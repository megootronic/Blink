import SwiftUI

@main
struct BlinkApp: App {
    @NSApplicationDelegateAdaptor(MenuBarController.self) private var menuBar

    var body: some Scene {
        Settings { EmptyView() }
    }
}
