import AppKit

enum Accessibility {
    static var isTrusted: Bool { AXIsProcessTrusted() }

    static func openSystemSettings() {
        guard let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        ) else { return }
        NSWorkspace.shared.open(url)
    }
}

extension AppState {
    func focusSimulator(_ simulator: Simulator) {
        let trusted = AXIsProcessTrustedWithOptions(
            [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        )

        guard trusted, let simApp = NSRunningApplication.runningApplications(
            withBundleIdentifier: "com.apple.iphonesimulator"
        ).first else { return }

        let appRef = AXUIElementCreateApplication(simApp.processIdentifier)
        var windowsRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(appRef, kAXWindowsAttribute as CFString, &windowsRef) == .success,
              let windows = windowsRef as? [AXUIElement] else { return }

        var targetWindow: AXUIElement?
        for window in windows {
            var titleRef: CFTypeRef?
            AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleRef)
            if let title = titleRef as? String, title.contains(simulator.name) {
                targetWindow = window
            }
        }

        guard let target = targetWindow else { return }

        AXUIElementSetAttributeValue(target, kAXMinimizedAttribute as CFString, false as CFTypeRef)
        AXUIElementPerformAction(target, kAXRaiseAction as CFString)

        if !simApp.isActive {
            simApp.activate()
        }
    }

    func copyToClipboard(text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}
