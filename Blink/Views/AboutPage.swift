import SwiftUI

struct AboutPage: View {
    let back: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            PanelPageHeader(title: "About", back: back)
            PanelDivider()

            Spacer()

            VStack(spacing: 6) {
                Text("Blink")
                    .font(.system(size: 30, weight: .bold))
                    .tracking(0.5)

                Text(Blink.version)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.secondary)

                VStack(spacing: 4) {
                    Text("Engineered at")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.secondary)

                    Link(destination: Blink.authorURL) {
                        Text("mo.software")
                            .font(.system(size: 15, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.accent)
                    }
                }
                .padding(.top, 22)
            }

            Spacer()

            Text("MIT licensed")
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundStyle(.secondary.opacity(0.8))
                .padding(.bottom, 14)
        }
        .frame(maxWidth: .infinity)
    }
}
