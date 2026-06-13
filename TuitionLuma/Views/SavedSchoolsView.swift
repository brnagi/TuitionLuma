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
                        shortlistEmptyState
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
            SavedSchoolShortlistCard(
                school: school,
                isCompared: appViewModel.isCompared(school),
                onRemoveTapped: { _ = appViewModel.toggleSaved(school) },
                onCompareTapped: { compareTapped(school) }
            )
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens school details.")
    }

    @ViewBuilder
    private var savedLimitPrompt: some View {
        if proPurchaseManager.state.isPro {
            EmptyView()
        } else {
            let limit = ProAccessPolicy.savedSchoolLimit(for: proPurchaseManager.state) ?? 0
            UpgradePrompt(
                title: "\(appViewModel.savedSchools.count)/\(limit) free saves used",
                message: "Upgrade for unlimited saved schools and richer family planning.",
                action: { isShowingPaywall = true }
            )
        }
    }

    private var shortlistEmptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "bookmark")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(LumaTheme.coral)
                .frame(width: 76, height: 76)
                .background(LumaTheme.aqua.opacity(0.16), in: Circle())
                .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text("Build your college shortlist")
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(LumaTheme.ink)

                Text("Save schools you want to revisit, then compare cost, aid, debt, and outcomes side by side.")
                    .font(.subheadline)
                    .foregroundStyle(LumaTheme.slate)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button {
                selectExploreTab()
            } label: {
                Label("Explore Schools", systemImage: "magnifyingglass")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 50)
                    .background(LumaTheme.heroGradient, in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityHint("Switches to Explore to search for schools.")
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
        .overlay {
            RoundedRectangle(cornerRadius: LumaTheme.cardRadius)
                .stroke(LumaTheme.cardStroke)
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

    private func selectExploreTab() {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = scene.windows.first(where: \.isKeyWindow)?.rootViewController,
              let tabBarController = rootViewController.findTabBarController() else {
            return
        }

        tabBarController.selectedIndex = 0
    }
}

private struct SavedSchoolShortlistCard: View {
    var school: School
    var isCompared: Bool
    var onRemoveTapped: () -> Void
    var onCompareTapped: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                lumaScoreBlock

                VStack(alignment: .leading, spacing: 6) {
                    Text(school.name)
                        .font(.title3.weight(.heavy))
                        .foregroundStyle(LumaTheme.ink)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("\(school.city), \(school.state)")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(LumaTheme.slate)
                        .lineLimit(1)

                    Text(school.valueLabel)
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(scoreTint)
                        .padding(.vertical, 5)
                        .padding(.horizontal, 9)
                        .background(scoreTint.opacity(0.10), in: Capsule())
                }
            }

            metricRow

            HStack(spacing: 10) {
                shortlistAction(
                    title: isCompared ? "Compared" : "Compare",
                    systemImage: isCompared ? "checkmark.circle.fill" : "plus.circle",
                    tint: isCompared ? LumaTheme.scorePurple : LumaTheme.ink,
                    action: onCompareTapped
                )

                shortlistAction(
                    title: "Remove",
                    systemImage: "bookmark.slash",
                    tint: LumaTheme.slate,
                    action: onRemoveTapped
                )
            }
        }
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
        .overlay {
            RoundedRectangle(cornerRadius: LumaTheme.cardRadius)
                .stroke(LumaTheme.cardStroke)
        }
        .shadow(color: LumaTheme.cardShadow.opacity(0.8), radius: 14, y: 8)
    }

    private var lumaScoreBlock: some View {
        VStack(spacing: 2) {
            Text("\(school.lumaScore)")
                .font(.system(size: 34, weight: .heavy))
                .foregroundStyle(scoreTint)
                .lineLimit(1)

            Text("Luma")
                .font(.caption2.weight(.heavy))
                .foregroundStyle(LumaTheme.slate)
        }
        .frame(width: 76, height: 76)
        .background(scoreTint.opacity(0.12), in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Luma Score")
        .accessibilityValue("\(school.lumaScore), \(school.valueLabel)")
    }

    private var metricRow: some View {
        HStack(spacing: 0) {
            shortlistMetric(
                title: "Net Price",
                value: school.costEstimate.averageNetPrice > 0 ? LumaFormat.compactCurrency(school.costEstimate.averageNetPrice) : "N/A",
                tint: school.costEstimate.averageNetPrice > 45_000 ? LumaTheme.warningOrange : LumaTheme.valueGreen
            )

            Divider()
                .frame(height: 30)

            shortlistMetric(
                title: "Earnings",
                value: school.medianEarnings > 0 ? LumaFormat.compactCurrency(school.medianEarnings) : "N/A",
                tint: LumaTheme.outcomeTeal
            )

            Divider()
                .frame(height: 30)

            shortlistMetric(
                title: "Grad Rate",
                value: school.graduationRate > 0 ? school.graduationRate.formatted(LumaFormat.percent) : "N/A",
                tint: LumaTheme.outcomeTeal
            )
        }
        .padding(.vertical, 11)
        .background(.black.opacity(0.025), in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
    }

    private var scoreTint: Color {
        switch school.valueLabel {
        case "Excellent Value":
            LumaTheme.valueGreen
        case "Good Value":
            LumaTheme.outcomeTeal
        case "Fair Value":
            LumaTheme.scoreGold
        case "Expensive":
            LumaTheme.warningOrange
        default:
            LumaTheme.scorePurple
        }
    }

    private func shortlistMetric(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.subheadline.weight(.heavy))
                .foregroundStyle(tint)
                .lineLimit(1)

            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(LumaTheme.slate)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(value)
    }

    private func shortlistAction(title: String, systemImage: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.heavy))
                .foregroundStyle(tint)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
                .background(.white, in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(tint.opacity(0.16))
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

private extension UIViewController {
    func findTabBarController() -> UITabBarController? {
        if let tabBarController = self as? UITabBarController {
            return tabBarController
        }

        for child in children {
            if let tabBarController = child.findTabBarController() {
                return tabBarController
            }
        }

        return presentedViewController?.findTabBarController()
    }
}
