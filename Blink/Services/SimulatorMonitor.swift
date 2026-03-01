//
//  SimulatorMonitor.swift
//  Blink
//
//  Monitors booted iOS simulators via simctl
//

import Foundation

enum SimulatorMonitor {
    static func scan() async -> [Simulator] {
        guard let output = await Shell.run(
            "/usr/bin/xcrun",
            arguments: ["simctl", "list", "devices", "booted", "--json"]
        ) else {
            return []
        }

        let devices = parse(output)

        return await withTaskGroup(of: (Int, Simulator).self) { group in
            for (index, device) in devices.enumerated() {
                group.addTask {
                    let app = await resolveRunningApp(udid: device.id)
                    return (index, Simulator(
                        id: device.id,
                        name: device.name,
                        runtime: device.runtime,
                        state: device.state,
                        runningApp: app
                    ))
                }
            }
            var results: [(Int, Simulator)] = []
            for await pair in group { results.append(pair) }
            return results.sorted { $0.0 < $1.0 }.map(\.1)
        }
    }

    static func shutdown(udid: String) async {
        _ = await Shell.run("/usr/bin/xcrun", arguments: ["simctl", "shutdown", udid])
    }

    static func shutdownAll() async {
        _ = await Shell.run("/usr/bin/xcrun", arguments: ["simctl", "shutdown", "all"])
    }
}

// MARK: - Parsing

private extension SimulatorMonitor {
    struct SimctlResponse: Decodable {
        let devices: [String: [SimctlDevice]]
    }

    struct SimctlDevice: Decodable {
        let udid: String
        let name: String
        let state: String
    }

    static func parse(_ output: String) -> [Simulator] {
        guard let data = output.data(using: .utf8),
              let response = try? JSONDecoder().decode(SimctlResponse.self, from: data) else {
            return []
        }

        return response.devices.flatMap { runtimeKey, devices in
            devices
                .filter { $0.state == "Booted" }
                .map { device in
                    Simulator(
                        id: device.udid,
                        name: device.name,
                        runtime: formatRuntime(runtimeKey),
                        state: device.state,
                        runningApp: nil
                    )
                }
        }
    }

    static func formatRuntime(_ key: String) -> String {
        guard let runtime = key.split(separator: ".").last else { return key }
        let parts = runtime.split(separator: "-")
        guard parts.count >= 2 else { return String(runtime) }
        let os = parts[0]
        let version = parts.dropFirst().joined(separator: ".")
        return "\(os) \(version)"
    }

    // MARK: - Running App Detection

    /// Queries launchctl inside the simulator to find running user apps
    static func resolveRunningApp(udid: String) async -> Simulator.AppInfo? {
        guard let output = await Shell.run(
            "/usr/bin/xcrun",
            arguments: ["simctl", "spawn", udid, "launchctl", "list"]
        ) else {
            return nil
        }

        // Parse for UIKitApplication entries with a running PID (not "-")
        // Format: "PID\tStatus\tLabel"
        // Running apps: "12345\t0\tUIKitApplication:com.example.app[0xABC][rb-legacy]"
        // Stopped apps: "-\t0\tUIKitApplication:com.example.app[0xABC][rb-legacy]"
        let bundleIDs = output.components(separatedBy: .newlines).compactMap { line -> String? in
            guard line.contains("UIKitApplication:") else { return nil }
            let columns = line.split(separator: "\t", maxSplits: 2)
            guard columns.count >= 3, Int(columns[0]) != nil else { return nil }
            let label = String(columns[2])
            guard let start = label.range(of: "UIKitApplication:")?.upperBound else { return nil }
            let rest = label[start...]
            let end = rest.firstIndex(of: "[") ?? rest.endIndex
            return String(rest[..<end])
        }.filter { !$0.hasPrefix("com.apple.") }

        guard let bundleID = bundleIDs.last else { return nil }

        let displayName = await resolveAppName(udid: udid, bundleID: bundleID)
        return Simulator.AppInfo(
            bundleID: bundleID,
            displayName: displayName ?? bundleID.components(separatedBy: ".").last ?? bundleID
        )
    }

    /// Gets the app container path and reads CFBundleDisplayName / CFBundleName
    static func resolveAppName(udid: String, bundleID: String) async -> String? {
        guard let containerPath = await Shell.run(
            "/usr/bin/xcrun",
            arguments: ["simctl", "get_app_container", udid, bundleID, "app"]
        )?.trimmingCharacters(in: .whitespacesAndNewlines),
              !containerPath.isEmpty else {
            return nil
        }

        let infoPlistPath = (containerPath as NSString).appendingPathComponent("Info.plist")
        guard let plistData = FileManager.default.contents(atPath: infoPlistPath),
              let plist = try? PropertyListSerialization.propertyList(
                  from: plistData, format: nil
              ) as? [String: Any] else {
            return nil
        }

        return (plist["CFBundleDisplayName"] as? String)
            ?? (plist["CFBundleName"] as? String)
    }
}
