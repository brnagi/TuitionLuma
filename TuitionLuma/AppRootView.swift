import SwiftUI

struct AppRootView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        if hasCompletedOnboarding {
            MainTabView()
        } else {
            OnboardingView {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
                    hasCompletedOnboarding = true
                }
            }
        }
    }
}
