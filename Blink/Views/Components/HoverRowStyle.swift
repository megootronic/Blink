import SwiftUI

struct HoverRowStyle: ViewModifier {
    static let horizontalPadding: CGFloat = 8.5

    @Environment(ScrollActivity.self) private var scrollActivity

    @State private var isHovered = false

    let onHoverChanged: ((Bool) -> Void)?

    init(onHoverChanged: ((Bool) -> Void)? = nil) {
        self.onHoverChanged = onHoverChanged
    }

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, Self.horizontalPadding)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovered ? Color.primary.opacity(0.06) : .clear)
            )
            .scaleEffect(isHovered ? 1.005 : 1.0)
            .animation(.easeOut(duration: 0.15), value: isHovered)
            .onHover { hovering in
                if hovering && scrollActivity.isScrolling { return }
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
