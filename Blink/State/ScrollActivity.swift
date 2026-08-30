import SwiftUI

@Observable
final class ScrollActivity {
    private(set) var isScrolling = false

    private var settleTask: Task<Void, Never>?
    private static let settleDelay = Duration.milliseconds(140)

    @MainActor
    func noteScroll() {
        isScrolling = true
        settleTask?.cancel()
        settleTask = Task { [weak self] in
            try? await Task.sleep(for: Self.settleDelay)
            guard !Task.isCancelled else { return }
            self?.isScrolling = false
        }
    }
}
