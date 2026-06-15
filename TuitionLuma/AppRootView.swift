import SwiftUI

struct AppRootView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @EnvironmentObject private var studentProfileStore: StudentProfileStore
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var isShowingInitialProfile = false

    var body: some View {
        if hasCompletedOnboarding {
            MainTabView()
                .sheet(isPresented: $isShowingInitialProfile) {
                    StudentProfileEditorView(profile: $studentProfileStore.profile)
                }
        } else {
            OnboardingView(profile: $studentProfileStore.profile) {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
                    isShowingInitialProfile = true
                    hasCompletedOnboarding = true
                }
            }
        }
    }
}
