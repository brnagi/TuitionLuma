import SwiftUI

struct SchoolDetailView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @EnvironmentObject private var proPurchaseManager: MockProPurchaseManager
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
                Text("Programs to compare")
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
                    title: "Program data unavailable",
                    message: "College Scorecard does not publish field-of-study outcomes for every school or program.",
                    systemImage: "list.bullet.clipboard"
                )
                .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
            } else {
                ForEach(viewModel.programs.prefix(proPurchaseManager.state.isPro ? 12 : 3)) { program in
                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(program.name)
                                .font(.headline)
                                .foregroundStyle(LumaTheme.ink)
                                .lineLimit(3)
                                .fixedSize(horizontal: false, vertical: true)

                            Text(programSubtitle(program))
                                .font(.caption)
                                .foregroundStyle(LumaTheme.slate)
                                .lineLimit(3)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(alignment: .trailing, spacing: 4) {
                            Text(program.medianEarnings > 0 ? program.medianEarnings.formatted(LumaFormat.currency) : "N/A")
                                .font(.headline.weight(.heavy))
                                .foregroundStyle(LumaTheme.ink)
                                .lineLimit(1)
                                .minimumScaleFactor(0.76)

                            Text("median pay")
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(LumaTheme.slate)
                        }
                        .frame(width: 86, alignment: .trailing)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
                    .clipped()
                }

                if !proPurchaseManager.state.isPro && viewModel.programs.count > 3 {
                    FeatureLock(
                        title: "Unlock program ROI",
                        message: "Compare more program outcomes, payback period, and advanced ROI with Pro.",
                        feature: .roiScore,
                        action: { isShowingPaywall = true }
                    )
                }
            }
        }
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
            ComparisonRow(title: "Acceptance rate", values: [school.admissionRate?.formatted(LumaFormat.percent) ?? "N/A"])
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
        let limit = ProAccessPolicy.savedSchoolLimit(for: proPurchaseManager.state)
        let result = appViewModel.toggleSaved(school, savedLimit: limit)

        if result == .limitReached {
            isShowingPaywall = true
        }
    }

    private func programSubtitle(_ program: Program) -> String {
        [
            program.credential,
            program.cipCode.map { "CIP \($0)" },
            program.debt.map { "Debt \($0.formatted(LumaFormat.currency))" },
            program.completionCount.map { "\($0) completions" }
        ]
        .compactMap { $0 }
        .joined(separator: " • ")
    }
}

@MainActor
final class SchoolDetailViewModel: ObservableObject {
    @Published var school: School
    @Published var programs: [Program] = []
    @Published var isLoadingDetails = false
    @Published var isLoadingPrograms = false
    @Published var errorMessage: String?

    private let provider: SchoolDataProviding

    init(school: School, provider: SchoolDataProviding = CollegeScorecardService()) {
        self.school = school
        self.programs = school.programs
        self.provider = provider
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
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadPrograms(scorecardID: Int) async {
        isLoadingPrograms = true
        defer { isLoadingPrograms = false }

        do {
            programs = try await provider.fetchProgramsForSchool(schoolId: scorecardID)
        } catch {
            programs = []
        }
    }
}
