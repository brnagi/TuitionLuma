import SwiftUI

struct SchoolDetailView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @EnvironmentObject private var proPurchaseManager: ProPurchaseManager
    @EnvironmentObject private var studentProfileStore: StudentProfileStore
    @StateObject private var viewModel: SchoolDetailViewModel
    @State private var isShowingPaywall = false

    init(school: School) {
        _viewModel = StateObject(wrappedValue: SchoolDetailViewModel(school: school))
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 18) {
                    hero
                    decisionSnapshot
                    dataQualitySection
                    CostBreakdownCard(cost: school.costEstimate)
                    proPlanningSection
                    programSection
                    outcomesSection
                }
                .padding()
                .frame(width: proxy.size.width, alignment: .leading)
                .clipped()
            }
            .background(LumaTheme.canvas)
        }
        .navigationTitle(school.name)
        .task {
            await viewModel.load()
            appViewModel.remember([viewModel.school])
            applySavedProgramChoice()
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    saveTapped()
                } label: {
                    Image(systemName: appViewModel.isSaved(school) ? "bookmark.fill" : "bookmark")
                        .foregroundStyle(appViewModel.isSaved(school) ? LumaTheme.coral : LumaTheme.ink)
                }
                .accessibilityLabel(appViewModel.isSaved(school) ? "Remove saved school" : "Save school")
                .accessibilityHint(appViewModel.isSaved(school) ? "Removes this school from Saved." : "Adds this school to Saved.")
            }
        }
        .sheet(isPresented: $isShowingPaywall) {
            PaywallView()
                .environmentObject(proPurchaseManager)
        }
    }

    private var school: School {
        viewModel.school
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
                .foregroundStyle(.white.opacity(0.94))
                .shadow(color: .black.opacity(0.24), radius: 4, y: 2)

            HStack(spacing: 10) {
                heroMetricChip(
                    title: "Avg net price",
                    value: school.costEstimate.averageNetPrice > 0 ? school.costEstimate.averageNetPrice.formatted(LumaFormat.currency) : "N/A",
                    systemImage: "dollarsign.circle.fill",
                    tint: LumaTheme.valueGreen
                )

                heroMetricChip(
                    title: "Median earnings",
                    value: school.medianEarnings > 0 ? school.medianEarnings.formatted(LumaFormat.currency) : "N/A",
                    systemImage: "chart.line.uptrend.xyaxis.circle.fill",
                    tint: LumaTheme.outcomeTeal
                )
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            ZStack {
                LinearGradient(
                    colors: [
                        LumaTheme.color(hex: school.primaryColor, fallback: LumaTheme.coral),
                        LumaTheme.color(hex: school.secondaryColor, fallback: LumaTheme.aqua)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                LinearGradient(
                    colors: [
                        .black.opacity(0.42),
                        .black.opacity(0.18),
                        .black.opacity(0.34)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                RadialGradient(
                    colors: [.white.opacity(0.18), .clear],
                    center: .topLeading,
                    startRadius: 20,
                    endRadius: 260
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
        }
        .overlay {
            RoundedRectangle(cornerRadius: LumaTheme.cardRadius)
                .stroke(.white.opacity(0.16))
        }
        .shadow(color: LumaTheme.cardShadow.opacity(0.60), radius: 16, y: 8)
    }

    private func heroMetricChip(title: String, value: String, systemImage: String, tint: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(tint)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text(title)
                    .font(.caption2.weight(.heavy))
                    .foregroundStyle(.white.opacity(0.78))
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.black.opacity(0.22), in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
        .overlay {
            RoundedRectangle(cornerRadius: LumaTheme.cardRadius)
                .stroke(tint.opacity(0.42))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(value)
    }

    private var decisionSnapshot: some View {
        VStack(alignment: .leading, spacing: 14) {
            LumaScoreCard(school: school)
            annualCostSummary

            VStack(alignment: .leading, spacing: 10) {
                Text("Key outcomes")
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(LumaTheme.slate)
                    .textCase(.uppercase)

                quickStats
            }
        }
        .padding(10)
        .background(LumaTheme.card, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
        .overlay {
            RoundedRectangle(cornerRadius: LumaTheme.cardRadius)
                .stroke(LumaTheme.cardStroke)
        }
        .shadow(color: LumaTheme.cardShadow.opacity(0.72), radius: 18, y: 10)
    }

    private var annualCostSummary: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Estimated Annual Cost")
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(.white.opacity(0.86))
                    .textCase(.uppercase)

                Text(moneyText(school.costEstimate.estimatedAnnualCost))
                    .font(.system(size: 34, weight: .heavy))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.70)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("Avg aid")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.78))

                Text(moneyText(school.costEstimate.averageGrantAid))
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.74)
            }
        }
        .padding(16)
        .background(LumaTheme.heroGradient, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
        .overlay {
            RoundedRectangle(cornerRadius: LumaTheme.cardRadius)
                .stroke(.white.opacity(0.18))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Estimated annual cost")
        .accessibilityValue("\(moneyText(school.costEstimate.estimatedAnnualCost)). Average aid \(moneyText(school.costEstimate.averageGrantAid)).")
    }

    private var quickStats: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            StatPill(title: "Net price", value: LumaFormat.compactCurrency(school.costEstimate.averageNetPrice), systemImage: "dollarsign", tint: LumaTheme.valueGreen)
            StatPill(title: "Earnings", value: LumaFormat.compactCurrency(school.medianEarnings), systemImage: "chart.line.uptrend.xyaxis", tint: LumaTheme.outcomeTeal)
            StatPill(title: "Grad rate", value: school.graduationRate.formatted(LumaFormat.percent), systemImage: "graduationcap.fill", tint: LumaTheme.coral)
            StatPill(title: "Avg debt", value: LumaFormat.compactCurrency(school.averageDebt), systemImage: "creditcard.fill", tint: LumaTheme.sun)
        }
    }

    private var programSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Top Programs")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(LumaTheme.ink)

                Spacer()

                if viewModel.isLoadingPrograms {
                    ProgressView()
                        .tint(LumaTheme.coral)
                }
            }

            if viewModel.programs.isEmpty {
                EmptyStateView(
                    title: "Program outcomes unavailable",
                    message: "No program-specific salary data is available for this school.",
                    systemImage: "list.bullet.clipboard"
                )
                .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
            } else if viewModel.topPrograms.isEmpty {
                EmptyStateView(
                    title: "Program salary data unavailable",
                    message: "No program-specific salary data is available for these programs.",
                    systemImage: "chart.line.uptrend.xyaxis"
                )
                .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))

                viewAllProgramsLink
            } else {
                ForEach(viewModel.topPrograms) { program in
                    NavigationLink {
                        ProgramDetailView(school: school, program: program)
                    } label: {
                        ProgramListRow(
                            program: program,
                            school: school,
                            isSavedChoice: appViewModel.isPreferredProgram(program, for: school)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Opens program details.")
                    .simultaneousGesture(TapGesture().onEnded {
                        viewModel.selectedProgram = program
                    })
                }

                if viewModel.programs.count > viewModel.topPrograms.count {
                    viewAllProgramsLink
                }

            }
        }
    }

    private var viewAllProgramsLink: some View {
        NavigationLink {
            ProgramExplorerView(school: school, programs: viewModel.rankedPrograms)
        } label: {
            HStack {
                Label("View All Programs", systemImage: "list.bullet")
                    .font(.headline)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .accessibilityHidden(true)
            }
            .foregroundStyle(LumaTheme.coral)
            .padding(14)
            .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("View all programs")
        .accessibilityValue("\(viewModel.programs.count) programs available")
    }

    @ViewBuilder
    private var dataQualitySection: some View {
        if viewModel.isLoadingDetails {
            LoadingStateView(title: "Refreshing live College Scorecard data...")
                .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
        } else if let errorMessage = viewModel.errorMessage {
            ErrorStateView(message: errorMessage) {
                Task { await viewModel.load() }
            }
            .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
        } else if !unresolvedMissingDataFields.isEmpty || school.costEstimate.hasEstimatedComponents {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(LumaTheme.outcomeTeal)
                    .font(.caption)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(dataQualityTitle)
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(LumaTheme.slate)
                        .textCase(.uppercase)

                    Text(dataQualityMessage)
                        .font(.caption)
                        .foregroundStyle(LumaTheme.slate)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(LumaTheme.outcomeTeal.opacity(0.08), in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
            .overlay {
                RoundedRectangle(cornerRadius: LumaTheme.cardRadius)
                    .stroke(LumaTheme.outcomeTeal.opacity(0.14))
            }
        }
    }

    private var unresolvedMissingDataFields: [String] {
        let estimatedCostFields = Set(["Out-of-state tuition", "Books and supplies", "Housing and meals", "Other living expenses"])
        return school.missingDataFields.filter { !estimatedCostFields.contains($0) }
    }

    private var dataQualityTitle: String {
        if unresolvedMissingDataFields.isEmpty {
            return "Some costs are estimated"
        }

        return "Some federal fields are unavailable"
    }

    private var dataQualityMessage: String {
        var messages: [String] = []

        if school.costEstimate.hasEstimatedComponents {
            messages.append("Missing cost line items are filled with reported Scorecard totals and TuitionLuma planning assumptions.")
        }

        if !unresolvedMissingDataFields.isEmpty {
            messages.append("Unavailable: \(unresolvedMissingDataFields.prefix(4).joined(separator: ", ")).")
        }

        return messages.joined(separator: " ")
    }

    private var proPlanningSection: some View {
        VStack(spacing: 12) {
            if ProAccessPolicy.canUse(.scenarioModeling, state: proPurchaseManager.state) {
                HStack {
                    Label("ROI score", systemImage: "chart.line.uptrend.xyaxis")
                        .font(.headline)
                        .foregroundStyle(LumaTheme.ink)

                    Spacer()

                    Text("\(roiOutcome.grade) • \(roiScore)")
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
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Planning scenarios")
            } else {
                FeatureLock(
                    title: "Unlock deeper planning",
                    message: "Model scenarios and unlock deeper planning tools for this school.",
                    feature: .scenarioModeling,
                    action: { isShowingPaywall = true }
                )
            }
        }
    }

    private var outcomesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Outcome snapshot")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(LumaTheme.ink)

                Text("A quick read on selectivity, completion, and campus size.")
                    .font(.subheadline)
                    .foregroundStyle(LumaTheme.slate)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                outcomeTile(
                    title: "Students",
                    value: LumaFormat.number(school.studentCount),
                    systemImage: "person.3.fill",
                    tint: LumaTheme.scorePurple
                )

                outcomeTile(
                    title: "Acceptance",
                    value: school.admissionRate?.formatted(LumaFormat.percent) ?? "N/A",
                    systemImage: "checkmark.seal.fill",
                    tint: LumaTheme.outcomeTeal
                )

                outcomeTile(
                    title: "Graduation",
                    value: school.graduationRate.formatted(LumaFormat.percent),
                    systemImage: "graduationcap.fill",
                    tint: LumaTheme.valueGreen
                )
                .gridCellColumns(2)
            }
        }
        .padding(16)
        .background(LumaTheme.card, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
        .overlay {
            RoundedRectangle(cornerRadius: LumaTheme.cardRadius)
                .stroke(LumaTheme.cardStroke)
        }
        .shadow(color: LumaTheme.cardShadow.opacity(0.55), radius: 12, y: 6)
    }

    private var roiScore: String {
        "\(roiOutcome.score)/100"
    }

    private var roiOutcome: ROIOutcomeResult {
        if studentProfileStore.profile.isComplete {
            return StudentProfileRecommendationEngine.personalizedROIOutcome(
                for: school,
                profile: studentProfileStore.profile
            )
        }

        return ROIOutcomeCalculator.result(for: school, program: viewModel.selectedProgram)
    }

    private func moneyText(_ value: Double) -> String {
        guard value > 0 else {
            return "Not reported"
        }

        return value.formatted(LumaFormat.currency)
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

    private func outcomeTile(title: String, value: String, systemImage: String, tint: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.headline.weight(.bold))
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(tint.opacity(0.14), in: Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(LumaTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Text(title)
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(LumaTheme.slate)
                    .textCase(.uppercase)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 76, alignment: .leading)
        .background(tint.opacity(0.08), in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
        .overlay {
            RoundedRectangle(cornerRadius: LumaTheme.cardRadius)
                .stroke(tint.opacity(0.14))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(value)
    }

    private func saveTapped() {
        let limit = ProAccessPolicy.savedSchoolLimit(for: proPurchaseManager.state)
        let result = appViewModel.toggleSaved(school, savedLimit: limit)

        if result == .limitReached {
            isShowingPaywall = true
        }
    }

    private func applySavedProgramChoice() {
        if let preferredProgram = appViewModel.preferredProgram(for: school, in: viewModel.programs) {
            viewModel.selectedProgram = preferredProgram
        } else if let profileProgram = StudentProfileRecommendationEngine.matchingProgram(
            in: viewModel.programs,
            for: school,
            profile: studentProfileStore.profile
        ) {
            viewModel.selectedProgram = profileProgram
        }
    }

}

@MainActor
final class SchoolDetailViewModel: ObservableObject {
    @Published var school: School
    @Published var programs: [AcademicProgram] = []
    @Published var selectedProgram: AcademicProgram?
    @Published var isLoadingDetails = false
    @Published var isLoadingPrograms = false
    @Published var errorMessage: String?

    private let provider: SchoolDataProviding

    var rankedPrograms: [AcademicProgram] {
        programs.sorted { lhs, rhs in
            let lhsHasEarnings = lhs.medianEarnings > 0
            let rhsHasEarnings = rhs.medianEarnings > 0

            if lhsHasEarnings != rhsHasEarnings {
                return lhsHasEarnings
            }

            let lhsROI = ROIOutcomeCalculator.result(for: school, program: lhs).score
            let rhsROI = ROIOutcomeCalculator.result(for: school, program: rhs).score

            if lhsROI != rhsROI {
                return lhsROI > rhsROI
            }

            if lhs.medianEarnings != rhs.medianEarnings {
                return lhs.medianEarnings > rhs.medianEarnings
            }

            return (lhs.completionCount ?? 0) > (rhs.completionCount ?? 0)
        }
    }

    var topPrograms: [AcademicProgram] {
        Array(
            rankedPrograms
                .filter { $0.medianEarnings > 0 }
                .prefix(5)
        )
    }

    init(school: School, provider: SchoolDataProviding = CollegeScorecardService()) {
        self.school = school
        self.programs = school.programs
        self.provider = provider
        self.selectedProgram = topPrograms.first
    }

    func load() async {
        guard let scorecardID = school.scorecardID else {
            return
        }

        await loadDetails(scorecardID: scorecardID)
        await loadPrograms(scorecardID: scorecardID)
    }

    private func loadDetails(scorecardID: Int) async {
        isLoadingDetails = true
        errorMessage = nil
        defer { isLoadingDetails = false }

        do {
            school = try await provider.fetchSchoolDetails(schoolId: scorecardID)
        } catch CollegeScorecardError.missingAPIKey {
            errorMessage = "Set COLLEGE_SCORECARD_API_KEY to refresh live school details."
        } catch let error as CollegeScorecardError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "TuitionLuma could not refresh live school details. Check your connection and try again."
        }
    }

    private func loadPrograms(scorecardID: Int) async {
        isLoadingPrograms = true
        defer { isLoadingPrograms = false }

        do {
            programs = try await provider.fetchProgramsForSchool(schoolId: scorecardID)
            school.programs = programs
            selectedProgram = topPrograms.first
        } catch {
            programs = school.programs
            selectedProgram = topPrograms.first
        }
    }
}
