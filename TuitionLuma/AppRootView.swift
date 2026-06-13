import SwiftUI

struct AppRootView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @EnvironmentObject private var studentProfileStore: StudentProfileStore
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        if hasCompletedOnboarding {
            MainTabView()
        } else {
            OnboardingView(profile: $studentProfileStore.profile) {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
                    hasCompletedOnboarding = true
                }
            }
        }
    }
}
