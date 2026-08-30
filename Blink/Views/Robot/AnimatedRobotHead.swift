import SwiftUI

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

    private static let glanceInterval: ClosedRange<Double> = 1.4...4.2
    private static let saccadeDuration: TimeInterval = 0.09
    private static let headFollowDuration: TimeInterval = 0.55
    private static let recentreChance = 0.45

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
                scheduleGlance()
                startIdleBob()
                handleEvent(event)
            }
            .onDisappear {
                blinkTimer?.invalidate()
                driftTimer?.invalidate()
            }
    }

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

        case .restarting:
            scanAnimation()

        case .failed:
            withAnimation(.spring(response: 0.18, dampingFraction: 0.35)) {
                eyeState = .wide
                tilt = -9
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.13) {
                withAnimation(.spring(response: 0.18, dampingFraction: 0.35)) { tilt = 9 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) { tilt = 0 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeInOut(duration: 0.25)) { eyeState = .open }
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

    private func startIdleBob() {
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
            bobOffset = -1.5
        }
    }

    private func scheduleBlinkTimer() {
        blinkTimer?.invalidate()
        blinkTimer = Timer.scheduledTimer(
            withTimeInterval: Double.random(in: RobotBlink.interval),
            repeats: false
        ) { _ in
            if eyeState != .closed && eyeState != .halfClosed {
                quickBlink()
            }
            scheduleBlinkTimer()
        }
    }

    private func scheduleGlance() {
        driftTimer?.invalidate()
        driftTimer = Timer.scheduledTimer(
            withTimeInterval: .random(in: Self.glanceInterval),
            repeats: false
        ) { _ in
            glance()
            scheduleGlance()
        }
    }

    private func glance() {
        let target = Double.random(in: 0...1) < Self.recentreChance
            ? .zero
            : CGPoint(x: .random(in: -0.6...0.6), y: .random(in: -0.3...0.3))

        withAnimation(.easeOut(duration: Self.saccadeDuration)) {
            pupilOffset = target
        }

        withAnimation(.easeInOut(duration: Self.headFollowDuration)) {
            tilt = Double(target.x) * 3.0
        }
    }

    private func quickBlink() {
        withAnimation(.easeIn(duration: RobotBlink.closeDuration)) {
            eyeState = .closed
        }
        DispatchQueue.main.asyncAfter(
            deadline: .now() + RobotBlink.closeDuration + RobotBlink.holdDuration
        ) {
            withAnimation(.easeOut(duration: RobotBlink.openDuration)) {
                eyeState = .open
            }
        }
    }

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
