import Darwin
import Foundation

@main
struct RelaunchedServerTests {
    struct Failure: Error, CustomStringConvertible {
        let description: String
    }

    static func require(_ condition: Bool, _ message: String) throws {
        if !condition { throw Failure(description: message) }
    }

    static func cpuSeconds() -> Double {
        var usage = rusage()
        precondition(getrusage(RUSAGE_SELF, &usage) == 0)
        return Double(usage.ru_utime.tv_sec + usage.ru_stime.tv_sec)
            + Double(usage.ru_utime.tv_usec + usage.ru_stime.tv_usec) / 1_000_000
    }

    static func waitUntil(_ condition: () -> Bool, timeout: TimeInterval = 10) throws {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() {
            try require(Date() < deadline, "Timed out waiting for child output or exit")
            Thread.sleep(forTimeInterval: 0.01)
        }
    }

    static func run(_ command: String, expectedOutput: [String], exit: String) throws -> RelaunchedServer {
        let server = try RelaunchedServer(
            executable: "/bin/sh",
            arguments: ["-c", command],
            directory: NSTemporaryDirectory()
        )
        try waitUntil { !server.isRunning }
        try waitUntil { expectedOutput.allSatisfy { server.outputTail().contains($0) } }
        try require(server.exitDescription.contains(exit), "Unexpected exit: \(server.exitDescription)")
        return server
    }

    static func main() {
        do {
            try runTests()
        } catch {
            fputs("FAIL: \(error)\n", stderr)
            exit(EXIT_FAILURE)
        }
    }

    static func runTests() throws {
        let scenarios: [(String, String, [String], String)] = [
            ("successful exit", "printf 'stdout preserved\\n'; printf 'stderr preserved\\n' >&2", ["stdout preserved", "stderr preserved"], "Exited with code 0"),
            ("failed exit", "printf 'RuntimeError: simulated failure\\n' >&2; exit 23", ["RuntimeError: simulated failure"], "Exited with code 23"),
            ("partial final line", "printf 'final output without newline'", ["final output without newline"], "Exited with code 0"),
            ("output across multiple reads", "printf 'first chunk\\n'; sleep 0.1; printf 'second chunk\\n'", ["first chunk", "second chunk"], "Exited with code 0"),
            ("empty output", "exit 0", [], "Exited with code 0"),
            ("signal termination", "printf 'before termination\\n'; kill -TERM $$", ["before termination"], "Killed by signal 15"),
            ("output larger than pipe capacity", "i=0; while [ $i -lt 20000 ]; do printf 'line %s: output exceeding pipe capacity\\n' \"$i\"; i=$((i + 1)); done; printf 'large output drained\\n'", ["large output drained"], "Exited with code 0"),
        ]

        var retained: [RelaunchedServer] = []
        for (name, command, output, exit) in scenarios {
            retained.append(try run(command, expectedOutput: output, exit: exit))
            print("PASS: \(name)")
        }

        Thread.sleep(forTimeInterval: 0.2)
        let wallStarted = ProcessInfo.processInfo.systemUptime
        let cpuStarted = cpuSeconds()
        Thread.sleep(forTimeInterval: 2)
        let cpuPercent = 100 * (cpuSeconds() - cpuStarted)
            / (ProcessInfo.processInfo.systemUptime - wallStarted)
        try require(cpuPercent < 5, "Retained exited processes used \(cpuPercent)% CPU; possible EOF callback loop")
        try require(retained.count == scenarios.count, "Exited processes must stay retained during measurement")
        retained.forEach { $0.stopDraining() }
        print(String(format: "PASS: retained exited processes use %.4f%% CPU", cpuPercent))
    }
}
