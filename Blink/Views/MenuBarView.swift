import SwiftUI

struct MenuBarView: View {
    static let panelSize = CGSize(width: 320, height: 440)

    @Environment(AppState.self) private var appState

    @State private var page: Page = .main

    enum Page {
        case main, settings, about
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            mainPage
                .panelPage(isActive: page == .main, restingOffset: -24)

            SettingsPage(isVisible: page == .settings) { page = .main }
                .frame(maxHeight: .infinity, alignment: .top)
                .panelPage(isActive: page == .settings, restingOffset: 24)

            AboutPage { page = .main }
                .frame(maxHeight: .infinity, alignment: .top)
                .panelPage(isActive: page == .about, restingOffset: 24)
        }
        .frame(width: Self.panelSize.width, height: Self.panelSize.height)
        // Material alone takes the wallpaper's colour; the ground pins the
        // panel to something the wallpaper only tints.
        .background {
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(Color.panelGround.opacity(0.80))
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Main page

private extension MenuBarView {

    var mainPage: some View {
        VStack(spacing: 0) {
            header
            PanelDivider()
            content
            PanelDivider()
            footer
        }
    }

    var header: some View {
        HStack {
            Text("Blink")
                .font(.system(size: 13, weight: .semibold))

            Spacer()

            if appState.totalCount > 0 {
                AnimatedRobotHead(size: 22, event: appState.lastEvent)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    var content: some View {
        if appState.isInitialLoad {
            VStack(spacing: 12) {
                AnimatedRobotHead(size: 48, event: .scanning)
                Text("Scanning...")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .transition(.opacity)
        } else if appState.servers.isEmpty && appState.simulators.isEmpty {
            EmptyStateView()
                .transition(.opacity.combined(with: .scale(scale: 0.97)))
        } else {
            ScrollView {
                VStack(spacing: 12) {
                    if !appState.servers.isEmpty {
                        serverSection
                    }
                    if !appState.simulators.isEmpty {
                        simulatorSection
                    }
                }
                .padding(12)
            }
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .black, location: 0),
                        .init(color: .black, location: 0.965),
                        .init(color: .black.opacity(0.55), location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .transition(.opacity.combined(with: .scale(scale: 0.97)))
        }
    }

    var serverSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(
                "DEV SERVERS",
                icon: "server.rack",
                action: appState.servers.count > 1 ? "Stop All" : nil
            ) {
                appState.stopAllServers()
            }

            ForEach(appState.servers) { server in
                ServerRowView(server: server)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
            }
        }
    }

    var simulatorSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(
                "SIMULATORS",
                icon: "iphone",
                action: appState.simulators.count > 1 ? "Shut Down All" : nil
            ) {
                appState.shutDownAllSimulators()
            }

            ForEach(appState.simulators) { simulator in
                SimulatorRowView(simulator: simulator)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
            }
        }
    }

    func sectionHeader(
        _ title: String,
        icon: String,
        action: String?,
        perform: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9))
                .frame(width: 12)
                .foregroundStyle(.secondary.opacity(0.6))

            Text(title)
                .font(.system(size: 10, weight: .medium))
                .tracking(0.8)
                .foregroundStyle(.secondary.opacity(0.6))

            Spacer()

            if let action {
                Button(action: perform) {
                    Text(action)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color.alert)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 4)
    }

    var footer: some View {
        VStack(spacing: 0) {
            PanelRow("Settings") { page = .settings }
            PanelDivider()
            PanelRow("About") { page = .about }
            PanelDivider()
            PanelRow("Quit") { NSApplication.shared.terminate(nil) }
        }
    }
}
