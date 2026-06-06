import SwiftUI

@main
struct TuitionLumaApp: App {
    @StateObject private var appViewModel = AppViewModel()
    @StateObject private var proPurchaseManager = MockProPurchaseManager()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(appViewModel)
                .environmentObject(proPurchaseManager)
        }
    }
}
