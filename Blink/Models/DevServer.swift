//
//  DevServer.swift
//  Blink
//
//  Model representing a running development server
//

import Foundation
import SwiftUI

struct DevServer: Identifiable, Hashable {
    let id: Int // PID
    let port: Int
    let command: String
    let framework: Framework
    let projectName: String
    let projectPath: String
    let startTime: Date

    var localhostURL: URL? {
        URL(string: "http://localhost:\(port)")
    }
}

// MARK: - Framework

enum Framework: String, CaseIterable {
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

    /// Brand color for each framework
    var color: Color {
        switch self {
        case .nextjs:  .primary
        case .vite:    .brand(.vite)
        case .nuxt:    .brand(.nuxt)
        case .remix:   .brand(.remix)
        case .astro:   .brand(.astro)
        case .webpack: .brand(.webpack)
        case .django:  .brand(.django)
        case .flask:   .secondary
        case .rails:   .brand(.rails)
        case .cargo:   .brand(.rust)
        case .go:      .brand(.go)
        case .php:     .brand(.php)
        case .unknown: .secondary
        }
    }
}

// MARK: - Brand Colors

extension Color {
    enum Brand {
        case vite, nuxt, remix, astro, webpack, django, rails, rust, go, php, xcode
    }

    static func brand(_ brand: Brand) -> Color {
        switch brand {
        case .vite:    Color(red: 0.39, green: 0.42, blue: 1.0)   // #646CFF
        case .nuxt:    Color(red: 0.0,  green: 0.86, blue: 0.51)  // #00DC82
        case .remix:   Color(red: 0.31, green: 0.51, blue: 1.0)   // #4F82FF
        case .astro:   Color(red: 1.0,  green: 0.36, blue: 0.0)   // #FF5D01
        case .webpack: Color(red: 0.55, green: 0.84, blue: 0.98)  // #8DD6F9
        case .django:  Color(red: 0.04, green: 0.42, blue: 0.24)  // #0C6B3E
        case .rails:   Color(red: 0.8,  green: 0.0,  blue: 0.0)   // #CC0000
        case .rust:    Color(red: 0.81, green: 0.26, blue: 0.17)  // #CE422B
        case .go:      Color(red: 0.0,  green: 0.68, blue: 0.85)  // #00ADD8
        case .php:     Color(red: 0.47, green: 0.48, blue: 0.70)  // #777BB4
        case .xcode:   Color(red: 0.2,  green: 0.56, blue: 1.0)   // #338FF0
        }
    }

    /// Xcode blue — used for simulator-related UI
    static let xcode = brand(.xcode)
}
