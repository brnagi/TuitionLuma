import SwiftUI

struct CompareView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @EnvironmentObject private var subscriptionManager: MockSubscriptionManager
    @StateObject private var viewModel = CompareViewModel()
    @State private var isShowingPaywall = false

    private var compareLimit: Int {
        SubscriptionPolicy.compareSchoolLimit(for: subscriptionManager.state)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    selectors
                    compareLimitPrompt
                    comparisonTable
                }
                .padding()
            }
            .background(LumaTheme.canvas)
            .onAppear {
                syncCompareSelection()
            }
            .onChange(of: subscriptionManager.state) { _, newState in
                appViewModel.trimComparedSchools(to: SubscriptionPolicy.compareSchoolLimit(for: newState))
                syncCompareSelection()
            }
            .onChange(of: appViewModel.comparedSchoolIDs) { _, _ in
                syncCompareSelection()
            }
            .sheet(isPresented: $isShowingPaywall) {
                PaywallView()
                    .environmentObject(subscriptionManager)
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
                Text(subscriptionManager.state.isPro ? "Pro compare: up to 5 schools" : "Free compare: up to 2 schools")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(subscriptionManager.state.isPro ? LumaTheme.coral : LumaTheme.slate)

                if subscriptionManager.state.isPro {
                    ProBadge(compact: true)
                }
            }
        }
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
                        ForEach(viewModel.allSchools) { school in
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
                    }
                    .padding(14)
                    .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
                }
            }

            if viewModel.selectedSchools.count < compareLimit {
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
            }
        }
    }

    @ViewBuilder
    private var compareLimitPrompt: some View {
        if subscriptionManager.state.isPro {
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

            ForEach(viewModel.metrics) { metric in
                ComparisonRow(title: metric.title, values: metric.values)

                if metric.id != viewModel.metrics.last?.id {
                    Divider()
                }
            }
        }
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
    }

    private func indexColor(_ index: Int) -> Color {
        [LumaTheme.coral, LumaTheme.aqua, LumaTheme.sun][index % 3]
    }

    private func syncCompareSelection() {
        appViewModel.trimComparedSchools(to: compareLimit)
        viewModel.sync(with: appViewModel.comparedSchools)
    }

    private func addNextSchoolToCompare() {
        let nextSchool = viewModel.allSchools.first { !appViewModel.isCompared($0) } ?? viewModel.allSchools[0]
        let result = appViewModel.addToCompare(nextSchool, compareLimit: compareLimit)

        if result == .limitReached {
            isShowingPaywall = true
        }

        // TODO: Replace this first-available-school behavior with a searchable add-to-compare picker.
        syncCompareSelection()
    }
}
