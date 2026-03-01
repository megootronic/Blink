//
//  Shell.swift
//  Blink
//
//  Lightweight async wrapper for running shell commands
//

import Foundation

enum Shell {
    static func run(_ path: String, arguments: [String] = []) async -> String? {
        await withCheckedContinuation { continuation in
            let process = Process()
            let pipe = Pipe()

            process.executableURL = URL(fileURLWithPath: path)
            process.arguments = arguments
            process.standardOutput = pipe
            process.standardError = FileHandle.nullDevice

            // Ensure Xcode developer tools are found
            var env = ProcessInfo.processInfo.environment
            if let xcodePath = [
                "/Applications/Xcode.app/Contents/Developer",
                "/Applications/Xcode-beta.app/Contents/Developer"
            ].first(where: { FileManager.default.fileExists(atPath: $0) }) {
                env["DEVELOPER_DIR"] = xcodePath
            }
            process.environment = env

            do {
                try process.run()
            } catch {
                continuation.resume(returning: nil)
                return
            }

            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            continuation.resume(returning: String(data: data, encoding: .utf8))
        }
    }
}
