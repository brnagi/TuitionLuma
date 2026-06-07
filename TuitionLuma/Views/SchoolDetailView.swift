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
                    LumaScoreCard(school: school)
                    quickStats
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
        .background(
            LinearGradient(
                colors: [
                    LumaTheme.color(hex: school.primaryColor, fallback: LumaTheme.coral),
                    LumaTheme.color(hex: school.secondaryColor, fallback: LumaTheme.aqua)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius)
        )
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
                        ProgramListRow(program: program, school: school)
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
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(dataQualityTitle)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(LumaTheme.ink)

                    Text(dataQualityMessage)
                        .font(.caption)
                        .foregroundStyle(LumaTheme.slate)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(14)
            .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
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
            if proPurchaseManager.state.isPro {
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
            ComparisonRow(title: "Acceptance rate", values: [school.admissionRate?.formatted(LumaFormat.percent) ?? "N/A"])
            ComparisonRow(title: "Graduation rate", values: [school.graduationRate.formatted(LumaFormat.percent)])
        }
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
    }

    private var roiScore: String {
        "\(roiOutcome.score)/100"
    }

    private var roiOutcome: ROIOutcomeResult {
        if proPurchaseManager.state.isPro, studentProfileStore.profile.isComplete {
            return StudentProfileRecommendationEngine.personalizedROIOutcome(
                for: school,
                profile: studentProfileStore.profile
            )
        }

        return ROIOutcomeCalculator.result(for: school, program: viewModel.selectedProgram)
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
        let limit = ProAccessPolicy.savedSchoolLimit(for: proPurchaseManager.state)
        let result = appViewModel.toggleSaved(school, savedLimit: limit)

        if result == .limitReached {
            isShowingPaywall = true
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
            selectedProgram = topPrograms.first
        } catch {
            programs = school.programs
            selectedProgram = topPrograms.first
        }
    }
}
