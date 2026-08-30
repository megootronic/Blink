import Foundation

// Output must be drained: an unread pipe fills at ~64KB and blocks the child.
final class RelaunchedServer {
    private let process = Process()
    private let pipe = Pipe()
    private let tail = OutputTail()
    private let startedAt = Date()

    init(executable: String, arguments: [String], directory: String) throws {
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.currentDirectoryURL = URL(fileURLWithPath: directory)
        process.standardOutput = pipe
        process.standardError = pipe

        var environment = ProcessInfo.processInfo.environment
        let binDirectory = (executable as NSString).deletingLastPathComponent
        if !binDirectory.isEmpty {
            let existing = environment["PATH"] ?? "/usr/bin:/bin:/usr/sbin:/sbin"
            if !existing.split(separator: ":").contains(Substring(binDirectory)) {
                environment["PATH"] = "\(binDirectory):\(existing)"
            }
        }
        process.environment = environment

        let tail = tail
        pipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }
            tail.append(String(decoding: data, as: UTF8.self))
        }

        try process.run()
    }

    func outputTail() -> String { tail.text }

    var isRunning: Bool { process.isRunning }

    var exitDescription: String {
        guard !process.isRunning else { return "Stopped serving." }

        let lifetime = Date().timeIntervalSince(startedAt)
        let lasted = lifetime < 1
            ? "immediately"
            : "after \(String(format: "%.0f", lifetime))s"

        if process.terminationReason == .uncaughtSignal {
            return "Killed by signal \(process.terminationStatus) \(lasted)."
        }
        return "Exited with code \(process.terminationStatus) \(lasted)."
    }

    func stopDraining() {
        pipe.fileHandleForReading.readabilityHandler = nil
    }
}

private final class OutputTail {
    private static let limit = 50

    private let lock = NSLock()
    private var lines: [String] = []
    private var partial = ""

    func append(_ chunk: String) {
        lock.lock()
        defer { lock.unlock() }

        partial += chunk
        var components = partial.components(separatedBy: "\n")
        partial = components.removeLast()

        lines.append(contentsOf: components)
        if lines.count > Self.limit {
            lines.removeFirst(lines.count - Self.limit)
        }
    }

    var text: String {
        lock.lock()
        defer { lock.unlock() }

        let all = partial.isEmpty ? lines : lines + [partial]
        let cleaned = all
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .filter { !$0.allSatisfy { "^~".contains($0) } }

        return Array(Self.leadingWithTheError(cleaned).suffix(12))
            .joined(separator: "\n")
    }

    private static func leadingWithTheError(_ lines: [String]) -> [String] {
        let marker = #"^([A-Za-z_][A-Za-z0-9_.]*)?(Error|Exception)\b"#

        guard let start = lines.firstIndex(where: {
            $0.range(of: marker, options: .regularExpression) != nil
        }) else {
            return lines
        }
        return Array(lines[start...])
    }
}
