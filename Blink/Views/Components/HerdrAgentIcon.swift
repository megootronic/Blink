import AppKit
import SwiftUI

enum HerdrAgentIcon {
    private static let templateKinds: Set<String> = [
        "cline", "copilot", "cursor", "droid", "grok", "hermes",
        "kilo", "mastracode", "opencode", "pi",
    ]

    static func image(for kind: String) -> NSImage? {
        let kind = kind.lowercased()

        if kind == "omp" {
            return NSImage(
                systemSymbolName: "option",
                accessibilityDescription: "Oh My Pi"
            )
        }

        for ext in ["svg", "png", "webp"] {
            // Xcode copies Agents/* flat into Contents/Resources/.
            guard let url = Bundle.main.url(forResource: kind, withExtension: ext),
                  let logo = NSImage(contentsOf: url) else { continue }

            logo.size = NSSize(width: 14, height: 14)
            logo.isTemplate = templateKinds.contains(kind)
            return logo
        }

        return NSImage(
            systemSymbolName: "cpu",
            accessibilityDescription: kind
        )
    }
}

struct HerdrAgentIconView: View {
    let kind: String

    var body: some View {
        Group {
            if let image = HerdrAgentIcon.image(for: kind) {
                Image(nsImage: image)
                    .resizable()
                    .renderingMode(image.isTemplate ? .template : .original)
                    .interpolation(.high)
                    .frame(width: 14, height: 14)
                    .foregroundStyle(.primary)
            }
        }
        .frame(width: 18, height: 18)
        .accessibilityHidden(true)
    }
}
