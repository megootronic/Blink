//
//  AppState.swift
//  Blink
//
//  Central state management with polling timer
//

import Foundation
import SwiftUI

@Observable
final class AppState {
    var servers: [DevServer] = []
    var simulators: [Simulator] = []
    var isScanning = false
    var isInitialLoad = true
    var lastEvent: BlinkEvent = .idle

    private static let pollingInterval: TimeInterval = 3.0

    private var timer: Timer?
    private var killedPIDs: Set<Int> = []
    private var killedPorts: Set<Int> = []
    private var killedSimUDIDs: Set<String> = []

    var totalCount: Int { servers.count + simulators.count }

    // MARK: - Blink Events

    enum BlinkEvent {
        case idle
        case active
        case scanning
        case newDetected
        case killed
    }

    // MARK: - Lifecycle

    init() {
        startPolling()
    }

    deinit {
        timer?.invalidate()
    }

    // MARK: - Polling

    func startPolling() {
        Task { await refresh() }

        timer = Timer.scheduledTimer(withTimeInterval: Self.pollingInterval, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { await self.refresh() }
        }
    }

    func refresh() async {
        guard !isScanning else { return }
        isScanning = true
        lastEvent = .scanning
        defer { isScanning = false }

        let previousCount = totalCount

        async let scannedServers = scanServers()
        async let scannedSims = SimulatorMonitor.scan()

        let (newServers, newSims) = await (scannedServers, scannedSims)

        // Clear killed entries that are no longer running
        let activePIDs = Set(newServers.map(\.id))
        let activePorts = Set(newServers.map(\.port))
        killedPIDs = killedPIDs.intersection(activePIDs)
        killedPorts = killedPorts.intersection(activePorts)
        let activeSimUDIDs = Set(newSims.map(\.id))
        killedSimUDIDs = killedSimUDIDs.intersection(activeSimUDIDs)

        servers = newServers.filter { !killedPIDs.contains($0.id) && !killedPorts.contains($0.port) }
        simulators = newSims.filter { !killedSimUDIDs.contains($0.id) }
        isInitialLoad = false

        if totalCount > previousCount {
            lastEvent = .newDetected
            try? await Task.sleep(for: .seconds(0.6))
        }

        lastEvent = totalCount > 0 ? .active : .idle
    }

    // MARK: - Actions

    func killServer(_ server: DevServer) {
        lastEvent = .killed
        killedPIDs.insert(server.id)
        killedPorts.insert(server.port)
        withAnimation(.easeOut(duration: 0.3)) {
            servers.removeAll { $0.id == server.id }
        }
        killProcessTree(pid: server.id)
    }

    func stopSimulator(_ simulator: Simulator) {
        lastEvent = .killed
        killedSimUDIDs.insert(simulator.id)
        withAnimation(.easeOut(duration: 0.3)) {
            simulators.removeAll { $0.id == simulator.id }
        }
        Task {
            await SimulatorMonitor.shutdown(udid: simulator.id)
        }
    }

    func stopAll() {
        for server in servers {
            killedPIDs.insert(server.id)
            killedPorts.insert(server.port)
            killProcessTree(pid: server.id)
        }
        for sim in simulators {
            killedSimUDIDs.insert(sim.id)
        }

        Task {
            await SimulatorMonitor.shutdownAll()
        }

        // Staggered removal for cascade effect
        let staggerDelay = 0.1
        let totalItems = servers.count + simulators.count
        for i in 0..<totalItems {
            let delay = Double(i) * staggerDelay
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeOut(duration: 0.25)) {
                    if !self.servers.isEmpty {
                        self.servers.removeFirst()
                    } else if !self.simulators.isEmpty {
                        self.simulators.removeFirst()
                    }
                }
            }
        }

        lastEvent = .killed
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(totalItems) * staggerDelay + 0.3) {
            self.lastEvent = .idle
        }
    }

    private func killProcessTree(pid: Int) {
        let p = pid_t(pid)
        kill(p, SIGTERM)
        Task {
            _ = await Shell.run("/usr/bin/pkill", arguments: ["-TERM", "-P", "\(pid)"])

            try? await Task.sleep(for: .seconds(1))
            kill(p, SIGKILL)
            _ = await Shell.run("/usr/bin/pkill", arguments: ["-KILL", "-P", "\(pid)"])
        }
    }

    func focusSimulator(_ simulator: Simulator) {
        let trusted = AXIsProcessTrustedWithOptions(
            [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        )

        guard trusted, let simApp = NSRunningApplication.runningApplications(
            withBundleIdentifier: "com.apple.iphonesimulator"
        ).first else { return }

        let appRef = AXUIElementCreateApplication(simApp.processIdentifier)
        var windowsRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(appRef, kAXWindowsAttribute as CFString, &windowsRef) == .success,
              let windows = windowsRef as? [AXUIElement] else { return }

        var targetWindow: AXUIElement?
        for window in windows {
            var titleRef: CFTypeRef?
            AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleRef)
            if let title = titleRef as? String, title.contains(simulator.name) {
                targetWindow = window
            }
        }

        guard let target = targetWindow else { return }

        AXUIElementSetAttributeValue(target, kAXMinimizedAttribute as CFString, false as CFTypeRef)
        AXUIElementPerformAction(target, kAXRaiseAction as CFString)

        if !simApp.isActive {
            simApp.activate()
        }
    }

    func openInBrowser(_ server: DevServer) {
        guard let url = server.localhostURL else { return }
        NSWorkspace.shared.open(url)
    }

    func copyToClipboard(_ server: DevServer) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString("localhost:\(server.port)", forType: .string)
    }
}

// MARK: - Server Scanning Pipeline

private extension AppState {
    static let devCommands: Set<String> = [
        "node", "python", "python3", "ruby", "cargo",
        "go", "php", "java", "deno", "bun", "tsx", "npx",
        "next-serv", "uvicorn", "gunicorn", "puma"
    ]

    func scanServers() async -> [DevServer] {
        let ports = await PortScanner.scan()

        let devPorts = ports.filter { port in
            Self.devCommands.contains(port.command)
        }

        // Deduplicate by port (IPv4 + IPv6) and by PID (multi-port servers)
        var seenPorts = Set<Int>()
        var seenPIDs = Set<Int>()
        let uniquePorts = devPorts.filter { port in
            seenPorts.insert(port.port).inserted && seenPIDs.insert(port.pid).inserted
        }

        return await withTaskGroup(of: DevServer?.self) { group in
            for port in uniquePorts {
                group.addTask {
                    guard let info = await ProcessResolver.resolve(pid: port.pid) else {
                        return nil
                    }
                    let framework = ProcessResolver.detectFramework(from: info)
                    let projectName = ProcessResolver.resolveProjectName(from: info.workingDirectory)

                    return DevServer(
                        id: port.pid,
                        port: port.port,
                        command: port.command,
                        framework: framework,
                        projectName: projectName,
                        projectPath: info.workingDirectory,
                        startTime: info.startTime
                    )
                }
            }

            var results: [DevServer] = []
            for await server in group {
                if let server { results.append(server) }
            }
            return results.sorted { $0.port < $1.port }
        }
    }
}
