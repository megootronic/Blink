import Foundation

extension AppState {
    fileprivate static let devCommands: Set<String> = [
        "node", "python", "python3", "ruby", "cargo",
        "go", "php", "java", "deno", "bun", "tsx", "npx",
        "next-serv", "uvicorn", "gunicorn", "puma"
    ]

    func scanServers() async -> [DevServer] {
        let ports = await PortScanner.scan()

        let devPorts = ports.filter { port in
            Self.devCommands.contains(port.command.lowercased())
        }

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
                        pid: port.pid,
                        port: port.port,
                        command: port.command,
                        framework: framework,
                        projectName: projectName,
                        projectPath: info.workingDirectory
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
