import SwiftUI

struct SavedSchoolsView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @EnvironmentObject private var proPurchaseManager: ProPurchaseManager
    @EnvironmentObject private var studentProfileStore: StudentProfileStore
    @State private var isShowingPaywall = false
    @State private var compareLimitMessage: String?
    @State private var programExplorerSchool: School?

    var body: some View {
        NavigationStack {
            ZStack {
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

                if let compareLimitMessage {
                    limitBanner(compareLimitMessage)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .frame(maxHeight: .infinity, alignment: .top)
                }
            }
            .sheet(isPresented: $isShowingPaywall) {
                PaywallView()
                    .environmentObject(proPurchaseManager)
            }
            .navigationDestination(item: $programExplorerSchool) { school in
                ProgramExplorerView(school: school, programs: school.programs)
            }
        }
    }

    private func savedSchoolLink(_ school: School) -> some View {
        NavigationLink {
            SchoolDetailView(school: school)
        } label: {
            SavedSchoolShortlistCard(
                school: school,
                savedSchools: appViewModel.savedSchools,
                programChoice: appViewModel.preferredProgramChoice(for: school),
                profile: studentProfileStore.profile,
                isCompared: appViewModel.isCompared(school),
                onRemoveTapped: { _ = appViewModel.toggleSaved(school) },
                onCompareTapped: { compareTapped(school) },
                onSelectProgramTapped: { programExplorerSchool = school }
            )
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens school details.")
    }

    @ViewBuilder
    private var savedLimitPrompt: some View {
        if ProAccessPolicy.canUse(.unlimitedSavedSchools, state: proPurchaseManager.state) {
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
        EmptyStateCard(
            title: "Build your college shortlist",
            message: "Save schools you want to revisit, then compare cost, aid, debt, and outcomes side by side.",
            systemImage: "bookmark"
        ) {
            Button {
                selectExploreTab()
            } label: {
                EmptyStateActionLabel(title: "Explore Schools", systemImage: "magnifyingglass")
            }
            .buttonStyle(.plain)
            .accessibilityHint("Switches to Explore to search for schools.")
        }
    }

    private func compareTapped(_ school: School) {
        guard ProAccessPolicy.canUse(.schoolCompare, state: proPurchaseManager.state) else {
            isShowingPaywall = true
            return
        }

        if appViewModel.isCompared(school) {
            _ = appViewModel.removeFromCompare(school)
            return
        }

        let limit = ProAccessPolicy.compareSchoolLimit(for: proPurchaseManager.state)
        let result = appViewModel.addToCompare(school, compareLimit: limit)

        if result == .limitReached {
            showCompareLimitMessage()
        }

        // TODO: Route directly to Compare after adding once global tab selection is introduced.
    }

    private func showCompareLimitMessage() {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.9)) {
            compareLimitMessage = "Compare limit reached. You can compare up to 3 schools at a time."
        }

        Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.2)) {
                    compareLimitMessage = nil
                }
            }
        }
    }

    private func limitBanner(_ message: String) -> some View {
        Label(message, systemImage: "info.circle.fill")
            .font(.subheadline.weight(.heavy))
            .foregroundStyle(LumaTheme.ink)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
            .overlay {
                RoundedRectangle(cornerRadius: LumaTheme.cardRadius)
                    .stroke(LumaTheme.coral.opacity(0.22))
            }
            .shadow(color: LumaTheme.cardShadow, radius: 14, y: 8)
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
    var savedSchools: [School]
    var programChoice: SavedProgramChoice?
    var profile: StudentProfile
    var isCompared: Bool
    var onRemoveTapped: () -> Void
    var onCompareTapped: () -> Void
    var onSelectProgramTapped: () -> Void

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
                        .background(scoreTint.opacity(0.15), in: Capsule())
                        .overlay {
                            Capsule()
                                .stroke(scoreTint.opacity(0.22))
                        }
                }
            }

            metricRow
            shortlistInsightRow
            programPlanSection

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

            Text("LumaScore")
                .font(.caption2.weight(.heavy))
                .foregroundStyle(LumaTheme.slate)
        }
        .frame(width: 76, height: 76)
        .background(scoreTint.opacity(0.16), in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
        .overlay {
            RoundedRectangle(cornerRadius: LumaTheme.cardRadius)
                .stroke(scoreTint.opacity(0.24))
        }
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
        .background(LumaTheme.canvas.opacity(0.85), in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
        .overlay {
            RoundedRectangle(cornerRadius: LumaTheme.cardRadius)
                .stroke(LumaTheme.cardStroke.opacity(0.55))
        }
    }

    private var shortlistInsightRow: some View {
        HStack(spacing: 8) {
            shortlistInsight(
                title: "Value",
                value: isStrongestValue ? "Strongest" : school.valueLabel,
                systemImage: "sparkles",
                tint: scoreTint
            )

            shortlistInsight(
                title: "Debt",
                value: isLowestDebt ? "Lowest" : debtSummary,
                systemImage: "creditcard.fill",
                tint: LumaTheme.sun
            )

            shortlistInsight(
                title: "Earnings",
                value: isHighestEarnings ? "Highest" : earningsSummary,
                systemImage: "chart.line.uptrend.xyaxis",
                tint: LumaTheme.outcomeTeal
            )
        }
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private var programPlanSection: some View {
        Button(action: onSelectProgramTapped) {
            VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: displayedProgramChoice == nil ? "book.closed" : "checkmark.seal.fill")
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(displayedProgramChoice == nil ? LumaTheme.slate : LumaTheme.coral)
                    .frame(width: 28, height: 28)
                    .background((displayedProgramChoice == nil ? LumaTheme.slate : LumaTheme.coral).opacity(0.12), in: Circle())
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(displayedProgramChoice == nil ? "Choose a program for planning" : "Program of study")
                        .font(.subheadline.weight(.heavy))
                        .foregroundStyle(LumaTheme.ink)

                    Text(displayedProgramChoice?.name ?? "Save a program from school details or Calculator to compare program-specific cost and outcomes.")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(displayedProgramChoice == nil ? LumaTheme.slate : LumaTheme.ink)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)

                    if let displayedProgramChoice {
                        Text(displayedProgramChoice.credential)
                            .font(.caption2.weight(.heavy))
                            .foregroundStyle(LumaTheme.outcomeTeal)
                            .padding(.vertical, 5)
                            .padding(.horizontal, 8)
                            .background(LumaTheme.aqua.opacity(0.12), in: Capsule())
                    }
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(LumaTheme.slate)
                    .accessibilityHidden(true)
            }

            if let displayedProgramChoice {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    programMetric(
                        title: displayedProgramChoice.medianEarnings ?? 0 > 0 ? "Program earnings" : "School earnings",
                        value: earningsValue(for: displayedProgramChoice),
                        tint: LumaTheme.outcomeTeal
                    )

                    programMetric(
                        title: "ROI grade",
                        value: roiResult(for: displayedProgramChoice).grade,
                        tint: LumaTheme.scorePurple
                    )

                    programMetric(
                        title: "Program debt",
                        value: debtValue(for: displayedProgramChoice),
                        tint: LumaTheme.sun
                    )

                    programMetric(
                        title: "Cost vs saved",
                        value: shortlistCostComparison,
                        tint: LumaTheme.valueGreen
                    )
                }
            }
        }
            .padding(13)
            .background(LumaTheme.canvas.opacity(0.74), in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
            .overlay {
                RoundedRectangle(cornerRadius: LumaTheme.cardRadius)
                    .stroke((displayedProgramChoice == nil ? LumaTheme.cardStroke : LumaTheme.coral.opacity(0.20)), lineWidth: displayedProgramChoice == nil ? 1 : 1.4)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(displayedProgramChoice == nil ? "Select course" : "Change course")
        .accessibilityHint("Opens this school's program list.")
    }

    private var displayedProgramChoice: SavedProgramChoice? {
        if let programChoice {
            return programChoice
        }

        guard let matchedProgram = StudentProfileRecommendationEngine.matchingProgram(
            in: school.programs,
            for: school,
            profile: profile
        ) else {
            return nil
        }

        return SavedProgramChoice(
            name: matchedProgram.name,
            credential: matchedProgram.credential,
            cipCode: matchedProgram.cipCode,
            medianEarnings: matchedProgram.medianEarnings,
            debt: matchedProgram.debt,
            category: matchedProgram.category,
            typicalDurationYears: matchedProgram.typicalDurationYears
        )
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

    private var isStrongestValue: Bool {
        guard let best = savedSchools.max(by: { $0.lumaScore < $1.lumaScore }) else {
            return false
        }

        return best.id == school.id
    }

    private var isLowestDebt: Bool {
        guard school.averageDebt > 0,
              let lowest = savedSchools
                .filter({ $0.averageDebt > 0 })
                .min(by: { $0.averageDebt < $1.averageDebt }) else {
            return false
        }

        return lowest.id == school.id
    }

    private var isHighestEarnings: Bool {
        guard school.medianEarnings > 0,
              let highest = savedSchools
                .filter({ $0.medianEarnings > 0 })
                .max(by: { $0.medianEarnings < $1.medianEarnings }) else {
            return false
        }

        return highest.id == school.id
    }

    private var debtSummary: String {
        school.averageDebt > 0 ? LumaFormat.compactCurrency(school.averageDebt) : "N/A"
    }

    private var earningsSummary: String {
        school.medianEarnings > 0 ? LumaFormat.compactCurrency(school.medianEarnings) : "N/A"
    }

    private func programMetric(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.subheadline.weight(.heavy))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.82)

            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(LumaTheme.slate)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
        .padding(.horizontal, 10)
        .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(value)
    }

    private func shortlistInsight(title: String, value: String, systemImage: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: systemImage)
                .font(.caption2.weight(.heavy))
                .foregroundStyle(LumaTheme.slate)
                .labelStyle(.titleAndIcon)

            Text(value)
                .font(.caption.weight(.heavy))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
        .padding(.horizontal, 10)
        .background(tint.opacity(0.08), in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
        .overlay {
            RoundedRectangle(cornerRadius: LumaTheme.cardRadius)
                .stroke(tint.opacity(0.14))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(value)
    }

    private func earningsValue(for choice: SavedProgramChoice) -> String {
        let earnings = choice.medianEarnings ?? school.medianEarnings
        return earnings > 0 ? LumaFormat.compactCurrency(earnings) : "N/A"
    }

    private func debtValue(for choice: SavedProgramChoice) -> String {
        let debt = choice.debt ?? school.averageDebt
        return debt > 0 ? LumaFormat.compactCurrency(debt) : "N/A"
    }

    private func roiResult(for choice: SavedProgramChoice) -> ROIOutcomeResult {
        ROIOutcomeCalculator.result(
            for: school,
            program: AcademicProgram(
                name: choice.name,
                credential: choice.credential,
                cipCode: choice.cipCode,
                medianEarnings: choice.medianEarnings ?? 0,
                debt: choice.debt,
                typicalDurationYears: choice.typicalDurationYears ?? 4,
                category: choice.category
            )
        )
    }

    private var shortlistCostComparison: String {
        let costs = savedSchools
            .map(\.costEstimate.averageNetPrice)
            .filter { $0 > 0 }

        guard !costs.isEmpty, school.costEstimate.averageNetPrice > 0 else {
            return "N/A"
        }

        let average = costs.reduce(0, +) / Double(costs.count)
        let difference = school.costEstimate.averageNetPrice - average

        if abs(difference) < 500 {
            return "Near avg"
        }

        return difference < 0
            ? "\(LumaFormat.compactCurrency(abs(difference))) lower"
            : "\(LumaFormat.compactCurrency(difference)) higher"
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
