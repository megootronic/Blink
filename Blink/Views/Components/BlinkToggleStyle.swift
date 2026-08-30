import SwiftUI

// The native switch ignores every public accent channel inside an agent
// panel, so the track is drawn rather than tinted.
struct BlinkToggleStyle: ToggleStyle {
    private static let scale: CGFloat = 22.0 / 28.0

    private static let trackWidth = 64 * scale
    private static let trackHeight = 28 * scale
    private static let knobWidth = 38 * scale
    private static let knobHeight = 24 * scale
    private static let inset = 2 * scale

    func makeBody(configuration: Configuration) -> some View {
        let travel = (Self.trackWidth - Self.knobWidth) / 2 - Self.inset

        Button {
            withAnimation(.bouncy(duration: 0.28, extraBounce: 0.05)) {
                configuration.isOn.toggle()
            }
        } label: {
            Capsule()
                .fill(configuration.isOn ? Color.accent : Color.primary.opacity(0.14))
                .frame(width: Self.trackWidth, height: Self.trackHeight)
                .overlay {
                    Capsule()
                        .fill(.white)
                        .frame(width: Self.knobWidth, height: Self.knobHeight)
                        .shadow(color: .black.opacity(0.25), radius: 2, y: 0.5)
                        .offset(x: configuration.isOn ? travel : -travel)
                }
        }
        .buttonStyle(.plain)
    }
}
