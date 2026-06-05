import SwiftUI

@main
struct TuitionLumaApp: App {
    @StateObject private var appViewModel = AppViewModel()
    @StateObject private var subscriptionManager = MockSubscriptionManager()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(appViewModel)
                .environmentObject(subscriptionManager)
        }
    }
}
