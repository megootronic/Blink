import SwiftUI

enum RobotGeometry {
    static let baseSize: CGFloat = 24
    static let faceWidthRatio: CGFloat = 20
    static let faceHeightRatio: CGFloat = 15
    static let faceCornerRadiusRatio: CGFloat = 4.5
    static let eyeSpacingRatio: CGFloat = 2.6
    static let eyeWidthRatio: CGFloat = 2.5
    static let eyeHeightRatio: CGFloat = 5.0
    static let minEyeHeightRatio: CGFloat = 0.6
    static let eyeCenterOffsetRatio: CGFloat = 1.5

    static func eyeOpenness(for state: RobotHead.EyeState) -> CGFloat {
        switch state {
        case .open: 1.0
        case .halfClosed: 0.35
        case .closed: 0.0
        case .wide: 1.3
        }
    }
}
