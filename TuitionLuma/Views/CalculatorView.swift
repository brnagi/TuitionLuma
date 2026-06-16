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
    @State private var selectedRepaymentPlan: SavedRepaymentPlan?

    private var calculatorSchools: [School] {
        appViewModel.savedSchools
    }

    private var hasProAccess: Bool {
        proPurchaseManager.state.isPro
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    schoolPicker
                    if viewModel.selectedSchool == nil {
                        calculatorEmptyState
                    } else {
                        programPicker
                        headlineNumbers
                        tuitionInfoCard
                        if hasProAccess {
                            aidInputs
                            planningModeCard
                            advancedCalculatorSection
                        } else {
                            proPlanningUnlockCard
                        }
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
                        if let selectedSchool = viewModel.selectedSchool {
                            appViewModel.savePreferredProgram(program, for: selectedSchool)
                        }
                        isShowingProgramDetails = false
                        isShowingProgramBrowser = false
                    }
                )
            }
            .sheet(item: $selectedRepaymentPlan) { plan in
                SavedRepaymentPlanDetailView(plan: plan)
            }
            .onChange(of: calculatorSchools.map(\.id)) { _, savedIDs in
                guard let selectedSchool = viewModel.selectedSchool else { return }
                if !savedIDs.contains(selectedSchool.id) {
                    viewModel.applySchoolDefaults(for: nil)
                }
            }
        }
    }

    private var schoolPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Calculator")
                .font(.largeTitle.weight(.heavy))
                .foregroundStyle(LumaTheme.ink)

            Text("Save a school from Explore first. Then come back here to model costs, aid, debt, and program outcomes.")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(LumaTheme.slate)
                .fixedSize(horizontal: false, vertical: true)

            Text("Choose a school")
                .font(.headline)
                .foregroundStyle(LumaTheme.ink)

            if !calculatorSchools.isEmpty {
                Picker("Choose a school", selection: $viewModel.selectedSchool) {
                    Text("Select a saved school").tag(Optional<School>.none)
                    ForEach(calculatorSchools) { school in
                        Text(school.name).tag(Optional(school))
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
                .overlay {
                    RoundedRectangle(cornerRadius: LumaTheme.cardRadius)
                        .stroke(LumaTheme.cardStroke)
                }
                .tint(LumaTheme.coral)
                .onChange(of: viewModel.selectedSchool) { _, newSchool in
                    isShowingProgramDetails = false
                    viewModel.applySchoolDefaults(for: newSchool)
                    applySavedProgramChoice()
                    Task {
                        await viewModel.loadProgramsForSelectedSchool()
                        applySavedProgramChoice()
                    }
                }
            }

        }
    }

    private var calculatorEmptyState: some View {
        EmptyStateCard(
            title: "Save a school first",
            message: "The calculator uses your saved schools so your planning stays focused. Save schools from Explore, then return here to model tuition, aid, and loan payments.",
            systemImage: "bookmark"
        ) {
            NavigationLink {
                ExploreView()
            } label: {
                EmptyStateActionLabel(title: "Explore Schools", systemImage: "magnifyingglass")
            }
            .buttonStyle(.plain)
            .accessibilityHint("Use the Explore tab to search and save schools.")
        }
    }

    private var programPicker: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "book.closed.fill")
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(LumaTheme.heroGradient, in: RoundedRectangle(cornerRadius: 14))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Program focus")
                        .font(.title3.weight(.heavy))
                        .foregroundStyle(LumaTheme.ink)

                    Text("Choose a major or program so cost planning can use program-level earnings, debt, and ROI where available.")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(LumaTheme.slate)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                if viewModel.isLoadingPrograms {
                    ProgressView()
                        .tint(LumaTheme.coral)
                }
            }

            if viewModel.availablePrograms.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Using school-wide outcomes")
                        .font(.headline.weight(.heavy))
                        .foregroundStyle(LumaTheme.ink)

                    Text("Program outcomes are not available yet, so TuitionLuma will use institution-level earnings and debt for this estimate.")
                        .font(.subheadline)
                        .foregroundStyle(LumaTheme.slate)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(LumaTheme.canvas, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Planning with")
                                .font(.caption.weight(.heavy))
                                .foregroundStyle(LumaTheme.slate)
                                .textCase(.uppercase)

                            Text(selectedProgramTitle)
                                .font(.title3.weight(.heavy))
                                .foregroundStyle(LumaTheme.ink)
                                .lineLimit(3)
                                .truncationMode(.tail)

                            if let selectedSchool = viewModel.selectedSchool,
                               let selectedProgram = viewModel.selectedProgram,
                               appViewModel.isPreferredProgram(selectedProgram, for: selectedSchool) {
                                Label("Saved for planning", systemImage: "checkmark.circle.fill")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(LumaTheme.valueGreen)
                            }
                        }

                        Spacer(minLength: 10)

                        Button {
                            isShowingProgramBrowser = true
                        } label: {
                            Label("Change", systemImage: "magnifyingglass")
                                .font(.caption.weight(.heavy))
                                .foregroundStyle(.white)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 12)
                                .background(LumaTheme.coral, in: Capsule())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Change program")
                        .accessibilityHint("Opens program search and filters.")
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(LumaTheme.aqua.opacity(0.10), in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
                .overlay {
                    RoundedRectangle(cornerRadius: LumaTheme.cardRadius)
                        .stroke(LumaTheme.aqua.opacity(0.22))
                }
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
        .overlay {
            RoundedRectangle(cornerRadius: LumaTheme.cardRadius)
                .stroke(LumaTheme.coral.opacity(0.12))
        }
        .shadow(color: LumaTheme.cardShadow.opacity(0.45), radius: 12, x: 0, y: 7)
    }

    private var selectedProgramTitle: String {
        viewModel.selectedProgram?.name ?? "Use institution average"
    }

    private func applySavedProgramChoice() {
        guard let selectedSchool = viewModel.selectedSchool,
              let preferredProgram = appViewModel.preferredProgram(
                for: selectedSchool,
                in: viewModel.availablePrograms
              ) else {
            return
        }

        viewModel.selectedProgram = preferredProgram
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

            if hasProAccess {
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
                Text("Aid, borrowing, and scholarships")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(LumaTheme.ink)

                Spacer()
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
                    .accessibilityLabel("Interest rate")
                    .accessibilityValue(viewModel.aidInput.interestRate.formatted(.percent.precision(.fractionLength(1))))
            }

            yearsInSchoolControl
            .accessibilityLabel("Years in school")
            .accessibilityValue("\(viewModel.aidInput.yearsInSchool)")
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

    private var proPlanningUnlockCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            ZStack(alignment: .topTrailing) {
                LumaTheme.heroGradient

                Circle()
                    .fill(.white.opacity(0.18))
                    .frame(width: 132, height: 132)
                    .offset(x: 44, y: -50)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .top) {
                        ProBadge()

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("$4.99")
                                .font(.title3.weight(.heavy))
                                .foregroundStyle(.white)

                            Text("one-time unlock")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white.opacity(0.84))
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(.white.opacity(0.18), in: RoundedRectangle(cornerRadius: 14))
                    }

                    VStack(alignment: .leading, spacing: 7) {
                        Text("Plan the real cost before you commit.")
                            .font(.title2.weight(.heavy))
                            .foregroundStyle(.white)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("Unlock aid planning, repayment forecasts, scenarios, and a polished family report.")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.90))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    HStack(spacing: 10) {
                        proSignalTile(title: "Aid", value: "Net cost", systemImage: "sparkles")
                        proSignalTile(title: "Debt", value: "Monthly", systemImage: "creditcard.fill")
                        proSignalTile(title: "Report", value: "Share", systemImage: "doc.richtext.fill")
                    }
                }
                .padding(18)
            }
            .clipShape(RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
            .overlay(alignment: .bottomTrailing) {
                Image(systemName: "graduationcap.fill")
                    .font(.system(size: 54, weight: .heavy))
                    .foregroundStyle(.white.opacity(0.12))
                    .padding(18)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Everything families ask next")
                    .font(.subheadline.weight(.heavy))
                    .foregroundStyle(LumaTheme.ink)

                VStack(spacing: 9) {
                    proPlanningBenefit("Aid, borrowing, scholarships", subtitle: "See the real gap after grants, family help, and loans.", systemImage: "dollarsign.circle.fill", tint: LumaTheme.mint)
                    proPlanningBenefit("Repayment and scenarios", subtitle: "Compare campus, residency, path, and 5-20 year loan terms.", systemImage: "slider.horizontal.3", tint: LumaTheme.coral)
                    proPlanningBenefit("Family-ready report", subtitle: "Export a polished PDF that explains cost, debt, and outcomes.", systemImage: "square.and.arrow.up.fill", tint: LumaTheme.outcomeTeal)
                }
            }

            Button {
                isShowingPaywall = true
            } label: {
                Label("Unlock TuitionLuma Pro", systemImage: "sparkles")
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 54)
                    .background(LumaTheme.heroGradient, in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityHint("Opens the TuitionLuma Pro unlock screen.")
        }
        .padding(18)
        .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
        .overlay {
            RoundedRectangle(cornerRadius: LumaTheme.cardRadius)
                .stroke(LumaTheme.coral.opacity(0.14))
        }
        .shadow(color: LumaTheme.coral.opacity(0.08), radius: 16, y: 8)
    }

    private func proSignalTile(title: String, value: String, systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: systemImage)
                .font(.caption.weight(.heavy))
                .accessibilityHidden(true)

            Text(title)
                .font(.caption2.weight(.bold))
                .textCase(.uppercase)
                .foregroundStyle(.white.opacity(0.72))

            Text(value)
                .font(.caption.weight(.heavy))
                .foregroundStyle(.white)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.white.opacity(0.17), in: RoundedRectangle(cornerRadius: 14))
        .foregroundStyle(.white)
    }

    private func proPlanningBenefit(_ title: String, subtitle: String, systemImage: String, tint: Color) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.heavy))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(tint, in: RoundedRectangle(cornerRadius: 10))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.heavy))
                    .foregroundStyle(LumaTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)

                Text(subtitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(LumaTheme.slate)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(LumaTheme.canvas, in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(tint.opacity(0.12))
        }
        .accessibilityElement(children: .combine)
    }

    private var aidAndBorrowingLock: some View {
        VStack(spacing: 12) {
            FeatureLock(
                title: "Unlock aid and borrowing",
                message: "Model grants, family help, work-study, and yearly loans with TuitionLuma Pro.",
                feature: .advancedDebtCalculator,
                action: { isShowingPaywall = true }
            )

            FeatureLock(
                title: "Unlock scholarship planning",
                message: "Add scholarships and grants to see how aid changes your real college cost.",
                feature: .scholarshipPlanning,
                action: { isShowingPaywall = true }
            )
        }
    }

    private var yearsInSchoolControl: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Years in school")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(LumaTheme.ink)

                Text("Adjust your degree timeline")
                    .font(.caption)
                    .foregroundStyle(LumaTheme.slate)
            }

            Spacer()

            HStack(spacing: 10) {
                yearStepperButton(systemImage: "minus") {
                    viewModel.aidInput.yearsInSchool = max(1, viewModel.aidInput.yearsInSchool - 1)
                }
                .disabled(viewModel.aidInput.yearsInSchool <= 1)

                Text("\(viewModel.aidInput.yearsInSchool)")
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(LumaTheme.ink)
                    .frame(minWidth: 28)

                yearStepperButton(systemImage: "plus") {
                    viewModel.aidInput.yearsInSchool = min(6, viewModel.aidInput.yearsInSchool + 1)
                }
                .disabled(viewModel.aidInput.yearsInSchool >= 6)
            }
            .padding(6)
            .background(LumaTheme.canvas, in: Capsule())
            .overlay {
                Capsule()
                    .stroke(LumaTheme.cardStroke)
            }
        }
        .padding(12)
        .background(LumaTheme.canvas.opacity(0.65), in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
    }

    private func yearStepperButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.heavy))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(LumaTheme.ink, in: Circle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var advancedCalculatorSection: some View {
        if hasProAccess {
            repaymentCard
            scenarioModelingCard
            reportExportCard
        } else {
            FeatureLock(
                title: "Unlock repayment calculator",
                message: "Upgrade to choose repayment terms, save plans on device, and compare debt scenarios.",
                feature: .advancedDebtCalculator,
                action: { isShowingPaywall = true }
            )

            FeatureLock(
                title: "Unlock scenario modeling",
                message: "Compare on-campus, off-campus, residency, and degree-path scenarios.",
                feature: .scenarioModeling,
                action: { isShowingPaywall = true }
            )

            FeatureLock(
                title: "Unlock family reports",
                message: "Share a polished PDF report with cost, aid, debt, and planning details.",
                feature: .pdfExport,
                action: { isShowingPaywall = true }
            )
        }
    }

    @ViewBuilder
    private var planningModeCard: some View {
        if hasProAccess {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Planning mode", systemImage: "person.2.fill")
                        .font(.headline)
                        .foregroundStyle(LumaTheme.ink)

                    Spacer()
                }

                HStack(spacing: 10) {
                    ForEach(PlanningMode.allCases) { mode in
                        planningModeButton(mode)
                    }
                }

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
            }
            .padding(16)
            .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
        } else {
            FeatureLock(
                title: "Unlock planning mode",
                message: "Switch between student and parent views as you refine affordability.",
                feature: .planningMode,
                action: { isShowingPaywall = true }
            )
        }
    }

    private func planningModeButton(_ mode: PlanningMode) -> some View {
        let isSelected = viewModel.planningMode == mode

        return Button {
            viewModel.planningMode = mode
        } label: {
            HStack(spacing: 7) {
                Image(systemName: mode == .student ? "graduationcap.fill" : "person.2.fill")
                    .font(.caption.weight(.bold))
                    .accessibilityHidden(true)

                Text(mode.rawValue)
                    .font(.subheadline.weight(.heavy))
                    .lineLimit(1)
            }
            .foregroundStyle(isSelected ? .white : LumaTheme.ink)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 46)
            .background(isSelected ? LumaTheme.coral : LumaTheme.canvas, in: Capsule())
            .overlay {
                Capsule()
                    .stroke(isSelected ? LumaTheme.coral.opacity(0.25) : LumaTheme.cardStroke)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(mode.rawValue) planning mode")
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
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
                    .lineLimit(2)
            }

            Text(viewModel.planningGuidance)
                .font(.footnote)
                .foregroundStyle(LumaTheme.slate)

            LumaButton(title: "Save Repayment Plan", systemImage: "tray.and.arrow.down.fill") {
                saveRepaymentPlan()
            }

            if let repaymentSaveMessage = viewModel.repaymentSaveMessage {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(LumaTheme.mint)
                        .accessibilityHidden(true)

                    Text(repaymentSaveMessage)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(LumaTheme.ink)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(LumaTheme.mint.opacity(0.12), in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
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
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Saved Plans")
                            .font(.caption.weight(.heavy))
                            .foregroundStyle(LumaTheme.ink)

                        Text("Stored privately on this device in TuitionLuma.")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(LumaTheme.slate)
                    }

                    Spacer()
                }

                ForEach(viewModel.savedRepaymentPlans.prefix(3)) { plan in
                    Button {
                        selectedRepaymentPlan = plan
                    } label: {
                        savedRepaymentPlanRow(plan)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("View repayment plan for \(plan.schoolName)")
                    .accessibilityHint("Opens saved repayment plan details.")
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
        guard hasProAccess else {
            isShowingPaywall = true
            return
        }

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
                .accessibilityLabel(title)
                .accessibilityValue(value.wrappedValue.formatted(LumaFormat.currency))
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

    private func saveRepaymentPlan() {
        guard hasProAccess else {
            isShowingPaywall = true
            return
        }

        viewModel.saveRepaymentPlan()
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

                Text("View")
                    .font(.caption2.weight(.heavy))
                    .foregroundStyle(LumaTheme.coral)
            }

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(LumaTheme.slate.opacity(0.65))
                .padding(.top, 2)
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
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
                .padding(.vertical, 10)
                .background(isSelected ? LumaTheme.coral : LumaTheme.mint.opacity(0.14), in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

private struct ShareableReport: Identifiable {
    let id = UUID()
    var url: URL
}

private struct SavedRepaymentPlanDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let plan: SavedRepaymentPlan

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(plan.schoolName)
                            .font(.title2.weight(.heavy))
                            .foregroundStyle(LumaTheme.ink)

                        Text(plan.scenarioSummary)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(LumaTheme.slate)
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))

                    HStack(spacing: 10) {
                        detailMetric("Monthly", plan.monthlyPayment.formatted(LumaFormat.currency), tint: LumaTheme.aqua)
                        detailMetric("Total", plan.totalRepayment.formatted(LumaFormat.currency), tint: LumaTheme.mint)
                    }

                    HStack(spacing: 10) {
                        detailMetric("Borrowed", plan.principal.formatted(LumaFormat.currency), tint: LumaTheme.coral)
                        detailMetric("Term", "\(plan.repaymentYears) years", tint: LumaTheme.sun)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Saved in TuitionLuma")
                            .font(.headline.weight(.heavy))
                            .foregroundStyle(LumaTheme.ink)

                        Text("This repayment plan is stored privately on this device and can be reviewed from the calculator's Saved Plans section.")
                            .font(.subheadline)
                            .foregroundStyle(LumaTheme.slate)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(18)
                    .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
                }
                .padding()
            }
            .background(LumaTheme.canvas)
            .navigationTitle("Repayment Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func detailMetric(_ title: String, _ value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value)
                .font(.title3.weight(.heavy))
                .foregroundStyle(LumaTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(LumaTheme.slate)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(tint.opacity(0.11), in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
    }
}

private struct ProgramBrowserSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedCategory = "All Categories"
    @State private var selectedCredential = "All Credentials"
    @FocusState private var isSearchFocused: Bool

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
            .scrollDismissesKeyboard(.interactively)
            .onTapGesture {
                isSearchFocused = false
            }
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

                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()

                    Button("Done") {
                        isSearchFocused = false
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(LumaTheme.slate)
                .accessibilityHidden(true)

            TextField(
                text: $searchText,
                prompt: Text("Search programs")
                    .foregroundStyle(LumaTheme.slate)
            ) {
                Text("Search programs")
            }
                .focused($isSearchFocused)
                .textInputAutocapitalization(.words)
                .foregroundStyle(LumaTheme.ink)
                .tint(LumaTheme.coral)
                .submitLabel(.search)
                .onSubmit {
                    isSearchFocused = false
                }
                .accessibilityLabel("Search programs")
        }
        .padding(14)
        .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
        .overlay {
            RoundedRectangle(cornerRadius: LumaTheme.cardRadius)
                .stroke(isSearchFocused ? LumaTheme.coral.opacity(0.45) : LumaTheme.cardStroke)
        }
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
        .accessibilityElement(children: .contain)
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
        .accessibilityLabel("Use institution average")
        .accessibilityValue(selectedProgram == nil ? "Selected" : "Not selected")
        .accessibilityHint("Uses school-wide earnings and debt outcomes.")
        .accessibilityAddTraits(selectedProgram == nil ? [.isButton, .isSelected] : .isButton)
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
                    .accessibilityHidden(true)
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
        .accessibilityLabel(systemImage == "folder.fill" ? "Category filter" : "Credential filter")
        .accessibilityValue(title)
        .accessibilityHint("Opens filter options.")
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
                    .accessibilityHidden(true)

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
        .accessibilityElement(children: .combine)
        .accessibilityLabel(program.name)
        .accessibilityValue("\(program.credential), \(categoryTitle(for: program)), earnings \(program.medianEarnings > 0 ? program.medianEarnings.formatted(LumaFormat.currency) : "not available")")
        .accessibilityHint(selectedProgram?.id == program.id ? "Currently selected." : "Double tap to select this program.")
        .accessibilityAddTraits(selectedProgram?.id == program.id ? [.isButton, .isSelected] : .isButton)
    }

    private func categoryTitle(for program: AcademicProgram) -> String {
        guard let category = program.category?.trimmingCharacters(in: .whitespacesAndNewlines), !category.isEmpty else {
            return "Other Programs"
        }

        return category
    }
}
