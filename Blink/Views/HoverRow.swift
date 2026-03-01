//
//  HoverRow.swift
//  Blink
//
//  Shared row styling: color bar, hover background, and scale effect
//

import SwiftUI

// MARK: - Color Bar

struct ColorBar: View {
    let color: Color

    var body: some View {
        RoundedRectangle(cornerRadius: 1.5)
            .fill(color)
            .frame(width: 3, height: 32)
            .padding(.trailing, 10)
    }
}

// MARK: - Hover Row Modifier

struct HoverRowStyle: ViewModifier {
    @State private var isHovered = false

    let onHoverChanged: ((Bool) -> Void)?

    init(onHoverChanged: ((Bool) -> Void)? = nil) {
        self.onHoverChanged = onHoverChanged
    }

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovered ? Color.primary.opacity(0.06) : .clear)
            )
            .scaleEffect(isHovered ? 1.005 : 1.0)
            .animation(.easeOut(duration: 0.15), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
                onHoverChanged?(hovering)
            }
    }
}

extension View {
    func hoverRow(onHoverChanged: ((Bool) -> Void)? = nil) -> some View {
        modifier(HoverRowStyle(onHoverChanged: onHoverChanged))
    }
}
