//
//  RobotHead.swift
//  Blink
//
//  Cute laptop character, reusable at any size
//

import SwiftUI

// MARK: - Shared Geometry

enum RobotGeometry {
    static let baseSize: CGFloat = 24
    static let faceWidthRatio: CGFloat = 20
    static let faceHeightRatio: CGFloat = 15
    static let faceCornerRadiusRatio: CGFloat = 4.5
    static let eyeSpacingRatio: CGFloat = 2.6
    static let eyeWidthRatio: CGFloat = 2.5
    static let eyeHeightRatio: CGFloat = 5.0
    static let minEyeHeightRatio: CGFloat = 0.6

    static func eyeOpenness(for state: RobotHead.EyeState) -> CGFloat {
        switch state {
        case .open: 1.0
        case .halfClosed: 0.35
        case .closed: 0.0
        case .wide: 1.3
        }
    }
}

// MARK: - Robot Head

struct RobotHead: View {
    @Environment(\.colorScheme) private var colorScheme
    var size: CGFloat = 18
    var eyeState: EyeState = .open
    var pupilOffset: CGPoint = .zero

    enum EyeState {
        case open, halfClosed, closed, wide
    }

    private var scale: CGFloat { size / RobotGeometry.baseSize }
    private var eyeOpenness: CGFloat { RobotGeometry.eyeOpenness(for: eyeState) }

    private var faceColor: Color { colorScheme == .dark ? .white.opacity(0.28) : .black.opacity(0.25) }
    private var eyeColor: Color { colorScheme == .dark ? .white.opacity(0.80) : .black.opacity(0.75) }

    var body: some View {
        Canvas { context, canvasSize in
            let mid = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)

            let faceWidth = RobotGeometry.faceWidthRatio * scale
            let faceHeight = RobotGeometry.faceHeightRatio * scale
            let faceRect = CGRect(
                x: mid.x - faceWidth / 2,
                y: mid.y - faceHeight / 2,
                width: faceWidth,
                height: faceHeight
            )
            let facePath = Path(roundedRect: faceRect, cornerRadius: RobotGeometry.faceCornerRadiusRatio * scale)
            context.fill(facePath, with: .color(faceColor))

            let eyeCenterY = faceRect.midY - 1.5 * scale + pupilOffset.y * scale
            let eyeSpacing = RobotGeometry.eyeSpacingRatio * scale
            let eyeWidth = RobotGeometry.eyeWidthRatio * scale
            let fullEyeHeight = RobotGeometry.eyeHeightRatio * scale
            let eyeHeight = max(fullEyeHeight * eyeOpenness, RobotGeometry.minEyeHeightRatio * scale)
            let eyeCornerRadius = eyeWidth / 2

            for xOffset in [-eyeSpacing, eyeSpacing] {
                let eyeX = mid.x + xOffset + pupilOffset.x * 0.5 * scale
                let eyeRect = CGRect(
                    x: eyeX - eyeWidth / 2,
                    y: eyeCenterY - eyeHeight / 2,
                    width: eyeWidth,
                    height: eyeHeight
                )

                context.fill(
                    Path(roundedRect: eyeRect, cornerRadius: eyeCornerRadius),
                    with: .color(eyeColor)
                )
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Animated Robot

struct AnimatedRobotHead: View {
    var size: CGFloat = 18
    var event: AppState.BlinkEvent = .idle

    @State private var pupilOffset: CGPoint = .zero
    @State private var eyeState: RobotHead.EyeState = .open
    @State private var tilt: Double = 0
    @State private var bobOffset: CGFloat = 0
    @State private var squish: CGFloat = 1.0
    @State private var blinkTimer: Timer?
    @State private var driftTimer: Timer?

    private static let blinkInterval: ClosedRange<Double> = 3.0...5.0
    private static let driftInterval: TimeInterval = 2.5

    var body: some View {
        RobotHead(size: size, eyeState: eyeState, pupilOffset: pupilOffset)
            .scaleEffect(x: 1.0, y: squish)
            .rotationEffect(.degrees(tilt))
            .offset(y: bobOffset)
            .onChange(of: event) { _, newEvent in
                handleEvent(newEvent)
            }
            .onAppear {
                scheduleBlinkTimer()
                startPupilDrift()
                startIdleBob()
                handleEvent(event)
            }
            .onDisappear {
                blinkTimer?.invalidate()
                driftTimer?.invalidate()
            }
    }

    // MARK: - Event Handling

    private func handleEvent(_ event: AppState.BlinkEvent) {
        switch event {
        case .idle:
            withAnimation(.easeInOut(duration: 0.4)) {
                eyeState = .halfClosed
                tilt = 0
            }

        case .active:
            withAnimation(.easeInOut(duration: 0.2)) {
                eyeState = .open
                tilt = 0
            }

        case .scanning:
            scanAnimation()

        case .newDetected:
            withAnimation(.spring(response: 0.25, dampingFraction: 0.4)) {
                eyeState = .wide
                squish = 1.15
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    squish = 1.0
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    eyeState = .open
                }
            }

        case .killed:
            withAnimation(.spring(response: 0.15, dampingFraction: 0.6)) {
                squish = 0.9
            }
            quickBlink()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    squish = 1.0
                }
            }
        }
    }

    // MARK: - Idle Bob

    private func startIdleBob() {
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
            bobOffset = -1.5
        }
    }

    // MARK: - Blink Cycle

    private func scheduleBlinkTimer() {
        blinkTimer?.invalidate()
        blinkTimer = Timer.scheduledTimer(
            withTimeInterval: Double.random(in: Self.blinkInterval),
            repeats: false
        ) { _ in
            if eyeState != .closed && eyeState != .halfClosed {
                quickBlink()
            }
            scheduleBlinkTimer()
        }
    }

    // MARK: - Pupil Drift

    private func startPupilDrift() {
        driftTimer = Timer.scheduledTimer(withTimeInterval: Self.driftInterval, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 1.0)) {
                pupilOffset = CGPoint(
                    x: CGFloat.random(in: -0.6...0.6),
                    y: CGFloat.random(in: -0.3...0.3)
                )
                tilt = Double(pupilOffset.x) * 3.0
            }
        }
    }

    // MARK: - Quick Blink

    private func quickBlink() {
        withAnimation(.easeIn(duration: 0.07)) {
            eyeState = .closed
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeOut(duration: 0.18)) {
                eyeState = .open
            }
        }
    }

    // MARK: - Scan Animation

    private func scanAnimation() {
        withAnimation(.easeInOut(duration: 0.35)) {
            pupilOffset = CGPoint(x: -0.8, y: -0.1)
            tilt = -4
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeInOut(duration: 0.35)) {
                pupilOffset = CGPoint(x: 0.8, y: -0.1)
                tilt = 4
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeInOut(duration: 0.25)) {
                pupilOffset = .zero
                tilt = 0
            }
        }
    }
}
