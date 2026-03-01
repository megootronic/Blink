//
//  BlinkApp.swift
//  Blink
//
//  Menu bar utility for monitoring dev servers and simulators
//

import SwiftUI

@main
struct BlinkApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environment(appState)
        } label: {
            MenuBarLabel(count: appState.totalCount)
        }
        .menuBarExtraStyle(.window)

        Window("Welcome to Blink", id: "welcome") {
            WelcomeView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }
}

private struct MenuBarLabel: View {
    let count: Int
    @AppStorage("hasLaunchedBefore") private var hasLaunchedBefore = false
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Image(nsImage: MenuBarIcon.render(count: count))
            .onAppear {
                if !hasLaunchedBefore {
                    openWindow(id: "welcome")
                }
            }
    }
}
