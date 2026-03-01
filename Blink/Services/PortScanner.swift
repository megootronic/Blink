//
//  PortScanner.swift
//  Blink
//
//  Scans for TCP ports in LISTEN state using lsof
//

import Foundation

struct ListeningPort {
    let pid: Int
    let port: Int
    let command: String
}

enum PortScanner {
    static func scan() async -> [ListeningPort] {
        guard let output = await Shell.run(
            "/usr/sbin/lsof",
            arguments: ["-iTCP", "-sTCP:LISTEN", "-n", "-P", "-F", "pcn"]
        ) else {
            return []
        }
        return parse(output)
    }
}

// MARK: - Parsing

private extension PortScanner {
    static func parse(_ output: String) -> [ListeningPort] {
        var results: [ListeningPort] = []
        var currentPID: Int?
        var currentCommand: String?

        for line in output.split(separator: "\n") {
            let content = String(line.dropFirst())
            switch line.first {
            case "p":
                currentPID = Int(content)
                currentCommand = nil
            case "c":
                currentCommand = content
            case "n":
                guard let pid = currentPID,
                      let command = currentCommand,
                      let port = extractPort(from: content) else { continue }
                results.append(ListeningPort(pid: pid, port: port, command: command))
            default:
                break
            }
        }

        return results
    }

    static func extractPort(from name: String) -> Int? {
        guard let colonIndex = name.lastIndex(of: ":") else { return nil }
        return Int(name[name.index(after: colonIndex)...])
    }
}
