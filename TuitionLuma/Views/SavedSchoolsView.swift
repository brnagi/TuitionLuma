import SwiftUI

struct SavedSchoolsView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @EnvironmentObject private var proPurchaseManager: ProPurchaseManager
    @State private var isShowingPaywall = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Saved")
                        .font(.largeTitle.weight(.heavy))
                        .foregroundStyle(LumaTheme.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    savedLimitPrompt

                    if appViewModel.savedSchools.isEmpty {
                        EmptyStateView(
                            title: "No saved schools yet",
                            message: "Tap the bookmark on any school to build a shortlist for your family conversation.",
                            systemImage: "bookmark"
                        )
                        .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
                    } else {
                        LazyVStack(alignment: .leading, spacing: 14) {
                            ForEach(appViewModel.savedSchools) { school in
                                savedSchoolLink(school)
                            }
                        }
                    }
                }
                .padding()
                .padding(.bottom, 72)
            }
            .background(LumaTheme.canvas)
            .sheet(isPresented: $isShowingPaywall) {
                PaywallView()
                    .environmentObject(proPurchaseManager)
            }
        }
    }

    private func savedSchoolLink(_ school: School) -> some View {
        NavigationLink {
            SchoolDetailView(school: school)
        } label: {
            SchoolCard(
                school: school,
                isSaved: true,
                isCompared: appViewModel.isCompared(school),
                onSaveTapped: { _ = appViewModel.toggleSaved(school) },
                onCompareTapped: { compareTapped(school) }
            )
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens school details.")
    }

    @ViewBuilder
    private var savedLimitPrompt: some View {
        if proPurchaseManager.state.isPro {
            HStack {
                ProBadge()
                Text("Unlimited saved schools are unlocked.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(LumaTheme.ink)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(LumaTheme.mint.opacity(0.12), in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Unlimited saved schools are unlocked.")
        } else {
            let limit = ProAccessPolicy.savedSchoolLimit(for: proPurchaseManager.state) ?? 0
            UpgradePrompt(
                title: "\(appViewModel.savedSchools.count)/\(limit) free saves used",
                message: "Upgrade for unlimited saved schools and richer family planning.",
                action: { isShowingPaywall = true }
            )
        }
    }

    private func compareTapped(_ school: School) {
        if appViewModel.isCompared(school) {
            _ = appViewModel.removeFromCompare(school)
            return
        }

        let limit = ProAccessPolicy.compareSchoolLimit(for: proPurchaseManager.state)
        let result = appViewModel.addToCompare(school, compareLimit: limit)

        if result == .limitReached {
            isShowingPaywall = true
        }

        // TODO: Route directly to Compare after adding once global tab selection is introduced.
    }
}
