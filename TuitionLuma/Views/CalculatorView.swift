import SwiftUI

struct CalculatorView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @EnvironmentObject private var proPurchaseManager: ProPurchaseManager
    @StateObject private var viewModel = CalculatorViewModel()
    @State private var isShowingPaywall = false
    @State private var isGeneratingReport = false
    @State private var reportErrorMessage: String?
    @State private var shareableReport: ShareableReport?
    @State private var isShowingProgramDetails = false
    @State private var isShowingProgramBrowser = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    schoolPicker
                    if viewModel.selectedSchool == nil {
                        EmptyStateView(
                            title: "Choose a live school first",
                            message: "Search real College Scorecard colleges in Explore, then return here to model costs.",
                            systemImage: "building.columns"
                        )
                        .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
                    } else {
                        programPicker
                        headlineNumbers
                        tuitionInfoCard
                        aidInputs
                        planningModeCard
                        advancedCalculatorSection
                    }
                }
                .padding()
            }
            .background(LumaTheme.canvas)
            .sheet(isPresented: $isShowingPaywall) {
                PaywallView()
                    .environmentObject(proPurchaseManager)
            }
            .sheet(item: $shareableReport) { report in
                ShareSheet(items: [report.url])
            }
            .sheet(isPresented: $isShowingProgramBrowser) {
                ProgramBrowserSheet(
                    programs: viewModel.availablePrograms,
                    selectedProgram: viewModel.selectedProgram,
                    onSelect: { program in
                        viewModel.selectedProgram = program
                        isShowingProgramDetails = false
                        isShowingProgramBrowser = false
                    }
                )
            }
        }
    }

    private var schoolPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Calculator")
                .font(.largeTitle.weight(.heavy))
                .foregroundStyle(LumaTheme.ink)

            Text("Choose a school")
                .font(.headline)
                .foregroundStyle(LumaTheme.ink)

            if appViewModel.knownSchools.isEmpty {
                Text("No live schools loaded yet")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(LumaTheme.slate)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
            } else {
                Picker("Choose a school", selection: $viewModel.selectedSchool) {
                    Text("Select a school").tag(Optional<School>.none)
                    ForEach(appViewModel.knownSchools) { school in
                        Text(school.name).tag(Optional(school))
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
                .onChange(of: viewModel.selectedSchool) { _, newSchool in
                    isShowingProgramDetails = false
                    viewModel.applySchoolDefaults(for: newSchool)
                    Task {
                        await viewModel.loadProgramsForSelectedSchool()
                    }
                }
            }

            if !proPurchaseManager.state.isPro {
                UpgradePrompt(
                    title: "Unlock advanced planning",
                    message: "Model loan payments, scholarships, grants, and living scenarios with Pro.",
                    action: { isShowingPaywall = true }
                )
            }
        }
    }

    private var programPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Academic program", systemImage: "book.closed.fill")
                    .font(.headline)
                    .foregroundStyle(LumaTheme.ink)

                Spacer()

                if viewModel.isLoadingPrograms {
                    ProgressView()
                        .tint(LumaTheme.coral)
                }
            }

            if viewModel.availablePrograms.isEmpty {
                Text("Institution-level earnings and debt will be used until program outcomes are available.")
                    .font(.subheadline)
                    .foregroundStyle(LumaTheme.slate)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(LumaTheme.canvas, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Selected Program")
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(LumaTheme.slate)

                    Text(selectedProgramTitle)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(LumaTheme.ink)
                        .lineLimit(2)
                        .truncationMode(.tail)

                    Button {
                        isShowingProgramBrowser = true
                    } label: {
                        Label("Change Program", systemImage: "magnifyingglass")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(LumaTheme.coral)
                    }
                    .buttonStyle(.plain)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(LumaTheme.canvas, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
                .accessibilityLabel("Academic program")
                .accessibilityValue(selectedProgramTitle)
                .onChange(of: viewModel.selectedProgram) { _, _ in
                    isShowingProgramDetails = false
                }

                if let selectedProgram = viewModel.selectedProgram {
                    programOutcomePreview(selectedProgram)
                }
            }

            if let programErrorMessage = viewModel.programErrorMessage {
                Text(programErrorMessage)
                    .font(.caption)
                    .foregroundStyle(LumaTheme.slate)
            }
        }
        .padding(18)
        .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
    }

    private var selectedProgramTitle: String {
        viewModel.selectedProgram?.name ?? "Use institution average"
    }

    private func programOutcomePreview(_ program: AcademicProgram) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                programMetric(
                    title: "Program earnings",
                    value: program.medianEarnings > 0 ? program.medianEarnings.formatted(LumaFormat.currency) : "Not reported",
                    tint: LumaTheme.outcomeTeal
                )

                programMetric(
                    title: "ROI grade",
                    value: viewModel.roiOutcome?.grade ?? "Not reported",
                    tint: LumaTheme.mint
                )
            }

            DisclosureGroup(isExpanded: $isShowingProgramDetails) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        programMetric(
                            title: "Program debt",
                            value: program.debt.map { $0.formatted(LumaFormat.currency) } ?? "Not reported",
                            tint: LumaTheme.sun
                        )

                        if let roiOutcome = viewModel.roiOutcome {
                            programMetric(
                                title: "Outcome source",
                                value: roiOutcome.usedProgramEarnings || roiOutcome.usedProgramDebt ? "Program" : "School",
                                tint: LumaTheme.coral
                            )
                        }
                    }

                    if let roiOutcome = viewModel.roiOutcome {
                        Text(roiOutcome.usedProgramEarnings || roiOutcome.usedProgramDebt ? "Using program-level outcomes where College Scorecard reports them." : "Program salary or debt information is unavailable. Using school-wide outcomes instead.")
                            .font(.caption)
                            .foregroundStyle(LumaTheme.slate)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if !program.pathLabels.isEmpty {
                        pathLabelWrap(program.pathLabels)
                    }
                }
                .padding(.top, 8)
            } label: {
                Text("More Program Details")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(LumaTheme.ink)
            }
            .tint(LumaTheme.coral)
            .padding(.top, 2)
        }
    }

    private var headlineNumbers: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Your estimated price")
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(headlineCostText(viewModel.netAnnualCost))
                        .font(.system(size: 40, weight: .heavy))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)

                    Text("net annual cost")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white.opacity(0.86))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(headlineCostText(viewModel.netTotalCost))
                        .font(.title2.weight(.heavy))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)

                    Text("\(viewModel.aidInput.yearsInSchool)-year total")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.86))
                }
            }

            Text(viewModel.annualCost > 0 ? "This starts with reported cost data, then subtracts grants, scholarships, and work-study. Family help and loans show how the remaining cost gets covered." : "College Scorecard has not reported enough cost data for this school yet.")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.88))

            if proPurchaseManager.state.isPro {
                Text(viewModel.scenarioSummary)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.88))
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(.white.opacity(0.18), in: Capsule())
            }
        }
        .padding(20)
        .background(LumaTheme.heroGradient, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
    }

    @ViewBuilder
    private var tuitionInfoCard: some View {
        if let school = viewModel.selectedSchool {
            let cost = school.costEstimate

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label("Tuition and cost data", systemImage: "dollarsign.circle.fill")
                        .font(.headline)
                        .foregroundStyle(LumaTheme.ink)

                    Spacer()

                    Text("College Scorecard")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(LumaTheme.slate)
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    costDataTile(
                        title: "In-state tuition",
                        value: moneyText(cost.tuitionAndFees),
                        tint: LumaTheme.valueGreen
                    )

                    costDataTile(
                        title: "Out-of-state tuition",
                        value: moneyText(cost.outOfStateTuition),
                        tint: LumaTheme.outcomeTeal
                    )

                    costDataTile(
                        title: "Annual cost",
                        value: moneyText(cost.estimatedAnnualCost),
                        tint: LumaTheme.coral
                    )

                    costDataTile(
                        title: "Avg net price",
                        value: moneyText(cost.averageNetPrice),
                        tint: LumaTheme.mint
                    )
                }

                Text(costDataNote(for: school))
                    .font(.caption)
                    .foregroundStyle(LumaTheme.slate)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(18)
            .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
        }
    }

    private var aidInputs: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(proPurchaseManager.state.isPro ? "Aid, borrowing, and scholarships" : "Basic calculator")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(LumaTheme.ink)

                Spacer()

                if proPurchaseManager.state.isPro {
                    ProBadge(compact: true)
                }
            }

            moneySlider(
                title: "Grants and scholarships",
                value: $viewModel.aidInput.grantsAndScholarships,
                range: 0...70_000,
                tint: LumaTheme.mint
            )

            moneySlider(
                title: "Family contribution",
                value: $viewModel.aidInput.familyContribution,
                range: 0...50_000,
                tint: LumaTheme.sun
            )

            moneySlider(
                title: "Work-study",
                value: $viewModel.aidInput.workStudy,
                range: 0...8_000,
                tint: LumaTheme.aqua
            )

            moneySlider(
                title: "Loans per year",
                value: $viewModel.aidInput.annualLoanAmount,
                range: 0...25_000,
                tint: LumaTheme.coral
            )

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Interest rate")
                    Spacer()
                    Text(viewModel.aidInput.interestRate.formatted(.percent.precision(.fractionLength(1))))
                        .fontWeight(.bold)
                }
                .foregroundStyle(LumaTheme.ink)

                Slider(value: $viewModel.aidInput.interestRate, in: 0...0.12, step: 0.001)
                    .tint(LumaTheme.coral)
            }

            Stepper(value: $viewModel.aidInput.yearsInSchool, in: 1...6) {
                HStack {
                    Text("Years in school")
                    Spacer()
                    Text("\(viewModel.aidInput.yearsInSchool)")
                        .fontWeight(.bold)
                }
                .foregroundStyle(LumaTheme.ink)
            }
            .onChange(of: viewModel.aidInput.yearsInSchool) { _, newValue in
                if newValue == 2 {
                    viewModel.degreePathScenario = .twoYear
                } else if newValue == 4 {
                    viewModel.degreePathScenario = .fourYear
                }
            }
        }
        .padding(18)
        .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
    }

    @ViewBuilder
    private var advancedCalculatorSection: some View {
        if proPurchaseManager.state.isPro {
            repaymentCard
            scenarioModelingCard
            reportExportCard
        } else {
            FeatureLock(
                title: "Advanced repayment forecast",
                message: "Upgrade to choose repayment terms, save plans on device, and compare debt scenarios.",
                feature: .advancedDebtCalculator,
                action: { isShowingPaywall = true }
            )

            FeatureLock(
                title: "Scholarship and grant planning",
                message: "Model awards and family contributions across different college paths.",
                feature: .scholarshipPlanning,
                action: { isShowingPaywall = true }
            )
        }
    }

    private var planningModeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Planning mode", systemImage: "person.2.fill")
                    .font(.headline)
                    .foregroundStyle(LumaTheme.ink)

                Spacer()

                if proPurchaseManager.state.isPro {
                    ProBadge(compact: true)
                } else {
                    Button("Unlock") {
                        isShowingPaywall = true
                    }
                    .font(.caption.weight(.bold))
                    .foregroundStyle(LumaTheme.coral)
                    .buttonStyle(.plain)
                }
            }

            if proPurchaseManager.state.isPro {
                Picker("Planning mode", selection: $viewModel.planningMode) {
                    ForEach(PlanningMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                VStack(alignment: .leading, spacing: 8) {
                    Text(viewModel.affordabilityFocus)
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(LumaTheme.coral)

                    Text(viewModel.planningModeSummary)
                        .font(.subheadline)
                        .foregroundStyle(LumaTheme.slate)
                        .fixedSize(horizontal: false, vertical: true)
                }

                planningModeMetrics
            } else {
                Text("Free mode shows one shared planning view.")
                    .font(.subheadline)
                    .foregroundStyle(LumaTheme.slate)
            }
        }
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
    }

    @ViewBuilder
    private var planningModeMetrics: some View {
        if viewModel.planningMode == .student {
            HStack(spacing: 10) {
                planningMetric(
                    title: "Monthly payment",
                    value: viewModel.monthlyPayment.formatted(LumaFormat.currency),
                    tint: LumaTheme.aqua
                )
                planningMetric(
                    title: "Cash gap / year",
                    value: viewModel.annualStudentOutOfPocketGap.formatted(LumaFormat.currency),
                    tint: LumaTheme.coral
                )
            }
        } else {
            HStack(spacing: 10) {
                planningMetric(
                    title: "Family / year",
                    value: viewModel.annualFamilyContribution.formatted(LumaFormat.currency),
                    tint: LumaTheme.sun
                )
                planningMetric(
                    title: "Remaining gap",
                    value: viewModel.annualFamilyFundingGap.formatted(LumaFormat.currency),
                    tint: LumaTheme.coral
                )
            }
        }
    }

    private var repaymentCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Repayment calculator", systemImage: "creditcard.fill")
                    .font(.headline)
                    .foregroundStyle(LumaTheme.ink)

                Spacer()

                ProBadge(compact: true)
            }

            scenarioGroup(title: "Loan term") {
                HStack(spacing: 8) {
                    ForEach(RepaymentTerm.allCases) { term in
                        scenarioChip(
                            term.title,
                            isSelected: viewModel.repaymentTerm == term
                        ) {
                            viewModel.repaymentTerm = term
                        }
                    }
                }
            }

            HStack(spacing: 10) {
                repaymentMetric("Borrowed", viewModel.loanPrincipal.formatted(LumaFormat.currency))
                repaymentMetric("Monthly", viewModel.monthlyPayment.formatted(LumaFormat.currency))
            }

            HStack {
                Text("Total repayment")
                    .foregroundStyle(LumaTheme.slate)

                Spacer()

                Text(viewModel.totalRepayment.formatted(LumaFormat.currency))
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(LumaTheme.ink)
            }

            if viewModel.planningMode == .parent {
                HStack(spacing: 10) {
                    repaymentMetric("Family total", viewModel.totalFamilyContribution.formatted(LumaFormat.currency), tint: LumaTheme.sun)
                    repaymentMetric("Annual gap", viewModel.annualFamilyFundingGap.formatted(LumaFormat.currency))
                }
            }

            HStack {
                Text(viewModel.affordabilityFocus)
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(LumaTheme.coral)

                Spacer()

                Text(viewModel.scenarioSummary)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(LumaTheme.slate)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            Text(viewModel.planningGuidance)
                .font(.footnote)
                .foregroundStyle(LumaTheme.slate)

            LumaButton(title: "Save Repayment Plan", systemImage: "tray.and.arrow.down.fill") {
                viewModel.saveRepaymentPlan()
            }

            if let repaymentSaveMessage = viewModel.repaymentSaveMessage {
                Text(repaymentSaveMessage)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(LumaTheme.mint)
            }

            savedRepaymentPlansSection
        }
        .padding(18)
        .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
    }

    @ViewBuilder
    private var savedRepaymentPlansSection: some View {
        if !viewModel.savedRepaymentPlans.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("Saved on this device")
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(LumaTheme.slate)

                ForEach(viewModel.savedRepaymentPlans.prefix(3)) { plan in
                    savedRepaymentPlanRow(plan)
                }
            }
        }
    }

    private var scenarioModelingCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Scenario modeling", systemImage: "slider.horizontal.3")
                    .font(.headline)
                    .foregroundStyle(LumaTheme.ink)

                Spacer()
                ProBadge(compact: true)
            }

            VStack(alignment: .leading, spacing: 12) {
                scenarioGroup(title: "Living") {
                    HStack(spacing: 10) {
                        ForEach(LivingScenario.allCases) { scenario in
                            scenarioChip(
                                scenario.rawValue,
                                isSelected: viewModel.livingScenario == scenario
                            ) {
                                viewModel.livingScenario = scenario
                            }
                        }
                    }
                }

                scenarioGroup(title: "Residency") {
                    HStack(spacing: 10) {
                        ForEach(ResidencyScenario.allCases) { scenario in
                            scenarioChip(
                                scenario.rawValue,
                                isSelected: viewModel.residencyScenario == scenario
                            ) {
                                viewModel.residencyScenario = scenario
                            }
                        }
                    }
                }

                scenarioGroup(title: "Path") {
                    HStack(spacing: 10) {
                        ForEach(DegreePathScenario.allCases) { scenario in
                            scenarioChip(
                                scenario.title,
                                isSelected: viewModel.degreePathScenario == scenario
                            ) {
                                viewModel.selectDegreePath(scenario)
                            }
                        }
                    }
                }
            }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.annualCost.formatted(LumaFormat.currency))
                        .font(.title3.weight(.heavy))
                        .foregroundStyle(LumaTheme.ink)
                    Text("modeled annual cost")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(LumaTheme.slate)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(viewModel.netTotalCost.formatted(LumaFormat.currency))
                        .font(.title3.weight(.heavy))
                        .foregroundStyle(LumaTheme.ink)
                    Text("modeled net total")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(LumaTheme.slate)
                }
            }
        }
        .padding(18)
        .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
    }

    private var reportExportCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Family report", systemImage: "square.and.arrow.up.fill")
                    .font(.headline)
                    .foregroundStyle(LumaTheme.ink)

                Spacer()
                ProBadge(compact: true)
            }

            Text("Create a polished PDF with cost breakdowns, aid planning, repayment estimates, and scenario details to review with family.")
                .font(.subheadline)
                .foregroundStyle(LumaTheme.slate)

            LumaButton(
                title: isGeneratingReport ? "Building Report..." : "Share Cost Report",
                systemImage: isGeneratingReport ? "hourglass" : "doc.richtext"
            ) {
                generateAndShareReport()
            }
            .disabled(isGeneratingReport)

            if let reportErrorMessage {
                Text(reportErrorMessage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(LumaTheme.warningOrange)
            }
        }
        .padding(18)
        .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
    }

    private func generateAndShareReport() {
        guard let selectedSchool = viewModel.selectedSchool else {
            reportErrorMessage = "Choose a school before sharing a report."
            return
        }

        isGeneratingReport = true
        reportErrorMessage = nil

        let payload = CostReportPayload(
            school: selectedSchool,
            aidInput: viewModel.aidInput,
            planningMode: viewModel.planningMode,
            livingScenario: viewModel.livingScenario,
            residencyScenario: viewModel.residencyScenario,
            degreePathScenario: viewModel.degreePathScenario,
            repaymentTerm: viewModel.repaymentTerm,
            annualCost: viewModel.annualCost,
            totalDegreeCost: viewModel.totalDegreeCost,
            netAnnualCost: viewModel.netAnnualCost,
            netTotalCost: viewModel.netTotalCost,
            loanPrincipal: viewModel.loanPrincipal,
            monthlyPayment: viewModel.monthlyPayment,
            totalRepayment: viewModel.totalRepayment,
            annualAidTotal: viewModel.annualAidTotal,
            totalFamilyContribution: viewModel.totalFamilyContribution,
            annualFamilyFundingGap: viewModel.annualFamilyFundingGap,
            annualStudentOutOfPocketGap: viewModel.annualStudentOutOfPocketGap
        )

        do {
            let url = try CostReportPDFGenerator.generate(payload: payload)
            shareableReport = ShareableReport(url: url)
        } catch {
            reportErrorMessage = "TuitionLuma could not create the PDF report."
        }

        isGeneratingReport = false
    }

    private func moneySlider(title: String, value: Binding<Double>, range: ClosedRange<Double>, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                Spacer()
                Text(value.wrappedValue.formatted(LumaFormat.currency))
                    .fontWeight(.bold)
            }
            .foregroundStyle(LumaTheme.ink)

            Slider(value: value, in: range, step: 500)
                .tint(tint)
        }
    }

    private func costDataTile(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value)
                .font(.headline.weight(.heavy))
                .foregroundStyle(value == "Not reported" ? LumaTheme.slate : tint)
                .lineLimit(1)
                .minimumScaleFactor(0.68)

            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(LumaTheme.slate)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(tint.opacity(0.08), in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
    }

    private func programMetric(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(value)
                .font(.subheadline.weight(.heavy))
                .foregroundStyle(value == "Not reported" ? LumaTheme.slate : tint)
                .lineLimit(2)
                .truncationMode(.tail)

            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(LumaTheme.slate)
                .lineLimit(2)
                .truncationMode(.tail)
        }
        .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
        .padding(12)
        .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
    }

    private func pathLabelWrap(_ labels: [AcademicPathLabel]) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 7)], alignment: .leading, spacing: 7) {
            ForEach(labels, id: \.self) { label in
                Text(label.rawValue)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(LumaTheme.ink)
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 9)
                    .background(LumaTheme.aqua.opacity(0.12), in: Capsule())
            }
        }
    }

    private func moneyText(_ value: Double?) -> String {
        guard let value, value > 0 else {
            return "Not reported"
        }

        return value.formatted(LumaFormat.currency)
    }

    private func headlineCostText(_ value: Double) -> String {
        guard viewModel.annualCost > 0 else {
            return "N/A"
        }

        return value.formatted(LumaFormat.currency)
    }

    private func costDataNote(for school: School) -> String {
        let cost = school.costEstimate
        if cost.costOfAttendance == nil, cost.estimatedAnnualCost > 0 {
            return "Annual cost uses the best available reported fields. Cost of attendance is not reported for this school, so housing or personal expenses may be incomplete."
        }

        if !school.missingDataFields.isEmpty {
            return "Some fields are not reported yet: \(school.missingDataFields.prefix(3).joined(separator: ", "))."
        }

        return "Annual cost uses reported cost of attendance when available. Avg net price reflects typical costs after grant and scholarship aid."
    }

    private func savedRepaymentPlanRow(_ plan: SavedRepaymentPlan) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "doc.text.fill")
                .font(.subheadline)
                .foregroundStyle(LumaTheme.coral)
                .frame(width: 30, height: 30)
                .background(LumaTheme.coral.opacity(0.10), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(plan.schoolName)
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(LumaTheme.ink)
                    .lineLimit(1)

                Text("\(plan.repaymentYears)-year term • \(plan.scenarioSummary)")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(LumaTheme.slate)
                    .lineLimit(2)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(plan.monthlyPayment.formatted(LumaFormat.currency))
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(LumaTheme.ink)

                Text("monthly")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(LumaTheme.slate)
            }
        }
        .padding(12)
        .background(LumaTheme.canvas, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
    }

    private func repaymentMetric(_ title: String, _ value: String, tint: Color = LumaTheme.aqua) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value)
                .font(.title2.weight(.heavy))
                .foregroundStyle(LumaTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.68)

            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(LumaTheme.slate)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
    }

    private func planningMetric(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(value)
                .font(.headline.weight(.heavy))
                .foregroundStyle(LumaTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(LumaTheme.slate)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(tint.opacity(0.11), in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
    }

    private func scenarioGroup<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.caption.weight(.heavy))
                .foregroundStyle(LumaTheme.slate)

            content()
        }
    }

    private func scenarioChip(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(isSelected ? .white : LumaTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSelected ? LumaTheme.coral : LumaTheme.mint.opacity(0.14), in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct ShareableReport: Identifiable {
    let id = UUID()
    var url: URL
}

private struct ProgramBrowserSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedCategory = "All Categories"
    @State private var selectedCredential = "All Credentials"

    var programs: [AcademicProgram]
    var selectedProgram: AcademicProgram?
    var onSelect: (AcademicProgram?) -> Void

    private var categories: [String] {
        ["All Categories"] + Set(programs.map(categoryTitle(for:))).sorted()
    }

    private var credentials: [String] {
        ["All Credentials"] + Set(programs.map(\.credential)).sorted()
    }

    private var popularPrograms: [AcademicProgram] {
        let popular = programs
            .filter { ($0.completionCount ?? 0) > 0 }
            .sorted {
                if ($0.completionCount ?? 0) == ($1.completionCount ?? 0) {
                    return $0.medianEarnings > $1.medianEarnings
                }
                return ($0.completionCount ?? 0) > ($1.completionCount ?? 0)
            }

        return Array((popular.isEmpty ? topPrograms : popular).prefix(5))
    }

    private var topPrograms: [AcademicProgram] {
        Array(programs
            .filter { $0.medianEarnings > 0 }
            .sorted {
                if $0.medianEarnings == $1.medianEarnings {
                    return ($0.debt ?? .greatestFiniteMagnitude) < ($1.debt ?? .greatestFiniteMagnitude)
                }
                return $0.medianEarnings > $1.medianEarnings
            }
            .prefix(5))
    }

    private var filteredPrograms: [AcademicProgram] {
        programs.filter { program in
            let matchesSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || program.name.localizedCaseInsensitiveContains(searchText)
                || program.credential.localizedCaseInsensitiveContains(searchText)
                || categoryTitle(for: program).localizedCaseInsensitiveContains(searchText)
            let matchesCategory = selectedCategory == "All Categories" || categoryTitle(for: program) == selectedCategory
            let matchesCredential = selectedCredential == "All Credentials" || program.credential == selectedCredential

            return matchesSearch && matchesCategory && matchesCredential
        }
    }

    private var groupedPrograms: [(String, [AcademicProgram])] {
        Dictionary(grouping: filteredPrograms, by: categoryTitle(for:))
            .map { key, value in
                (
                    key,
                    value.sorted {
                        if $0.medianEarnings == $1.medianEarnings {
                            return ($0.completionCount ?? 0) > ($1.completionCount ?? 0)
                        }
                        return $0.medianEarnings > $1.medianEarnings
                    }
                )
            }
            .sorted { $0.0 < $1.0 }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    searchField
                    filterRow
                    selectedAverageButton

                    if !searchText.isEmpty || selectedCategory != "All Categories" || selectedCredential != "All Credentials" {
                        filteredCatalog
                    } else {
                        curatedSection(title: "Popular Programs", programs: popularPrograms)
                        curatedSection(title: "Top Programs", programs: topPrograms)
                        filteredCatalog
                    }
                }
                .padding()
            }
            .background(LumaTheme.canvas)
            .navigationTitle("Change Program")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(LumaTheme.coral)
                }
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(LumaTheme.slate)

            TextField("Search programs", text: $searchText)
                .textInputAutocapitalization(.words)
        }
        .padding(14)
        .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
    }

    private var filterRow: some View {
        HStack(spacing: 10) {
            filterMenu(title: selectedCategory, systemImage: "folder.fill", options: categories) { option in
                selectedCategory = option
            }

            filterMenu(title: selectedCredential, systemImage: "graduationcap.fill", options: credentials) { option in
                selectedCredential = option
            }
        }
    }

    private var selectedAverageButton: some View {
        Button {
            onSelect(nil)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: selectedProgram == nil ? "checkmark.circle.fill" : "building.columns.fill")
                    .foregroundStyle(selectedProgram == nil ? LumaTheme.mint : LumaTheme.slate)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Use institution average")
                        .font(.subheadline.weight(.heavy))
                        .foregroundStyle(LumaTheme.ink)

                    Text("Use school-wide outcomes when you are still deciding.")
                        .font(.caption)
                        .foregroundStyle(LumaTheme.slate)
                }

                Spacer()
            }
            .padding(14)
            .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
        }
        .buttonStyle(.plain)
    }

    private var filteredCatalog: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All Programs")
                .font(.headline)
                .foregroundStyle(LumaTheme.ink)

            if groupedPrograms.isEmpty {
                Text("No programs match your search.")
                    .font(.subheadline)
                    .foregroundStyle(LumaTheme.slate)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
            } else {
                ForEach(groupedPrograms, id: \.0) { category, programs in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(category)
                            .font(.caption.weight(.heavy))
                            .foregroundStyle(LumaTheme.slate)
                            .textCase(.uppercase)

                        ForEach(programs) { program in
                            programRow(program)
                        }
                    }
                }
            }
        }
    }

    private func curatedSection(title: String, programs: [AcademicProgram]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(LumaTheme.ink)

            if programs.isEmpty {
                Text("Program outcomes are not available yet.")
                    .font(.subheadline)
                    .foregroundStyle(LumaTheme.slate)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
            } else {
                ForEach(programs) { program in
                    programRow(program)
                }
            }
        }
    }

    private func filterMenu(title: String, systemImage: String, options: [String], action: @escaping (String) -> Void) -> some View {
        Menu {
            ForEach(options, id: \.self) { option in
                Button(option) {
                    action(option)
                }
            }
        } label: {
            HStack(spacing: 7) {
                Image(systemName: systemImage)
                Text(title)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.bold))
            }
            .font(.caption.weight(.bold))
            .foregroundStyle(LumaTheme.ink)
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .background(.white, in: Capsule())
        }
    }

    private func programRow(_ program: AcademicProgram) -> some View {
        Button {
            onSelect(program)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: selectedProgram?.id == program.id ? "checkmark.circle.fill" : "book.closed.fill")
                    .font(.subheadline)
                    .foregroundStyle(selectedProgram?.id == program.id ? LumaTheme.mint : LumaTheme.coral)
                    .frame(width: 30, height: 30)
                    .background(LumaTheme.coral.opacity(0.10), in: Circle())

                VStack(alignment: .leading, spacing: 6) {
                    Text(program.name)
                        .font(.subheadline.weight(.heavy))
                        .foregroundStyle(LumaTheme.ink)
                        .lineLimit(2)
                        .truncationMode(.tail)

                    Text("\(program.credential) • \(categoryTitle(for: program))")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(LumaTheme.slate)
                        .lineLimit(2)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(program.medianEarnings > 0 ? program.medianEarnings.formatted(LumaFormat.currency) : "N/A")
                        .font(.subheadline.weight(.heavy))
                        .foregroundStyle(program.medianEarnings > 0 ? LumaTheme.outcomeTeal : LumaTheme.slate)

                    Text("earnings")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(LumaTheme.slate)
                }
            }
            .padding(14)
            .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
        }
        .buttonStyle(.plain)
    }

    private func categoryTitle(for program: AcademicProgram) -> String {
        guard let category = program.category?.trimmingCharacters(in: .whitespacesAndNewlines), !category.isEmpty else {
            return "Other Programs"
        }

        return category
    }
}
