//
//  MenuBarView.swift
//  Blink
//
//  Main popover content for the menu bar
//

import SwiftUI

struct MenuBarView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 0) {
            header
            separator
            content
            separator
            footer
        }
        .frame(width: 320, height: 420)
        .background(.ultraThinMaterial)
    }
}

// MARK: - Sections

private extension MenuBarView {
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

    var separator: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [.clear, .secondary.opacity(0.2), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 0.5)
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
            .transition(.opacity.combined(with: .scale(scale: 0.97)))
        }
    }

    var serverSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("DEV SERVERS", icon: "server.rack")

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
            sectionHeader("SIMULATORS", icon: "iphone")

            ForEach(appState.simulators) { simulator in
                SimulatorRowView(simulator: simulator)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
            }
        }
    }

    func sectionHeader(_ title: String, icon: String? = nil) -> some View {
        HStack(spacing: 4) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary.opacity(0.6))
            }
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .tracking(0.8)
                .foregroundStyle(.secondary.opacity(0.6))
        }
        .padding(.horizontal, 4)
    }

    var footer: some View {
        HStack {
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .font(.body)
            .foregroundStyle(.primary)
            .keyboardShortcut("q", modifiers: .command)

            Spacer()

            if appState.totalCount > 0 {
                Button("Stop All") {
                    appState.stopAll()
                }
                .buttonStyle(.plain)
                .font(.subheadline)
                .foregroundStyle(Color(red: 0.98, green: 0.34, blue: 0.45))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
