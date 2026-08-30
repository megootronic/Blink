import SwiftUI

enum RobotBlink {
    static let interval: ClosedRange<Double> = 3.0...5.0

    static let closeDuration: TimeInterval = 0.07
    static let holdDuration: TimeInterval = 0.03
    static let openDuration: TimeInterval = 0.18

    static var duration: TimeInterval { closeDuration + holdDuration + openDuration }

    static func openness(at elapsed: TimeInterval) -> CGFloat {
        let fullyOpen = RobotGeometry.eyeOpenness(for: .open)

        if elapsed < closeDuration {
            return fullyOpen * (1 - easeIn(elapsed / closeDuration))
        }

        let openingStart = closeDuration + holdDuration
        guard elapsed >= openingStart else { return 0 }

        return fullyOpen * easeOut(min((elapsed - openingStart) / openDuration, 1))
    }

    private static func easeIn(_ t: Double) -> CGFloat { CGFloat(t * t) }

    private static func easeOut(_ t: Double) -> CGFloat { CGFloat(1 - (1 - t) * (1 - t)) }
}
