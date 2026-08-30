import SwiftUI

struct ColorBar: View {
    static let gutter: CGFloat = 13

    let color: Color

    var isWorking: Bool = false

    private static let height: CGFloat = 32
    private static let highlightHeight: CGFloat = 14

    @State private var travel: CGFloat = -highlightHeight

    var body: some View {
        RoundedRectangle(cornerRadius: 1.5)
            .fill(color.opacity(isWorking ? 0.25 : 1))
            .frame(width: 3, height: Self.height)
            .overlay(alignment: .top) {
                if isWorking {
                    LinearGradient(
                        colors: [color.opacity(0), color, color.opacity(0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(width: 3, height: Self.highlightHeight)
                    .offset(y: travel)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 1.5))
            .padding(.trailing, 10)
            .onAppear { if isWorking { startTravelling() } }
            .onChange(of: isWorking) { _, working in
                if working {
                    startTravelling()
                } else {
                    withAnimation(.none) { travel = -Self.highlightHeight }
                }
            }
    }

    private func startTravelling() {
        travel = -Self.highlightHeight
        withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: false)) {
            travel = Self.height
        }
    }
}
