import SwiftUI

enum MenuBarIcon {
    static let iconSize: CGFloat = 22

    static let awakeOpenness = RobotGeometry.eyeOpenness(for: .open)
    static let asleepOpenness = RobotGeometry.eyeOpenness(for: .halfClosed)

    @MainActor
    static func render(eyeOpenness: CGFloat) -> NSImage {
        let size = NSSize(width: iconSize, height: iconSize)
        let view = MenuBarRobot(size: iconSize, eyeOpenness: eyeOpenness)

        let renderer = ImageRenderer(content: view)
        renderer.scale = 2.0

        guard let cgImage = renderer.cgImage else {
            return NSImage(systemSymbolName: "network", accessibilityDescription: "Blink")!
        }

        let image = NSImage(cgImage: cgImage, size: size)
        image.isTemplate = true
        return image
    }
}

private struct MenuBarRobot: View {
    let size: CGFloat
    let eyeOpenness: CGFloat

    private var scale: CGFloat { size / RobotGeometry.baseSize }

    var body: some View {
        Canvas { context, canvasSize in
            let mid = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2 + 0.5)

            let faceWidth = RobotGeometry.faceWidthRatio * scale
            let faceHeight = RobotGeometry.faceHeightRatio * scale
            let faceRect = CGRect(
                x: mid.x - faceWidth / 2,
                y: mid.y - faceHeight / 2,
                width: faceWidth,
                height: faceHeight
            )

            var facePath = Path(roundedRect: faceRect, cornerRadius: RobotGeometry.faceCornerRadiusRatio * scale)

            let eyeCenterY = faceRect.midY - RobotGeometry.eyeCenterOffsetRatio * scale
            let eyeSpacing = RobotGeometry.eyeSpacingRatio * scale
            let eyeWidth = RobotGeometry.eyeWidthRatio * scale
            let fullEyeHeight = RobotGeometry.eyeHeightRatio * scale
            let eyeHeight = max(fullEyeHeight * eyeOpenness, RobotGeometry.minEyeHeightRatio * scale)
            let eyeCornerRadius = eyeWidth / 2

            for xOffset in [-eyeSpacing, eyeSpacing] {
                let eyeRect = CGRect(
                    x: mid.x + xOffset - eyeWidth / 2,
                    y: eyeCenterY - eyeHeight / 2,
                    width: eyeWidth,
                    height: eyeHeight
                )
                facePath.addPath(Path(roundedRect: eyeRect, cornerRadius: eyeCornerRadius))
            }

            context.fill(facePath, with: .color(.black), style: FillStyle(eoFill: true))
        }
        .frame(width: size, height: size)
    }
}
