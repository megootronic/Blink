import Foundation

struct ResolvedProcess {
    let pid: Int
    let arguments: String
    let workingDirectory: String
}

enum ProcessResolver {
    // MARK: - Process Details

    static func resolve(pid: Int) async -> ResolvedProcess? {
        async let argsResult = Shell.run("/bin/ps", arguments: ["-p", "\(pid)", "-o", "args="])
        async let cwdResult = Shell.run("/usr/sbin/lsof", arguments: ["-d", "cwd", "-a", "-p", "\(pid)", "-Fn"])

        guard let args = await argsResult?.trimmingCharacters(in: .whitespacesAndNewlines),
              !args.isEmpty else { return nil }

        let cwd = await parseCWD(cwdResult ?? "")

        return ResolvedProcess(
            pid: pid,
            arguments: args,
            workingDirectory: cwd
        )
    }

    // MARK: - Real argv

    struct LaunchInfo {
        let executablePath: String
        let argv: [String]
    }

    static func launchInfo(pid: Int) -> LaunchInfo {
        var mib: [Int32] = [CTL_KERN, KERN_PROCARGS2, Int32(pid)]
        var size = 0

        guard sysctl(&mib, 3, nil, &size, nil, 0) == 0, size > MemoryLayout<Int32>.size else {
            return LaunchInfo(executablePath: "", argv: [])
        }

        var buffer = [UInt8](repeating: 0, count: size)
        guard sysctl(&mib, 3, &buffer, &size, nil, 0) == 0,
              size > MemoryLayout<Int32>.size else {
            return LaunchInfo(executablePath: "", argv: [])
        }

        let argc = buffer.withUnsafeBytes { $0.loadUnaligned(as: Int32.self) }
        guard argc > 0 else { return LaunchInfo(executablePath: "", argv: []) }

        var index = MemoryLayout<Int32>.size

        var executable: [UInt8] = []
        while index < size, buffer[index] != 0 {
            executable.append(buffer[index])
            index += 1
        }
        while index < size, buffer[index] == 0 { index += 1 }

        var result: [String] = []
        var current: [UInt8] = []

        while index < size, result.count < Int(argc) {
            if buffer[index] == 0 {
                result.append(String(decoding: current, as: UTF8.self))
                current.removeAll(keepingCapacity: true)
            } else {
                current.append(buffer[index])
            }
            index += 1
        }

        return LaunchInfo(
            executablePath: String(decoding: executable, as: UTF8.self),
            argv: result
        )
    }

    // MARK: - Relaunch Target

    struct RelaunchTarget {
        let pid: Int
        let executablePath: String
        let arguments: [String]
    }

    private static let maxAncestorHops = 4

    // Next.js and npm overwrite their own argv with a display title, so the
    // process holding the port often cannot be relaunched — walk up to one that can.
    static func relaunchTarget(pid: Int, projectPath: String) async -> RelaunchTarget? {
        var candidate: Int? = pid

        for _ in 0..<maxAncestorHops {
            guard let current = candidate else { return nil }

            let info = launchInfo(pid: current)
            let directory = await workingDirectory(pid: current)

            guard directory == projectPath else { return nil }

            if isRelaunchable(info) {
                return RelaunchTarget(
                    pid: current,
                    executablePath: info.executablePath,
                    arguments: Array(info.argv.dropFirst())
                )
            }

            candidate = parentPID(of: current)
        }

        return nil
    }

    private static func isRelaunchable(_ info: LaunchInfo) -> Bool {
        guard !info.executablePath.isEmpty,
              FileManager.default.isExecutableFile(atPath: info.executablePath),
              let first = info.argv.first,
              !first.contains(" ") else {
            return false
        }
        return !info.argv.dropFirst().contains(where: \.isEmpty)
    }

    static func parentPID(of pid: Int) -> Int? {
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, Int32(pid)]
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride

        guard sysctl(&mib, 4, &info, &size, nil, 0) == 0, size > 0 else { return nil }

        let parent = Int(info.kp_eproc.e_ppid)
        return parent > 1 ? parent : nil
    }

    static func workingDirectory(pid: Int) async -> String {
        let output = await Shell.run(
            "/usr/sbin/lsof",
            arguments: ["-d", "cwd", "-a", "-p", "\(pid)", "-Fn"]
        )
        return parseCWD(output ?? "")
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

extension ProcessResolver {
    static func parseCWD(_ output: String) -> String {
        for line in output.split(separator: "\n") {
            if line.hasPrefix("n/") {
                return String(line.dropFirst())
            }
        }
        return ""
    }
}
