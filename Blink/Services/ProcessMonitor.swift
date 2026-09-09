import Foundation

enum ProcessMonitor {
    static func sample(pids: [Int]) async -> [Int: ProcessMetrics] {
        guard !pids.isEmpty,
              let output = await Shell.run(
                  "/bin/ps",
                  arguments: [
                      "-p", pids.map(String.init).joined(separator: ","),
                      "-o", "pid=,pcpu=,rss="
                  ]
              ) else {
            return [:]
        }

        return parse(output)
    }

    static func parse(_ output: String) -> [Int: ProcessMetrics] {
        var metrics: [Int: ProcessMetrics] = [:]

        for line in output.split(separator: "\n") {
            let fields = line.split(whereSeparator: { $0.isWhitespace })
            guard fields.count == 3,
                  let pid = Int(fields[0]),
                  let cpuPercent = Double(fields[1]),
                  let residentMemoryKB = Int64(fields[2]),
                  cpuPercent >= 0,
                  residentMemoryKB >= 0 else {
                continue
            }

            metrics[pid] = ProcessMetrics(
                cpuPercent: cpuPercent,
                residentMemoryBytes: residentMemoryKB * 1_024
            )
        }

        return metrics
    }
}
