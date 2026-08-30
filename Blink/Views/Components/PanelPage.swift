import SwiftUI

struct PanelPage: ViewModifier {
    let isActive: Bool
    let restingOffset: CGFloat

    private static let arrive = Animation.snappy(duration: 0.2).delay(0.1)
    private static let leave = Animation.snappy(duration: 0.14)

    func body(content: Content) -> some View {
        content
            .opacity(isActive ? 1 : 0)
            .offset(x: isActive ? 0 : restingOffset)
            .allowsHitTesting(isActive)
            .animation(isActive ? Self.arrive : Self.leave, value: isActive)
    }
}

extension View {
    func panelPage(isActive: Bool, restingOffset: CGFloat) -> some View {
        modifier(PanelPage(isActive: isActive, restingOffset: restingOffset))
    }
}
