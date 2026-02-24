import SwiftUI

@main
struct Main1001DailyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // No windows — pure menu bar agent app
        Settings { EmptyView() }
    }
}
