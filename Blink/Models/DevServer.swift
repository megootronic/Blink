import Foundation
import SwiftUI

struct DevServer: Identifiable, Hashable {
    // Identity is the port: a restart swaps the PID, the row must survive it.
    var id: Int { port }

    let pid: Int
    let port: Int
    let command: String
    let framework: Framework
    let projectName: String
    let projectPath: String

    var localhostURL: URL? {
        URL(string: "http://localhost:\(port)")
    }
}

// MARK: - Framework

enum Framework: String {
    case nextjs = "Next.js"
    case vite = "Vite"
    case nuxt = "Nuxt"
    case remix = "Remix"
    case astro = "Astro"
    case webpack = "Webpack"
    case django = "Django"
    case flask = "Flask"
    case rails = "Rails"
    case cargo = "Cargo"
    case go = "Go"
    case php = "PHP"
    case unknown = "Server"

    var color: Color {
        switch self {
        case .nextjs:  .primary
        case .vite:    Color(hex: 0x646CFF)
        case .nuxt:    Color(hex: 0x00DC82)
        case .remix:   Color(hex: 0x4F82FF)
        case .astro:   Color(hex: 0xFF5D01)
        case .webpack: Color(hex: 0x8DD6F9)
        case .django:  Color(hex: 0x0C6B3E)
        case .flask:   .secondary
        case .rails:   Color(hex: 0xCC0000)
        case .cargo:   Color(hex: 0xCE422B)
        case .go:      Color(hex: 0x00ADD8)
        case .php:     Color(hex: 0x777BB4)
        case .unknown: .secondary
        }
    }
}
