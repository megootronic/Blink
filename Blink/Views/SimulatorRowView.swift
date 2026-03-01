//
//  SimulatorRowView.swift
//  Blink
//
//  Row displaying a booted iOS simulator
//

import SwiftUI

struct SimulatorRowView: View {
    @Environment(AppState.self) private var appState
    let simulator: Simulator

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 0) {
            ColorBar(color: .xcode)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 5) {
                    PulseDot()
                    Text(simulator.runningApp?.displayName ?? simulator.name)
                        .font(.system(size: 12, weight: .medium))
                        .lineLimit(1)
                }

                Text("\(simulator.name) · \(simulator.runtime)")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if isHovered {
                HStack(spacing: 4) {
                    Button {
                        appState.focusSimulator(simulator)
                    } label: {
                        Image(systemName: "macwindow")
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .help("Focus simulator")

                    Button {
                        appState.stopSimulator(simulator)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color(red: 0.98, green: 0.34, blue: 0.45))
                    .help("Shutdown simulator")
                }
                .transition(.opacity)
            }
        }
        .hoverRow { isHovered = $0 }
    }
}
