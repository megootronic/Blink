//
//  EmptyStateView.swift
//  Blink
//
//  Displayed when no servers or simulators are running
//

import SwiftUI

struct EmptyStateView: View {
    @State private var floatOffset: CGFloat = 0
    @State private var zOpacity1: Double = 0
    @State private var zOpacity2: Double = 0
    @State private var zOpacity3: Double = 0
    @State private var zOffset1: CGFloat = 0
    @State private var zOffset2: CGFloat = 0
    @State private var zOffset3: CGFloat = 0

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                floatingZ(opacity: zOpacity1, offset: zOffset1, x: 18, delay: 0)
                floatingZ(opacity: zOpacity2, offset: zOffset2, x: 26, delay: 0.8)
                floatingZ(opacity: zOpacity3, offset: zOffset3, x: 22, delay: 1.6)

                RobotHead(size: 48, eyeState: .closed, pupilOffset: .zero)
                    .offset(y: floatOffset)
            }
            .frame(height: 56)

            Text("All quiet here")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .onAppear { startAnimations() }
    }

    // MARK: - Floating Zs

    private func floatingZ(opacity: Double, offset: CGFloat, x: CGFloat, delay: Double) -> some View {
        Text("z")
            .font(.system(size: 10, weight: .medium, design: .rounded))
            .foregroundStyle(.secondary)
            .opacity(opacity)
            .offset(x: x, y: -20 + offset)
    }

    private func startAnimations() {
        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
            floatOffset = -4
        }

        animateZ(opacity: $zOpacity1, offset: $zOffset1, delay: 0)
        animateZ(opacity: $zOpacity2, offset: $zOffset2, delay: 0.8)
        animateZ(opacity: $zOpacity3, offset: $zOffset3, delay: 1.6)
    }

    private func animateZ(opacity: Binding<Double>, offset: Binding<CGFloat>, delay: Double) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: false)) {
                opacity.wrappedValue = 0.6
                offset.wrappedValue = -20
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                opacity.wrappedValue = 0
                offset.wrappedValue = 0
            }
        }
    }
}
