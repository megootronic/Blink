//
//  WelcomeWindowController.swift
//  Blink
//
//  Shows the welcome window using NSWindow to avoid SwiftUI Window scene issues
//

import SwiftUI

enum WelcomeWindowController {
    private static var window: NSWindow?

    @MainActor
    static func show() {
        guard window == nil else { return }

        let hostingView = NSHostingView(rootView: WelcomeView())
        hostingView.frame = NSRect(x: 0, y: 0, width: 320, height: 380)

        let w = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 380),
            styleMask: [.titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        w.contentView = hostingView
        w.titlebarAppearsTransparent = true
        w.titleVisibility = .hidden
        w.isMovableByWindowBackground = true
        w.center()
        w.isReleasedWhenClosed = false
        w.makeKeyAndOrderFront(nil)

        window = w
    }

    @MainActor
    static func close() {
        window?.close()
        window = nil
    }
}
