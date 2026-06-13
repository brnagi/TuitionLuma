import SwiftUI

struct CompareView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @EnvironmentObject private var proPurchaseManager: ProPurchaseManager
    @StateObject private var viewModel = CompareViewModel()
    @State private var isShowingPaywall = false

    private var compareLimit: Int {
        ProAccessPolicy.compareSchoolLimit(for: proPurchaseManager.state)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    if viewModel.selectedSchools.isEmpty {
                        EmptyStateView(
                            title: "No schools selected",
                            message: "Use Explore to search live College Scorecard schools, then tap compare on the cards.",
                            systemImage: "rectangle.split.3x1"
                        )
                        .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
                    } else {
                        selectors
                        compareLimitPrompt
                        lumaScoreComparison
                        comparisonTable
                    }
                }
                .padding()
            }
            .background(LumaTheme.canvas)
            .onAppear {
                syncCompareSelection()
            }
            .onChange(of: proPurchaseManager.state) { _, newState in
                appViewModel.trimComparedSchools(to: ProAccessPolicy.compareSchoolLimit(for: newState))
                syncCompareSelection()
            }
            .onChange(of: appViewModel.comparedSchoolIDs) { _, _ in
                syncCompareSelection()
            }
            .sheet(isPresented: $isShowingPaywall) {
                PaywallView()
                    .environmentObject(proPurchaseManager)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Compare")
                .font(.largeTitle.weight(.heavy))
                .foregroundStyle(LumaTheme.ink)

            Text("Line up the tradeoffs.")
                .font(.title2.weight(.heavy))
                .foregroundStyle(LumaTheme.ink)

            Text("Swap schools to compare cost, debt, earnings, and completion side by side.")
                .font(.subheadline)
                .foregroundStyle(LumaTheme.slate)

                    HStack {
                        Text(proPurchaseManager.state.isPro ? "Pro compare: up to 5 schools" : "Free compare: up to 2 schools")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(proPurchaseManager.state.isPro ? LumaTheme.coral : LumaTheme.slate)

                if proPurchaseManager.state.isPro {
                    ProBadge(compact: true)
                }
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var selectors: some View {
        VStack(spacing: 10) {
            ForEach(viewModel.selectedSchools.indices, id: \.self) { index in
                Menu {
                    Picker(
                        "School \(index + 1)",
                        selection: Binding(
                            get: { viewModel.selectedSchools[index] },
                            set: { school in
                                appViewModel.replaceComparedSchool(at: index, with: school)
                                viewModel.replaceSchool(at: index, with: school)
                            }
                        )
                    ) {
                        ForEach(appViewModel.knownSchools) { school in
                            Text(school.name).tag(school)
                        }
                    }
                } label: {
                    HStack {
                        Text("\(index + 1)")
                            .font(.headline.weight(.heavy))
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(indexColor(index), in: Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            Text(viewModel.selectedSchools[index].name)
                                .font(.headline)
                                .foregroundStyle(LumaTheme.ink)
                                .lineLimit(1)

                            Text("\(viewModel.selectedSchools[index].city), \(viewModel.selectedSchools[index].state)")
                                .font(.caption)
                                .foregroundStyle(LumaTheme.slate)
                        }

                        Spacer()

                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(LumaTheme.slate)
                            .accessibilityHidden(true)
                    }
                    .padding(14)
                    .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Compared school \(index + 1)")
                    .accessibilityValue(viewModel.selectedSchools[index].name)
                }
                .accessibilityHint("Opens a menu to replace this compared school.")
            }

            if viewModel.selectedSchools.count < compareLimit && !appViewModel.knownSchools.isEmpty {
                Button {
                    addNextSchoolToCompare()
                } label: {
                    Label("Add School", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .foregroundStyle(LumaTheme.coral)
                        .frame(maxWidth: .infinity)
                        .padding(14)
                        .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add school")
                .accessibilityHint("Adds the next available school to your comparison.")
            }
        }
    }

    @ViewBuilder
    private var compareLimitPrompt: some View {
        if proPurchaseManager.state.isPro {
            EmptyView()
        } else {
            UpgradePrompt(
                title: "Need a bigger shortlist?",
                message: "Pro lets families compare up to 5 schools side by side.",
                action: { isShowingPaywall = true }
            )
        }
    }

    private var comparisonTable: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                ForEach(viewModel.selectedSchools) { school in
                    Text(school.name)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.72)
                        .frame(maxWidth: .infinity, minHeight: 46)
                        .padding(8)
                        .background(LumaTheme.heroGradient, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
                }
            }
            .padding(.bottom, 10)
            .accessibilityElement(children: .contain)

            ForEach(detailedMetrics) { metric in
                ComparisonRow(title: metric.title, values: metric.values)

                if metric.id != detailedMetrics.last?.id {
                    Divider()
                }
            }
        }
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
    }

    private var lumaScoreComparison: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Luma Score")
                .font(.headline)
                .foregroundStyle(LumaTheme.ink)

            HStack(spacing: 10) {
                ForEach(viewModel.selectedSchools) { school in
                    VStack(alignment: .leading, spacing: 5) {
                        Text("\(school.lumaScore)")
                            .font(.system(size: 30, weight: .heavy))
                            .foregroundStyle(lumaScoreColor(for: school.valueLabel))
                            .lineLimit(1)

                        Text(school.valueLabel)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(LumaTheme.ink)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
                    .padding(14)
                    .background(lumaScoreColor(for: school.valueLabel).opacity(0.12), in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
                }
            }
        }
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
        .accessibilityElement(children: .contain)
    }

    private var detailedMetrics: [ComparisonMetric] {
        viewModel.metrics.filter { !$0.title.localizedCaseInsensitiveContains("Luma") }
    }

    private func lumaScoreColor(for valueLabel: String) -> Color {
        let normalizedLabel = valueLabel.lowercased()

        if normalizedLabel.contains("excellent") {
            return LumaTheme.valueGreen
        }

        if normalizedLabel.contains("good") {
            return LumaTheme.outcomeTeal
        }

        if normalizedLabel.contains("fair") {
            return LumaTheme.sun
        }

        return LumaTheme.warningOrange
    }

    private func indexColor(_ index: Int) -> Color {
        [LumaTheme.coral, LumaTheme.aqua, LumaTheme.sun][index % 3]
    }

    private func syncCompareSelection() {
        appViewModel.trimComparedSchools(to: compareLimit)
        viewModel.sync(with: appViewModel.comparedSchools)
    }

    private func addNextSchoolToCompare() {
        guard let nextSchool = appViewModel.knownSchools.first(where: { !appViewModel.isCompared($0) }) else {
            return
        }

        let result = appViewModel.addToCompare(nextSchool, compareLimit: compareLimit)

        if result == .limitReached {
            isShowingPaywall = true
        }

        // TODO: Replace this first-available-school behavior with a searchable add-to-compare picker.
        syncCompareSelection()
    }
}
