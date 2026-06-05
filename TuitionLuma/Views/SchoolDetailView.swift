import SwiftUI

struct SchoolDetailView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @EnvironmentObject private var subscriptionManager: MockSubscriptionManager
    @State private var isShowingPaywall = false
    var school: School

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                hero
                quickStats
                CostBreakdownCard(cost: school.costEstimate)
                proPlanningSection
                programSection
                outcomesSection
            }
            .padding()
        }
        .background(LumaTheme.canvas)
        .navigationTitle(school.name)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    saveTapped()
                } label: {
                    Image(systemName: appViewModel.isSaved(school) ? "bookmark.fill" : "bookmark")
                        .foregroundStyle(appViewModel.isSaved(school) ? LumaTheme.coral : LumaTheme.ink)
                }
                .accessibilityLabel(appViewModel.isSaved(school) ? "Remove saved school" : "Save school")
            }
        }
        .sheet(isPresented: $isShowingPaywall) {
            PaywallView()
                .environmentObject(subscriptionManager)
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(school.type.rawValue)
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(.white)
                    .padding(.vertical, 7)
                    .padding(.horizontal, 10)
                    .background(.white.opacity(0.2), in: Capsule())

                Spacer()

                Text("\(school.city), \(school.state)")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white.opacity(0.9))
            }

            Text(school.name)
                .font(.system(size: 34, weight: .heavy))
                .foregroundStyle(.white)
                .lineLimit(3)
                .minimumScaleFactor(0.72)

            Text(school.campusVibe)
                .font(.headline)
                .foregroundStyle(.white.opacity(0.92))

            HStack(spacing: 8) {
                ForEach(school.highlights.prefix(2), id: \.self) { highlight in
                    Text(highlight)
                        .font(.caption.weight(.bold))
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 10)
                        .foregroundStyle(.white)
                        .background(.white.opacity(0.18), in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LumaTheme.heroGradient, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
    }

    private var quickStats: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            StatPill(title: "Net price", value: LumaFormat.compactCurrency(school.costEstimate.averageNetPrice), systemImage: "dollarsign", tint: LumaTheme.mint)
            StatPill(title: "Earnings", value: LumaFormat.compactCurrency(school.medianEarnings), systemImage: "chart.line.uptrend.xyaxis", tint: LumaTheme.aqua)
            StatPill(title: "Grad rate", value: school.graduationRate.formatted(LumaFormat.percent), systemImage: "graduationcap.fill", tint: LumaTheme.coral)
            StatPill(title: "Avg debt", value: LumaFormat.compactCurrency(school.averageDebt), systemImage: "creditcard.fill", tint: LumaTheme.sun)
        }
    }

    private var programSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Programs to compare")
                .font(.title3.weight(.bold))
                .foregroundStyle(LumaTheme.ink)

            ForEach(school.programs) { program in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(program.name)
                            .font(.headline)
                            .foregroundStyle(LumaTheme.ink)

                        Text("\(program.credential) • \(program.typicalDurationYears) years")
                            .font(.caption)
                            .foregroundStyle(LumaTheme.slate)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(program.medianEarnings.formatted(LumaFormat.currency))
                            .font(.headline.weight(.heavy))
                            .foregroundStyle(LumaTheme.ink)

                        Text("median pay")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(LumaTheme.slate)
                    }
                }
                .padding(14)
                .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
            }
        }
    }

    private var proPlanningSection: some View {
        VStack(spacing: 12) {
            if subscriptionManager.state.isPro {
                HStack {
                    Label("ROI score", systemImage: "chart.line.uptrend.xyaxis")
                        .font(.headline)
                        .foregroundStyle(LumaTheme.ink)

                    Spacer()

                    Text(roiScore)
                        .font(.title2.weight(.heavy))
                        .foregroundStyle(LumaTheme.mint)
                }
                .padding(16)
                .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))

                HStack(spacing: 10) {
                    scenarioPill("On campus")
                    scenarioPill("Off campus")
                    scenarioPill(school.type == .publicUniversity ? "In-state" : "Aid path")
                }
            } else {
                FeatureLock(
                    title: "Unlock deeper planning",
                    message: "See ROI score, affordability guidance, PDF sharing, and scenario modeling for this school.",
                    feature: .roiScore,
                    action: { isShowingPaywall = true }
                )
            }
        }
    }

    private var outcomesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Outcome snapshot")
                .font(.title3.weight(.bold))
                .foregroundStyle(LumaTheme.ink)

            ComparisonRow(title: "Students", values: [LumaFormat.number(school.studentCount)])
            ComparisonRow(title: "Acceptance rate", values: [school.acceptanceRate.formatted(LumaFormat.percent)])
            ComparisonRow(title: "Graduation rate", values: [school.graduationRate.formatted(LumaFormat.percent)])
        }
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
    }

    private var roiScore: String {
        let value = min(99, max(35, Int((school.medianEarnings / max(school.costEstimate.averageNetPrice, 1)) * 18)))
        return "\(value)/100"
    }

    private func scenarioPill(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.bold))
            .foregroundStyle(LumaTheme.ink)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(LumaTheme.aqua.opacity(0.12), in: Capsule())
    }

    private func saveTapped() {
        let limit = SubscriptionPolicy.savedSchoolLimit(for: subscriptionManager.state)
        let result = appViewModel.toggleSaved(school, savedLimit: limit)

        if result == .limitReached {
            isShowingPaywall = true
        }
    }
}
