import SwiftUI

struct CompareView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @EnvironmentObject private var proPurchaseManager: ProPurchaseManager
    @EnvironmentObject private var studentProfileStore: StudentProfileStore
    @StateObject private var viewModel = CompareViewModel()
    @State private var isShowingCompareLimitMessage = false
    @State private var isShowingPaywall = false

    private var compareLimit: Int {
        ProAccessPolicy.compareSchoolLimit(for: proPurchaseManager.state)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    if !proPurchaseManager.state.isPro {
                        FeatureLock(
                            title: "Unlock school comparison",
                            message: "Compare up to 3 schools side-by-side across value, net price, debt, and outcomes.",
                            feature: .fiveSchoolCompare,
                            action: { isShowingPaywall = true }
                        )
                    } else if viewModel.selectedSchools.isEmpty {
                        EmptyStateView(
                            title: "No schools selected",
                            message: "Use Explore to search live College Scorecard schools, then tap compare on the cards.",
                            systemImage: "rectangle.split.3x1"
                        )
                        .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
                    } else {
                        selectors
                        compareLimitMessage
                        comparisonSummary
                        primaryComparison
                        moreDetailsSection
                    }
                }
                .padding()
            }
            .background(LumaTheme.canvas)
            .onAppear {
                syncCompareSelection()
            }
            .onChange(of: proPurchaseManager.state) { _, newState in
                appViewModel.trimComparedSchools(to: compareLimit)
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
                Text("Compare up to 3 schools at a time")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(LumaTheme.slate)
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var selectors: some View {
        VStack(spacing: 12) {
            List {
                ForEach(viewModel.selectedSchools.indices, id: \.self) { index in
                    compareSelectorRow(for: index)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                removeComparedSchool(at: index)
                            } label: {
                                Label("Remove", systemImage: "trash")
                            }
                        }
                }
            }
            .listStyle(.plain)
            .scrollDisabled(true)
            .frame(height: CGFloat(viewModel.selectedSchools.count) * 74)
            .background(Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: LumaTheme.cardRadius))

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
            } else if viewModel.selectedSchools.count >= compareLimit {
                Button {
                    showCompareLimitMessage()
                } label: {
                    Label("Add School", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .foregroundStyle(LumaTheme.slate)
                        .frame(maxWidth: .infinity)
                        .padding(14)
                        .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
                        .overlay {
                            RoundedRectangle(cornerRadius: LumaTheme.cardRadius)
                                .stroke(LumaTheme.slate.opacity(0.16))
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add school")
                .accessibilityHint("Shows the active comparison limit.")
            }
        }
    }

    private func compareSelectorRow(for index: Int) -> some View {
        let school = viewModel.selectedSchools[index]

        return HStack(spacing: 10) {
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
                        Text(school.name)
                            .font(.headline)
                            .foregroundStyle(LumaTheme.ink)
                            .lineLimit(1)

                        Text("\(school.city), \(school.state)")
                            .font(.caption)
                            .foregroundStyle(LumaTheme.slate)
                    }

                    Spacer()

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(LumaTheme.slate)
                        .accessibilityHidden(true)
                }
                .contentShape(Rectangle())
            }
            .accessibilityLabel("Compared school \(index + 1)")
            .accessibilityValue(school.name)
            .accessibilityHint("Opens a menu to replace this compared school.")

            Button(role: .destructive) {
                removeComparedSchool(at: index)
            } label: {
                Image(systemName: "trash")
                    .font(.subheadline.weight(.heavy))
                    .foregroundStyle(LumaTheme.warningOrange)
                    .frame(width: 40, height: 40)
                    .background(LumaTheme.warningOrange.opacity(0.10), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove \(school.name) from compare")
        }
        .padding(.vertical, 8)
        .padding(.leading, 14)
        .padding(.trailing, 10)
        .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
    }

    @ViewBuilder
    private var compareLimitMessage: some View {
        if isShowingCompareLimitMessage {
            Label("Compare limit reached. You can compare up to 3 schools at a time.", systemImage: "info.circle.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(LumaTheme.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(LumaTheme.sun.opacity(0.16), in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
                .overlay {
                    RoundedRectangle(cornerRadius: LumaTheme.cardRadius)
                        .stroke(LumaTheme.sun.opacity(0.24))
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .accessibilityAddTraits(.isStaticText)
        }
    }

    private var moreDetailsSection: some View {
        DisclosureGroup {
            comparisonTable
                .padding(.top, 12)
        } label: {
            HStack {
                Text("More Details")
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(LumaTheme.ink)

                Spacer()

                Text("Acceptance, graduation, sticker cost")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(LumaTheme.slate)
                    .lineLimit(1)
            }
            .contentShape(Rectangle())
        }
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
    }

    private var comparisonTable: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                ForEach(viewModel.selectedSchools) { school in
                    Text(comparisonHeaderName(for: school))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .padding(8)
                        .background(LumaTheme.heroGradient, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
                        .accessibilityLabel(school.name)
                }
            }
            .padding(.bottom, 10)
            .accessibilityElement(children: .contain)

            ForEach(detailedMetrics) { metric in
                comparisonMetricRow(metric)

                if metric.id != detailedMetrics.last?.id {
                    Divider()
                }
            }
        }
    }

    private var primaryComparison: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Primary Comparison")
                .font(.headline)
                .foregroundStyle(LumaTheme.ink)

            VStack(spacing: 10) {
                ForEach(viewModel.selectedSchools) { school in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .center, spacing: 14) {
                            VStack(spacing: 0) {
                                Text("\(school.lumaScore)")
                                    .font(.system(size: 46, weight: .heavy))
                                    .foregroundStyle(lumaScoreColor(for: school.valueLabel))
                                    .lineLimit(1)

                                Text("LumaScore")
                                    .font(.caption.weight(.heavy))
                                    .foregroundStyle(LumaTheme.ink)
                            }
                            .frame(width: 104, height: 90)
                            .background(lumaScoreColor(for: school.valueLabel).opacity(0.12), in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
                            .overlay {
                                RoundedRectangle(cornerRadius: LumaTheme.cardRadius)
                                    .stroke(lumaScoreColor(for: school.valueLabel).opacity(0.22))
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(comparisonHeaderName(for: school))
                                    .font(.headline.weight(.heavy))
                                    .foregroundStyle(LumaTheme.ink)
                                    .lineLimit(1)

                                Text(school.valueLabel)
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(lumaScoreColor(for: school.valueLabel))
                                    .lineLimit(1)
                            }

                            Spacer()
                        }

                        HStack(spacing: 8) {
                            primaryMetric("Net", currencyShort(Int(school.costEstimate.averageNetPrice)), tint: LumaTheme.valueGreen)
                            primaryMetric("Earn", currencyShort(Int(school.medianEarnings)), tint: LumaTheme.outcomeTeal)
                            primaryMetric("Debt", currencyShort(Int(school.averageDebt)), tint: LumaTheme.sun)
                        }
                    }
                    .padding(14)
                    .background(LumaTheme.canvas, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
                }
            }
        }
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
        .accessibilityElement(children: .contain)
    }

    private var comparisonSummary: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let topSchool = highestLumaScoreSchool {
                HStack(alignment: .top, spacing: 14) {
                    VStack(spacing: 2) {
                        Text("\(topSchool.lumaScore)")
                            .font(.system(size: 34, weight: .heavy))
                            .foregroundStyle(lumaScoreColor(for: topSchool.valueLabel))
                            .lineLimit(1)

                        Text("Luma")
                            .font(.caption2.weight(.heavy))
                            .foregroundStyle(LumaTheme.slate)
                    }
                    .frame(width: 74, height: 74)
                    .background(lumaScoreColor(for: topSchool.valueLabel).opacity(0.12), in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))

                    VStack(alignment: .leading, spacing: 6) {
                        Text(studentProfileStore.profile.isComplete ? "Recommended for your profile" : "Recommended School")
                            .font(.caption.weight(.heavy))
                            .foregroundStyle(LumaTheme.coral)
                            .textCase(.uppercase)

                        Text(topSchool.name)
                            .font(.title3.weight(.heavy))
                            .foregroundStyle(LumaTheme.ink)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("\(comparisonHeaderName(for: topSchool)) is the strongest overall value in this comparison.")
                            .font(.caption)
                            .foregroundStyle(LumaTheme.slate)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Why")
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(LumaTheme.slate)

                    ForEach(recommendationReasons(for: topSchool), id: \.self) { reason in
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(LumaTheme.valueGreen)
                                .accessibilityHidden(true)

                            Text(reason)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(LumaTheme.ink)
                        }
                    }
                }
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                summaryPill("Better value", school: highestLumaScoreSchool, tint: LumaTheme.scorePurple)
                summaryPill("Lower net price", school: lowestNetPriceSchool, tint: LumaTheme.valueGreen)
                summaryPill("Lower debt", school: lowestDebtSchool, tint: LumaTheme.sun)
                summaryPill("Stronger outcomes", school: strongestOutcomesSchool, tint: LumaTheme.outcomeTeal)
            }
        }
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
        .accessibilityElement(children: .contain)
    }

    private var detailedMetrics: [ComparisonMetric] {
        viewModel.metrics.filter { metric in
            let title = metric.title.lowercased()
            return !title.contains("luma")
                && !title.contains("net")
                && !title.contains("earn")
                && !title.contains("debt")
        }
    }

    private var highestLumaScoreSchool: School? {
        viewModel.selectedSchools.max { $0.lumaScore < $1.lumaScore }
    }

    private var lowestNetPriceSchool: School? {
        viewModel.selectedSchools
            .filter { $0.costEstimate.averageNetPrice > 0 }
            .min { $0.costEstimate.averageNetPrice < $1.costEstimate.averageNetPrice }
    }

    private var lowestDebtSchool: School? {
        viewModel.selectedSchools
            .filter { $0.averageDebt > 0 }
            .min { $0.averageDebt < $1.averageDebt }
    }

    private var strongestOutcomesSchool: School? {
        viewModel.selectedSchools
            .filter { $0.medianEarnings > 0 }
            .max { $0.medianEarnings < $1.medianEarnings }
    }

    private func summaryPill(_ title: String, school: School?, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.heavy))
                .foregroundStyle(tint)
                .lineLimit(1)

            Text(school.map(comparisonHeaderName(for:)) ?? "Not enough data")
                .font(.caption.weight(.semibold))
                .foregroundStyle(LumaTheme.ink)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .frame(maxWidth: .infinity, minHeight: 62, alignment: .leading)
        .padding(10)
        .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
    }

    private func primaryMetric(_ title: String, _ value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value)
                .font(.subheadline.weight(.heavy))
                .foregroundStyle(tint)
                .lineLimit(1)

            Text(title)
                .font(.caption2.weight(.bold))
                .foregroundStyle(LumaTheme.slate)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
        .padding(.horizontal, 10)
        .background(.white.opacity(0.88), in: RoundedRectangle(cornerRadius: 12))
    }

    private func currencyShort(_ value: Int) -> String {
        guard value > 0 else { return "N/A" }
        return "$\(max(1, value / 1_000))K"
    }

    private func recommendationReasons(for school: School) -> [String] {
        var reasons: [String] = ["Better value"]

        if lowestDebtSchool?.id == school.id {
            reasons.append("Lower debt")
        }

        if lowestNetPriceSchool?.id == school.id {
            reasons.append("Lower net price")
        }

        if strongestOutcomesSchool?.id == school.id {
            reasons.append("Stronger earnings outcomes")
        }

        if school.graduationRate >= 0.65 {
            reasons.append("Solid completion outcomes")
        }

        return Array(reasons.prefix(4))
    }

    private func comparisonMetricRow(_ metric: ComparisonMetric) -> some View {
        HStack(alignment: .center, spacing: 10) {
            Text(metric.title)
                .font(.caption.weight(.heavy))
                .foregroundStyle(LumaTheme.slate)
                .frame(width: 88, alignment: .leading)
                .lineLimit(2)
                .truncationMode(.tail)

            ForEach(Array(metric.values.enumerated()), id: \.offset) { _, value in
                Text(value)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(LumaTheme.ink)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .minimumScaleFactor(0.72)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
    }

    private func comparisonHeaderName(for school: School) -> String {
        let name = school.name
        let normalizedName = name.lowercased()

        if normalizedName.contains("southern new hampshire university") {
            return "SNHU"
        }

        if normalizedName.contains("western governors university") {
            return "WGU"
        }

        if normalizedName.contains("grand canyon university") {
            return "GCU"
        }

        if normalizedName.contains("university of phoenix") {
            return "U. Phoenix"
        }

        if normalizedName.hasPrefix("university of ") {
            let remainder = String(name.dropFirst("University of ".count))
            return "U. \(remainder.replacingOccurrences(of: "-Main Campus", with: ""))"
        }

        return name
            .replacingOccurrences(of: " University", with: "")
            .replacingOccurrences(of: " College", with: "")
            .replacingOccurrences(of: "-Main Campus", with: "")
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
        guard viewModel.selectedSchools.count < compareLimit else {
            showCompareLimitMessage()
            return
        }

        guard let nextSchool = appViewModel.knownSchools.first(where: { !appViewModel.isCompared($0) }) else {
            return
        }

        let result = appViewModel.addToCompare(nextSchool, compareLimit: compareLimit)

        if result == .limitReached {
            showCompareLimitMessage()
        }

        // TODO: Replace this first-available-school behavior with a searchable add-to-compare picker.
        syncCompareSelection()
    }

    private func removeComparedSchool(at index: Int) {
        guard viewModel.selectedSchools.indices.contains(index) else { return }
        _ = appViewModel.removeFromCompare(viewModel.selectedSchools[index])
        syncCompareSelection()
    }

    private func showCompareLimitMessage() {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.9)) {
            isShowingCompareLimitMessage = true
        }

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(3))
            withAnimation(.easeOut(duration: 0.2)) {
                isShowingCompareLimitMessage = false
            }
        }
    }
}
