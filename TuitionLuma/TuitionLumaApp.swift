import SwiftUI

@main
struct TuitionLumaApp: App {
    @StateObject private var appViewModel = AppViewModel()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(appViewModel)
        }
    }
}
