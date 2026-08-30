import SwiftUI

struct PanelRow: View {
    private let title: String
    private let detail: String?
    private let action: () -> Void

    @State private var isHovered = false

    init(_ title: String, detail: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.detail = detail
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 12))

                Spacer(minLength: 0)

                if let detail {
                    Text(detail)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .contentShape(Rectangle())
                .background(isHovered ? Color.primary.opacity(0.06) : .clear)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

struct PanelStatusRow: View {
    let title: String
    let detail: String

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.system(size: 12))

            Spacer(minLength: 0)

            Text(detail)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
    }
}

struct PanelToggleRow: View {
    private let title: String
    private let isOn: Binding<Bool>

    init(_ title: String, isOn: Binding<Bool>) {
        self.title = title
        self.isOn = isOn
    }

    var body: some View {
        HStack(spacing: 0) {
            Text(title)
                .font(.system(size: 12))

            Spacer(minLength: 8)

            Toggle("", isOn: isOn)
                .labelsHidden()
                .toggleStyle(BlinkToggleStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 7)
    }
}

struct PanelDivider: View {
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [.clear, .secondary.opacity(0.2), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 0.5)
    }
}

struct PanelPageHeader: View {
    let title: String
    let back: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: back) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 11, weight: .semibold))
                    .frame(width: 26, height: 26)
                    .background(.primary.opacity(0.08), in: Circle())
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)

            Text(title)
                .font(.system(size: 13, weight: .semibold))

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
