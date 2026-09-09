import Foundation
import SwiftUI

enum HerdrAgentStatus: String, Hashable {
    case idle
    case working
    case blocked
    case done
    case unknown

    init(raw: String) {
        self = HerdrAgentStatus(rawValue: raw) ?? .unknown
    }

    var label: String {
        switch self {
        case .idle: return "idle"
        case .working: return "working"
        case .blocked: return "blocked"
        case .done: return "done"
        case .unknown: return "unknown"
        }
    }

    var sortRank: Int {
        switch self {
        case .blocked: return 0
        case .working: return 1
        case .done: return 2
        case .idle: return 3
        case .unknown: return 4
        }
    }

    var color: Color {
        switch self {
        case .blocked: return .alert
        case .working: return .xcode
        case .done: return Color(hex: 0x34C759)
        case .idle, .unknown: return .secondary
        }
    }
}

struct HerdrAgent: Identifiable, Hashable {
    var id: String { paneId }

    let paneId: String
    let tabId: String
    let workspaceId: String
    let kind: String
    let displayName: String
    let cwd: String
    let workspaceLabel: String?
    let status: HerdrAgentStatus
    let focused: Bool
}
