import AppKit
import Foundation

enum HerdrMonitor {
    static func scan() async -> [HerdrAgent] {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                continuation.resume(returning: Self.scanSync())
            }
        }
    }

    private static func scanSync() -> [HerdrAgent] {
        guard let binary = resolveBinary() else { return [] }

        guard let data = try? run(binary, ["api", "snapshot"]) else {
            return []
        }

        return decodeSnapshot(data)
    }

    static func focus(agent: HerdrAgent) {
        DispatchQueue.main.async {
            activateOrLaunchTerminal {
                DispatchQueue.global(qos: .userInitiated).async {
                    guard let binary = resolveBinary() else { return }
                    if !agent.workspaceId.isEmpty {
                        _ = try? run(binary, ["workspace", "focus", agent.workspaceId])
                    }
                    _ = try? run(binary, ["agent", "focus", agent.paneId])
                }
            }
        }
    }

    static func closePane(paneId: String) {
        guard let binary = resolveBinary() else { return }
        _ = try? run(binary, ["pane", "close", paneId])
    }

    // MARK: - Terminal

    private static let terminalApps: [(bundleId: String, path: String)] = [
        ("com.mitchellh.ghostty", "/Applications/Ghostty.app"),
        ("fun.tw93.kaku", "/Applications/Kaku.app"),
    ]

    private static func activateOrLaunchTerminal(then: @escaping () -> Void) {
        for app in terminalApps {
            if let running = NSRunningApplication.runningApplications(
                withBundleIdentifier: app.bundleId
            ).first {
                running.activate()
                then()
                return
            }
        }

        for app in terminalApps {
            let url = URL(fileURLWithPath: app.path)
            guard FileManager.default.fileExists(atPath: app.path) else { continue }
            let configuration = NSWorkspace.OpenConfiguration()
            configuration.activates = true
            NSWorkspace.shared.openApplication(at: url, configuration: configuration) { _, _ in
                then()
            }
            return
        }

        then()
    }

    // MARK: - Binary

    private static func resolveBinary() -> String? {
        if let override = ProcessInfo.processInfo.environment["HERDR_BIN"],
           !override.isEmpty,
           FileManager.default.isExecutableFile(atPath: override) {
            return override
        }

        for candidate in ["/usr/local/bin/herdr", "/opt/homebrew/bin/herdr"] {
            if FileManager.default.isExecutableFile(atPath: candidate) {
                return candidate
            }
        }

        // Not installed / not on PATH → scan returns [] and the AGENTS section stays hidden.
        guard let which = try? run("/usr/bin/which", ["herdr"]),
              let path = String(data: which, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines),
              !path.isEmpty,
              FileManager.default.isExecutableFile(atPath: path) else {
            return nil
        }
        return path
    }

    // MARK: - Process

    @discardableResult
    private static func run(_ path: String, _ arguments: [String]) throws -> Data {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = arguments

        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr

        try process.run()
        let data = stdout.fileHandleForReading.readDataToEndOfFile()
        _ = stderr.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw HerdrError.nonZeroExit(process.terminationStatus)
        }
        return data
    }

    // MARK: - Decode

    private static func decodeSnapshot(_ data: Data) -> [HerdrAgent] {
        guard let response = try? JSONDecoder().decode(SnapshotResponse.self, from: data) else {
            return []
        }

        let snapshot = response.result.snapshot
        let labels = Dictionary(
            uniqueKeysWithValues: snapshot.workspaces.map { ($0.workspaceId, $0.label) }
        )

        let agents = snapshot.agents.compactMap { raw -> HerdrAgent? in
            guard let paneId = raw.paneId, !paneId.isEmpty,
                  let kind = raw.agent, !kind.isEmpty else { return nil }
            let custom = [raw.displayAgent, raw.name]
                .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
                .first { !$0.isEmpty && $0.caseInsensitiveCompare(kind) != .orderedSame }

            return HerdrAgent(
                paneId: paneId,
                tabId: raw.tabId ?? "",
                workspaceId: raw.workspaceId ?? "",
                kind: kind,
                displayName: (custom ?? kind).capitalized,
                cwd: raw.cwd ?? "",
                workspaceLabel: raw.workspaceId.flatMap { labels[$0] },
                status: HerdrAgentStatus(raw: raw.agentStatus ?? "unknown"),
                focused: raw.focused ?? false
            )
        }

        return agents.sorted {
            if $0.status.sortRank != $1.status.sortRank {
                return $0.status.sortRank < $1.status.sortRank
            }
            return $0.paneId < $1.paneId
        }
    }
}

// MARK: - Errors

private enum HerdrError: Error {
    case nonZeroExit(Int32)
}

// MARK: - JSON

private struct SnapshotResponse: Decodable {
    struct Result: Decodable {
        let snapshot: Snapshot
    }

    let result: Result
}

private struct Snapshot: Decodable {
    let agents: [RawAgent]
    let workspaces: [RawWorkspace]
}

private struct RawWorkspace: Decodable {
    let workspaceId: String
    let label: String

    enum CodingKeys: String, CodingKey {
        case workspaceId = "workspace_id"
        case label
    }
}

private struct RawAgent: Decodable {
    let agent: String?
    let displayAgent: String?
    let name: String?
    let agentStatus: String?
    let cwd: String?
    let paneId: String?
    let tabId: String?
    let workspaceId: String?
    let focused: Bool?

    enum CodingKeys: String, CodingKey {
        case agent
        case displayAgent = "display_agent"
        case name
        case agentStatus = "agent_status"
        case cwd
        case paneId = "pane_id"
        case tabId = "tab_id"
        case workspaceId = "workspace_id"
        case focused
    }
}
