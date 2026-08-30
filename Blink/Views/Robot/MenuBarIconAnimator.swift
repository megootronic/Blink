import SwiftUI

@MainActor
final class MenuBarIconAnimator {
    private weak var button: NSStatusBarButton?
    private var blinkLoop: Task<Void, Never>?
    private var isAwake: Bool?

    private static let frameInterval: TimeInterval = 1.0 / 60.0

    init(button: NSStatusBarButton?) {
        self.button = button
        setAwake(false)
    }

    func setAwake(_ awake: Bool) {
        guard awake != isAwake else { return }
        isAwake = awake

        blinkLoop?.cancel()
        blinkLoop = nil

        guard awake else {
            draw(MenuBarIcon.asleepOpenness)
            return
        }

        draw(MenuBarIcon.awakeOpenness)
        blinkLoop = Task { [weak self] in await self?.runBlinkLoop() }
    }

    private func runBlinkLoop() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(.random(in: RobotBlink.interval)))
            guard !Task.isCancelled else { return }
            await blinkOnce()
        }
    }

    private func blinkOnce() async {
        var elapsed: TimeInterval = 0

        while elapsed < RobotBlink.duration {
            guard !Task.isCancelled else { return }

            draw(RobotBlink.openness(at: elapsed))
            try? await Task.sleep(for: .seconds(Self.frameInterval))
            elapsed += Self.frameInterval
        }

        guard !Task.isCancelled else { return }
        draw(MenuBarIcon.awakeOpenness)
    }

    private func draw(_ openness: CGFloat) {
        button?.image = MenuBarIcon.render(eyeOpenness: openness)
    }
}
