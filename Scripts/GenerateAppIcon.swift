#!/usr/bin/env swift
//
//  GenerateAppIcon.swift
//  Blink
//
//  Renders the actual RobotHead SwiftUI view to icon PNGs.
//  Run: swift Scripts/GenerateAppIcon.swift
//

import SwiftUI

// MARK: - Geometry (copied from RobotHead.swift)

enum RobotGeometry {
    static let baseSize: CGFloat = 24
    static let faceWidthRatio: CGFloat = 20
    static let faceHeightRatio: CGFloat = 15
    static let faceCornerRadiusRatio: CGFloat = 4.5
    static let eyeSpacingRatio: CGFloat = 2.6
    static let eyeWidthRatio: CGFloat = 2.5
    static let eyeHeightRatio: CGFloat = 5.0
    static let minEyeHeightRatio: CGFloat = 0.6
}

// MARK: - RobotHead (copied from RobotHead.swift — identical Canvas)

struct RobotHead: View {
    var size: CGFloat = 18
    private var scale: CGFloat { size / RobotGeometry.baseSize }

    var body: some View {
        Canvas { context, canvasSize in
            let mid = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)

            // Face
            let faceWidth = RobotGeometry.faceWidthRatio * scale
            let faceHeight = RobotGeometry.faceHeightRatio * scale
            let faceRect = CGRect(
                x: mid.x - faceWidth / 2,
                y: mid.y - faceHeight / 2,
                width: faceWidth,
                height: faceHeight
            )
            let facePath = Path(roundedRect: faceRect, cornerRadius: RobotGeometry.faceCornerRadiusRatio * scale)
            let faceOpacity: Double = 0.25
            context.fill(facePath, with: .color(.black.opacity(faceOpacity)))

            // Eyes
            let eyeCenterY = faceRect.midY - 1.5 * scale
            let eyeSpacing = RobotGeometry.eyeSpacingRatio * scale
            let eyeWidth = RobotGeometry.eyeWidthRatio * scale
            let fullEyeHeight = RobotGeometry.eyeHeightRatio * scale
            let eyeHeight = max(fullEyeHeight * 1.0, RobotGeometry.minEyeHeightRatio * scale)
            let eyeCornerRadius = eyeWidth / 2

            for xOffset in [-eyeSpacing, eyeSpacing] {
                let eyeX = mid.x + xOffset
                let eyeRect = CGRect(
                    x: eyeX - eyeWidth / 2,
                    y: eyeCenterY - eyeHeight / 2,
                    width: eyeWidth,
                    height: eyeHeight
                )

                context.fill(
                    Path(roundedRect: eyeRect, cornerRadius: eyeCornerRadius),
                    with: .color(.black.opacity(0.75))
                )
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Icon View (robot centered on rounded-rect background)

struct AppIconView: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.22)
                .fill(Color(nsColor: .windowBackgroundColor))

            RobotHead(size: size)
        }
        .frame(width: size, height: size)
        .environment(\.colorScheme, .light)
    }
}

// MARK: - Render

let sizes: [Int] = [16, 32, 64, 128, 256, 512, 1024]

let scriptURL = URL(fileURLWithPath: #file)
let projectRoot = scriptURL.deletingLastPathComponent().deletingLastPathComponent()
let outputDir = projectRoot
    .appendingPathComponent("Blink")
    .appendingPathComponent("Assets.xcassets")
    .appendingPathComponent("AppIcon.appiconset")

@MainActor
func generate() throws {
    print("Generating Blink app icons...")
    print("Output: \(outputDir.path)\n")

    try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

    for size in sizes {
        let view = AppIconView(size: CGFloat(size))
        let renderer = ImageRenderer(content: view)
        renderer.scale = 1.0

        guard let cgImage = renderer.cgImage else {
            print("  FAILED: icon_\(size).png")
            continue
        }

        let bitmap = NSBitmapImageRep(cgImage: cgImage)
        guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
            print("  FAILED: icon_\(size).png")
            continue
        }

        let filename = "icon_\(size).png"
        let url = outputDir.appendingPathComponent(filename)
        try pngData.write(to: url)
        print("  \(filename) (\(size)x\(size))")
    }

    print("\nDone! Generated \(sizes.count) icons.")
}

try MainActor.assumeIsolated { try generate() }
