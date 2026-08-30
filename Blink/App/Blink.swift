import Foundation

enum Blink {
    static var version: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        return "v\(short)"
    }

    static let repositoryURL = URL(string: "https://github.com/megootronic/Blink")!
    static let issuesURL = URL(string: "https://github.com/megootronic/Blink/issues/new")!
    static let authorURL = URL(string: "https://mo.software")!
}
