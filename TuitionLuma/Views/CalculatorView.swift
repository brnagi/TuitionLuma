import SwiftUI

struct CalculatorView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @EnvironmentObject private var subscriptionManager: MockSubscriptionManager
    @StateObject private var viewModel = CalculatorViewModel()
    @State private var isShowingPaywall = false

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
                    .environmentObject(subscriptionManager)
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
            }

            if !subscriptionManager.state.isPro {
                UpgradePrompt(
                    title: "Unlock advanced planning",
                    message: "Model loan payments, scholarships, grants, and living scenarios with Pro.",
                    action: { isShowingPaywall = true }
                )
            }
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

            Text(viewModel.annualCost > 0 ? "This subtracts grants, scholarships, family help, and work-study from the annual sticker price." : "College Scorecard has not reported enough cost data for this school yet.")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.88))
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
                Text(subscriptionManager.state.isPro ? "Aid, borrowing, and scholarships" : "Basic calculator")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(LumaTheme.ink)

                Spacer()

                if subscriptionManager.state.isPro {
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
        }
        .padding(18)
        .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
    }

    @ViewBuilder
    private var advancedCalculatorSection: some View {
        if subscriptionManager.state.isPro {
            repaymentCard
            scenarioModelingCard
            reportExportCard
        } else {
            FeatureLock(
                title: "Advanced repayment forecast",
                message: "Upgrade to see monthly loan payment projections, 10-year repayment, and debt scenarios.",
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

                if subscriptionManager.state.isPro {
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

            Text(subscriptionManager.state.isPro ? "Switch between student and parent planning views as you refine the plan." : "Free mode shows one shared planning view.")
                .font(.subheadline)
                .foregroundStyle(LumaTheme.slate)
        }
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
    }

    private var repaymentCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Loan estimate", systemImage: "creditcard.fill")
                    .font(.headline)
                    .foregroundStyle(LumaTheme.ink)

                Spacer()

                Text("10 years")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 9)
                    .background(LumaTheme.coral, in: Capsule())
            }

            HStack(spacing: 10) {
                repaymentMetric("Borrowed", viewModel.loanPrincipal.formatted(LumaFormat.currency))
                repaymentMetric("Monthly", viewModel.monthlyPayment.formatted(LumaFormat.currency))
            }

            HStack {
                Text("Total repayment")
                    .foregroundStyle(LumaTheme.slate)

                Spacer()

                Text(viewModel.totalTenYearRepayment.formatted(LumaFormat.currency))
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(LumaTheme.ink)
            }

            Text("Use this as a planning estimate. Real loan terms can vary by federal loan limits, private loans, fees, and repayment plan.")
                .font(.footnote)
                .foregroundStyle(LumaTheme.slate)
        }
        .padding(18)
        .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
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

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                scenarioChip("On campus")
                scenarioChip("Off campus")
                scenarioChip("In-state")
                scenarioChip("Out-of-state")
                scenarioChip("2-year path")
                scenarioChip("4-year path")
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

            Text("PDF export is mocked for the MVP and ready for a future report generator.")
                .font(.subheadline)
                .foregroundStyle(LumaTheme.slate)

            LumaButton(title: "Share Cost Report", systemImage: "doc.richtext") {}
        }
        .padding(18)
        .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
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

    private func repaymentMetric(_ title: String, _ value: String) -> some View {
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
        .background(LumaTheme.aqua.opacity(0.10), in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
    }

    private func scenarioChip(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.bold))
            .foregroundStyle(LumaTheme.ink)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(LumaTheme.mint.opacity(0.14), in: Capsule())
    }
}
