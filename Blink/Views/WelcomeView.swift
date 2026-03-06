//
//  WelcomeView.swift
//  Blink
//
//  First-launch welcome window
//

import SwiftUI

struct WelcomeView: View {
    @AppStorage("hasLaunchedBefore") private var hasLaunchedBefore = false
    @State private var appeared = false
    @State private var step = 0

    var body: some View {
        VStack(spacing: 0) {
            if step == 0 {
                welcomeStep
                    .transition(.asymmetric(
                        insertion: .opacity,
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            } else {
                accessibilityStep
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .opacity
                    ))
            }
        }
        .padding(32)
        .overlay(alignment: .bottom) {
            if step == 0 {
                Text("Version \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.bottom, 10)
            }
        }
        .frame(width: 320, height: 380)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                appeared = true
            }
        }
    }

    // MARK: - Step 1: Welcome

    private var welcomeStep: some View {
        VStack(spacing: 0) {
            Spacer()

            AnimatedRobotHead(size: 64, event: .active)
                .padding(.bottom, 2)

            Text("Blink")
                .font(.system(size: 28, weight: .bold))
                .padding(.bottom, 8)

            Text("Keeps an eye on your dev servers\nand simulators.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.35)) {
                    step = 1
                }
            } label: {
                Text("Get Started")
                    .font(.body.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(.primary.opacity(0.8))
        }
    }

    // MARK: - Step 2: Accessibility

    private var accessibilityStep: some View {
        VStack(spacing: 0) {
            Spacer()

            Image(systemName: "iphone")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
                .padding(.bottom, 12)

            Text("One-Tap Focus")
                .font(.system(size: 20, weight: .semibold))
                .padding(.bottom, 8)

            Text("Click any simulator in Blink to bring\nits window forward. This needs\nAccessibility access.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            Button {
                requestAccessibility()
                dismiss()
            } label: {
                Text("Allow Access")
                    .font(.body.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(.primary.opacity(0.8))

            Button {
                dismiss()
            } label: {
                Text("Skip for Now")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .padding(.top, 12)
        }
    }

    // MARK: - Helpers

    private func requestAccessibility() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    private func dismiss() {
        hasLaunchedBefore = true
        WelcomeWindowController.close()
    }
}
