import SwiftUI

struct ServerRowView: View {
    @Environment(AppState.self) private var appState
    let server: DevServer

    @State private var isHovered = false

    private var restartState: AppState.RestartState? {
        appState.restartStates[server.port]
    }

    private var isRestarting: Bool { restartState == .restarting }

    private var failureMessage: String? {
        if case .failed(let message) = restartState { return message }
        return nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            header

            if let failureMessage {
                FailureBox(message: failureMessage)
                    .padding(.leading, HoverRowStyle.horizontalPadding + ColorBar.gutter)
                    .padding(.trailing, HoverRowStyle.horizontalPadding)
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.2), value: failureMessage)
    }

    private var header: some View {
        HStack(spacing: 0) {
            ColorBar(color: barColor, isWorking: isRestarting)

            VStack(alignment: .leading, spacing: 2) {
                Text(server.projectName)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(verbatim: ":\(server.port)")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(.secondary)
                    subtitle
                }
            }

            Spacer()

            if isHovered && !isRestarting {
                actions
                    .transition(.opacity)
            }
        }
        .opacity(isRestarting ? 0.4 : 1)
        .allowsHitTesting(!isRestarting)
        .animation(.easeOut(duration: 0.2), value: isRestarting)
        .hoverRow { isHovered = $0 }
        .onTapGesture {
            guard failureMessage == nil else { return }
            appState.openInBrowser(server)
        }
    }
}

// MARK: - Pieces

private extension ServerRowView {
    var barColor: Color {
        failureMessage == nil ? server.framework.color : Color.alert
    }

    @ViewBuilder
    var subtitle: some View {
        if isRestarting {
            Text("restarting…")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        } else if failureMessage != nil {
            Text("failed to restart")
                .font(.system(size: 10))
                .foregroundStyle(Color.alert)
        } else {
            Text(server.framework == .unknown ? server.command : server.framework.rawValue)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
    }

    var actions: some View {
        HStack(spacing: RowAction.spacing) {
            RowAction(symbol: "arrow.clockwise", help: "Restart server") {
                appState.restartServer(server)
            }

            RowAction(
                symbol: "xmark",
                help: failureMessage == nil ? "Stop server" : "Dismiss",
                tint: .alert
            ) {
                if failureMessage == nil {
                    appState.killServer(server)
                } else {
                    appState.dismissFailed(server)
                }
            }
        }
    }
}

// MARK: - Measurement

private struct ErrorTextHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
