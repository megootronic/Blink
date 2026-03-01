//
//  ServerRowView.swift
//  Blink
//
//  Row displaying a single dev server
//

import SwiftUI

struct ServerRowView: View {
    @Environment(AppState.self) private var appState
    let server: DevServer

    @State private var isHovered = false
    @State private var copied = false

    var body: some View {
        HStack(spacing: 0) {
            ColorBar(color: server.framework.color)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 5) {
                    PulseDot()
                    Text(server.projectName)
                        .font(.system(size: 12, weight: .medium))
                        .lineLimit(1)
                }

                HStack(spacing: 6) {
                    portLabel

                    Text(server.framework == .unknown ? server.command : server.framework.rawValue)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if isHovered {
                HStack(spacing: 4) {
                    Button {
                        appState.openInBrowser(server)
                    } label: {
                        Image(systemName: "globe")
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .help("Open in browser")

                    Button {
                        appState.killServer(server)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color(red: 0.98, green: 0.34, blue: 0.45))
                    .help("Stop server")
                }
                .transition(.opacity)
            }
        }
        .hoverRow { isHovered = $0 }
    }

    // MARK: - Port Label

    private var portLabel: some View {
        Button {
            appState.copyToClipboard(server)
            withAnimation(.easeInOut(duration: 0.2)) { copied = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeInOut(duration: 0.2)) { copied = false }
            }
        } label: {
            HStack(spacing: 2) {
                if copied {
                    Image(systemName: "checkmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.green)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Text(verbatim: ":\(server.port)")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .underline(isHovered)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.15), value: copied)
        }
        .buttonStyle(.plain)
        .help("Copy localhost:\(server.port)")
    }
}
