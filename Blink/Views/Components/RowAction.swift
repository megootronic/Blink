import SwiftUI

struct RowAction: View {
    static let spacing: CGFloat = 4

    private static let diameter: CGFloat = 22

    let symbol: String
    let help: String
    var tint: Color?
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(glyphColor)
                .frame(width: Self.diameter, height: Self.diameter)
                .background {
                    Circle()
                        .fill(containerFill)
                        .padding(tint == nil ? 0 : 1)
                }
        }
        .buttonStyle(.plain)
        .help(help)
        .onHover { isHovered = $0 }
        .animation(.easeOut(duration: 0.12), value: isHovered)
    }

    private var containerFill: Color {
        guard let tint else {
            return Color.primary.opacity(isHovered ? 0.34 : 0.26)
        }
        return tint.opacity(isHovered ? 1.0 : 0.85)
    }

    private var glyphColor: Color {
        tint == nil ? .primary : .white
    }
}
