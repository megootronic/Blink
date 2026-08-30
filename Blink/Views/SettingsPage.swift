import SwiftUI

struct SettingsPage: View {
    let isVisible: Bool
    let back: () -> Void

    @State private var launchAtLogin = LoginItem.isEnabled
    @State private var failure: String?
    @State private var accessibilityTrusted = Accessibility.isTrusted

    var body: some View {
        VStack(spacing: 0) {
            PanelPageHeader(title: "Settings", back: back)
            PanelDivider()

            PanelToggleRow("Start at login", isOn: $launchAtLogin)

            if let failure {
                Text(failure)
                    .font(.system(size: 10))
                    .foregroundStyle(Color.alert)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 6)
            }

            PanelDivider()

            if accessibilityTrusted {
                PanelStatusRow(title: "Simulator focus", detail: "Allowed")
            } else {
                PanelRow("Simulator focus", detail: "Not allowed") {
                    Accessibility.openSystemSettings()
                }
            }

            PanelDivider()
            PanelRow("Report an Issue") {
                NSWorkspace.shared.open(Blink.issuesURL)
            }
            PanelDivider()

            Spacer()
        }
        .onChange(of: launchAtLogin) { _, enabled in
            apply(enabled)
        }
        .onChange(of: isVisible) { _, visible in
            guard visible else { return }
            accessibilityTrusted = Accessibility.isTrusted
            launchAtLogin = LoginItem.isEnabled
        }
    }

    private func apply(_ enabled: Bool) {
        do {
            try LoginItem.setEnabled(enabled)
            failure = nil
        } catch {
            failure = error.localizedDescription
            launchAtLogin = LoginItem.isEnabled
        }
    }
}
