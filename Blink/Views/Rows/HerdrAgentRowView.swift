import SwiftUI

struct HerdrAgentRowView: View {
    @Environment(AppState.self) private var appState
    let agent: HerdrAgent

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 0) {
            ColorBar(color: agent.status.color, isWorking: agent.status == .working)

            HStack(alignment: .center, spacing: 8) {
                HerdrAgentIconView(kind: agent.kind)

                VStack(alignment: .leading, spacing: 2) {
                    Text(agent.displayName)
                        .font(.system(size: 12, weight: .medium))
                        .lineLimit(1)

                    Text(subtitle)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if isHovered {
                RowAction(
                    symbol: "xmark",
                    help: "Close agent pane",
                    tint: .alert
                ) {
                    appState.stopAgent(agent)
                }
                .transition(.opacity)
            }
        }
        .hoverRow { isHovered = $0 }
        .contentShape(Rectangle())
        .onTapGesture { appState.focusAgent(agent) }
        .help("Open in Herdr")
    }

    private var subtitle: String {
        let place = agent.workspaceLabel
            ?? URL(fileURLWithPath: agent.cwd).lastPathComponent
        if place.isEmpty {
            return agent.status.label
        }
        return "\(agent.status.label) · \(place)"
    }
}
