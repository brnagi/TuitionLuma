import SwiftUI

struct AppRootView: View {
    @EnvironmentObject private var appViewModel: AppViewModel

    var body: some View {
        if appViewModel.hasCompletedOnboarding {
            MainTabView()
        } else {
            OnboardingView {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
                    appViewModel.hasCompletedOnboarding = true
                }
            }
        }
    }
}
