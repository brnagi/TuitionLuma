import SwiftUI

struct SavedSchoolsView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @EnvironmentObject private var subscriptionManager: MockSubscriptionManager
    @State private var isShowingPaywall = false

    var body: some View {
        NavigationStack {
            ZStack {
                LumaTheme.canvas
                    .ignoresSafeArea()

                if appViewModel.savedSchools.isEmpty {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Saved")
                            .font(.largeTitle.weight(.heavy))
                            .foregroundStyle(LumaTheme.ink)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        savedLimitPrompt

                        EmptyStateView(
                            title: "No saved schools yet",
                            message: "Tap the bookmark on any school to build a shortlist for your family conversation.",
                            systemImage: "bookmark"
                        )
                    }
                    .padding()
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 14) {
                            Text("Saved")
                                .font(.largeTitle.weight(.heavy))
                                .foregroundStyle(LumaTheme.ink)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            savedLimitPrompt

                            ForEach(appViewModel.savedSchools) { school in
                                NavigationLink {
                                    SchoolDetailView(school: school)
                                } label: {
                                    SchoolCard(
                                        school: school,
                                        isSaved: true,
                                        onSaveTapped: { _ = appViewModel.toggleSaved(school) }
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                }
            }
            .sheet(isPresented: $isShowingPaywall) {
                PaywallView()
                    .environmentObject(subscriptionManager)
            }
        }
    }

    @ViewBuilder
    private var savedLimitPrompt: some View {
        if subscriptionManager.state.isPro {
            HStack {
                ProBadge()
                Text("Unlimited saved schools are unlocked.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(LumaTheme.ink)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(LumaTheme.mint.opacity(0.12), in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
        } else {
            let limit = SubscriptionPolicy.savedSchoolLimit(for: subscriptionManager.state) ?? 0
            UpgradePrompt(
                title: "\(appViewModel.savedSchools.count)/\(limit) free saves used",
                message: "Upgrade for unlimited saved schools and richer family planning.",
                action: { isShowingPaywall = true }
            )
        }
    }
}
