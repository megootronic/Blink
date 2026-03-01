//
//  ProcessResolver.swift
//  Blink
//
//  Resolves process details: working directory, arguments, framework
//

import Foundation

struct ResolvedProcess {
    let pid: Int
    let arguments: String
    let workingDirectory: String
    let startTime: Date
}

enum ProcessResolver {

    // MARK: - Process Details

    static func resolve(pid: Int) async -> ResolvedProcess? {
        async let argsResult = Shell.run("/bin/ps", arguments: ["-p", "\(pid)", "-o", "args="])
        async let cwdResult = Shell.run("/usr/sbin/lsof", arguments: ["-d", "cwd", "-a", "-p", "\(pid)", "-Fn"])
        async let timeResult = Shell.run("/bin/ps", arguments: ["-p", "\(pid)", "-o", "lstart="])

        guard let args = await argsResult?.trimmingCharacters(in: .whitespacesAndNewlines),
              !args.isEmpty else { return nil }

        let cwd = await parseCWD(cwdResult ?? "")
        let startTime = await parseStartTime(timeResult ?? "")

        return ResolvedProcess(
            pid: pid,
            arguments: args,
            workingDirectory: cwd,
            startTime: startTime ?? Date()
        )
    }

    // MARK: - Framework Detection

    static func detectFramework(from info: ResolvedProcess) -> Framework {
        let args = info.arguments.lowercased()

        if args.contains("next") { return .nextjs }
        if args.contains("vite") || args.contains("vitest") { return .vite }
        if args.contains("nuxt") { return .nuxt }
        if args.contains("remix") { return .remix }
        if args.contains("astro") { return .astro }
        if args.contains("webpack") { return .webpack }
        if args.contains("manage.py") || args.contains("django") { return .django }
        if args.contains("flask") { return .flask }
        if args.contains("rails") || args.contains("puma") || args.contains("unicorn") { return .rails }
        if args.contains("cargo") { return .cargo }
        if args.contains("go run") || args.contains("go build") { return .go }
        if args.contains("php") || args.contains("artisan") { return .php }

        return .unknown
    }

    // MARK: - Project Name

    static func resolveProjectName(from directory: String) -> String {
        let fm = FileManager.default

        let packageJSON = (directory as NSString).appendingPathComponent("package.json")
        if let data = fm.contents(atPath: packageJSON),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let name = json["name"] as? String, !name.isEmpty {
            return formatName(name)
        }

        let cargoToml = (directory as NSString).appendingPathComponent("Cargo.toml")
        if let content = try? String(contentsOfFile: cargoToml, encoding: .utf8),
           let range = content.range(of: #"name\s*=\s*"([^"]+)""#, options: .regularExpression) {
            let match = content[range]
            if let quoteStart = match.firstIndex(of: "\""),
               let quoteEnd = match[match.index(after: quoteStart)...].firstIndex(of: "\"") {
                return formatName(String(match[match.index(after: quoteStart)..<quoteEnd]))
            }
        }

        let name = (directory as NSString).lastPathComponent
        return formatName(name.isEmpty || name == "/" ? "Unknown" : name)
    }

    private static func formatName(_ name: String) -> String {
        name.split(separator: "-")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }
}

// MARK: - Private Parsing

private extension ProcessResolver {
    static func parseCWD(_ output: String) -> String {
        for line in output.split(separator: "\n") {
            if line.hasPrefix("n/") {
                return String(line.dropFirst())
            }
        }
        return ""
    }

    static func parseStartTime(_ output: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE MMM dd HH:mm:ss yyyy"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.date(from: output.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}
