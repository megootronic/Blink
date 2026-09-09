import AppKit
import Foundation

enum HerdrMonitor {
    private static var cachedBinary: String?
    private static var didResolveBinary = false

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
            // Binary may have moved — allow rediscovery next tick.
            invalidateBinaryCache()
            return []
        }

        return decodeSnapshot(data)
    }

    static func focus(agent: HerdrAgent) {
        DispatchQueue.main.async {
            activateHostTerminal()
            DispatchQueue.global(qos: .userInitiated).async {
                guard let binary = resolveBinary() else { return }
                if !agent.workspaceId.isEmpty {
                    _ = try? run(binary, ["workspace", "focus", agent.workspaceId])
                }
                _ = try? run(binary, ["agent", "focus", agent.paneId])
            }
        }
    }

    static func closePane(paneId: String) {
        guard let binary = resolveBinary() else { return }
        _ = try? run(binary, ["pane", "close", paneId])
    }

    // MARK: - Host terminal (discovered, not hardcoded)

    /// Bring forward whatever GUI app is hosting a live `herdr` client by
    /// walking that process's parent chain. No fixed terminal list.
    private static func activateHostTerminal() {
        guard let app = discoverHostTerminalApp() else { return }
        app.activate()
    }

    private static func discoverHostTerminalApp() -> NSRunningApplication? {
        guard let data = try? run("/usr/bin/pgrep", ["-f", "herdr"]),
              let text = String(data: data, encoding: .utf8) else {
            return nil
        }

        for token in text.split(whereSeparator: \.isNewline) {
            guard let pid = Int32(token.trimmingCharacters(in: .whitespaces)) else { continue }
            if let app = appOwning(pid: pid) {
                return app
            }
        }
        return nil
    }

    private static func appOwning(pid: Int32) -> NSRunningApplication? {
        var current = pid
        for _ in 0..<16 {
            guard let info = processInfo(pid: current) else { return nil }

            // Prefer a regular GUI app at this PID.
            if let app = NSRunningApplication(processIdentifier: current),
               app.activationPolicy == .regular {
                return app
            }

            // Or an ancestor whose command path lives inside a .app bundle.
            if info.command.contains(".app/"),
               let app = NSRunningApplication(processIdentifier: current) {
                return app
            }

            guard let ppid = info.ppid, ppid > 1 else { return nil }
            current = ppid
        }
        return nil
    }

    private static func processInfo(pid: Int32) -> (ppid: Int32?, command: String)? {
        guard let data = try? run(
            "/bin/ps",
            ["-o", "ppid=,command=", "-p", "\(pid)"]
        ),
        let line = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
        !line.isEmpty else {
            return nil
        }

        let parts = line.split(maxSplits: 1, whereSeparator: \.isWhitespace)
        guard let ppidToken = parts.first,
              let ppid = Int32(ppidToken) else {
            return (nil, line)
        }
        let command = parts.count > 1 ? String(parts[1]) : ""
        return (ppid, command)
    }

    // MARK: - Binary (env override or login-shell PATH)

    private static func invalidateBinaryCache() {
        didResolveBinary = false
        cachedBinary = nil
    }

    private static func resolveBinary() -> String? {
        if didResolveBinary { return cachedBinary }

        if let override = ProcessInfo.processInfo.environment["HERDR_BIN"]?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !override.isEmpty,
           FileManager.default.isExecutableFile(atPath: override) {
            didResolveBinary = true
            cachedBinary = override
            return override
        }

        // Resolve via the user's login shell so Homebrew / ~/.local / custom
        // installs work without baking in brew prefixes.
        let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
        let path: String?
        if let data = try? run(shell, ["-lc", "command -v herdr"]),
           let resolved = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !resolved.isEmpty,
           FileManager.default.isExecutableFile(atPath: resolved) {
            path = resolved
        } else {
            path = nil
        }

        didResolveBinary = true
        cachedBinary = path
        return path
    }

    // MARK: - Process

    @discardableResult
    private static func run(_ path: String, _ arguments: [String]) throws -> Data {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = arguments

        var environment = ProcessInfo.processInfo.environment
        if environment["HOME"] == nil {
            environment["HOME"] = NSHomeDirectory()
        }
        process.environment = environment

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
