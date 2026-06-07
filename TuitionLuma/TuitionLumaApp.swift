import SwiftUI

@main
struct TuitionLumaApp: App {
    @StateObject private var appViewModel = AppViewModel()
    @StateObject private var proPurchaseManager = ProPurchaseManager()
    @StateObject private var studentProfileStore = StudentProfileStore()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(appViewModel)
                .environmentObject(proPurchaseManager)
                .environmentObject(studentProfileStore)
        }
    }
}
