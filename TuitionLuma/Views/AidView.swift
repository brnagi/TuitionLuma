import SwiftUI

struct AidView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @EnvironmentObject private var proPurchaseManager: ProPurchaseManager
    @EnvironmentObject private var studentProfileStore: StudentProfileStore
    @State private var isShowingPaywall = false
    @State private var isShowingProfile = false

    private var opportunities: [ScholarshipOpportunity] {
        ScholarshipDiscoveryEngine.opportunities(
            for: studentProfileStore.profile,
            savedSchools: appViewModel.savedSchools,
            programChoices: appViewModel.savedProgramChoices
        )
    }

    private var schoolSpecificOpportunities: [ScholarshipOpportunity] {
        opportunities.filter { $0.school != nil }
    }

    private var generalOpportunities: [ScholarshipOpportunity] {
        opportunities.filter { $0.school == nil }
    }

    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 18) {
                    screenTitle
                    header

                    if !proPurchaseManager.state.isPro {
                        lockedScholarshipPreview
                    } else if !studentProfileStore.profile.isComplete {
                        profileNeededCard
                    } else {
                        financialPlanningWorkspace
                        scholarshipSummary
                        priorityPlanCard
                        calculatorBridgeCard
                        if appViewModel.savedSchools.isEmpty {
                            savedSchoolsNeededCard
                        } else {
                            schoolMatchesSection
                        }
                        generalAidSection
                    }
                }
                .padding()
                .padding(.bottom, 96)
            }
            .scrollBounceBehavior(.basedOnSize, axes: .vertical)
            .background(LumaTheme.canvas.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isShowingPaywall) {
                PaywallView()
                    .environmentObject(proPurchaseManager)
            }
            .sheet(isPresented: $isShowingProfile) {
                StudentProfileEditorView(profile: $studentProfileStore.profile)
            }
        }
    }

    private var screenTitle: some View {
        Text("Aid")
            .font(.largeTitle.weight(.heavy))
            .foregroundStyle(LumaTheme.ink)
            .padding(.top, 2)
            .accessibilityAddTraits(.isHeader)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Find aid you can act on")
                .font(.system(size: 24, weight: .heavy))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
                .shadow(color: LumaTheme.gradientTextShadow, radius: 2, y: 1)

            Text("See likely scholarship paths, why they fit, and how they could reduce your loans.")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.94))
                .fixedSize(horizontal: false, vertical: true)
                .shadow(color: LumaTheme.gradientTextShadow, radius: 2, y: 1)
        }
        .padding(16)
        .background {
            ZStack {
                LumaTheme.heroGradient
                LumaTheme.readableGradientOverlay.opacity(0.58)
            }
            .clipShape(RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
        }
        .overlay {
            RoundedRectangle(cornerRadius: LumaTheme.cardRadius)
                .stroke(.white.opacity(0.24), lineWidth: 1)
        }
        .shadow(color: LumaTheme.coral.opacity(0.18), radius: 18, y: 9)
    }

    private var lockedScholarshipPreview: some View {
        VStack(alignment: .leading, spacing: 16) {
            FeatureLock(
                title: "Unlock scholarship discovery",
                message: "Find school scholarships, merit aid, state grants, and program awards matched by LumaEngine.",
                feature: .scholarshipPlanning,
                action: { isShowingPaywall = true }
            )

            VStack(alignment: .leading, spacing: 12) {
                Text("What Pro adds")
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(LumaTheme.ink)

                lockedBenefit("School-specific scholarships", detail: "See where your saved schools may have institutional aid upside.")
                lockedBenefit("Merit and state aid", detail: "Use GPA, coursework, residency, and income to identify likely paths.")
                lockedBenefit("Program awards", detail: "Connect your selected course of study to department-level opportunities.")
            }
            .lumaCard(padding: 16, shadowOpacity: 0.24)

            LumaButton(title: "Unlock Pro", systemImage: "sparkles") {
                isShowingPaywall = true
            }
        }
    }

    private var profileNeededCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Complete your profile", systemImage: "person.crop.circle.badge.plus")
                .font(.title3.weight(.heavy))
                .foregroundStyle(LumaTheme.ink)

            Text("Scholarship matches need your residency, income, GPA, coursework, and preferences so LumaEngine can estimate realistic aid paths.")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(LumaTheme.slate)
                .fixedSize(horizontal: false, vertical: true)

            LumaButton(title: "Complete Profile", systemImage: "arrow.right") {
                isShowingProfile = true
            }
        }
        .lumaCard(padding: 16, shadowOpacity: 0.26)
    }

    private var savedSchoolsNeededCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Save schools to discover aid", systemImage: "bookmark")
                .font(.title3.weight(.heavy))
                .foregroundStyle(LumaTheme.ink)

            Text("Scholarship Discovery works best from your shortlist. Save schools from Explore, then return here to see school-specific and program-based opportunities.")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(LumaTheme.slate)
                .fixedSize(horizontal: false, vertical: true)
        }
        .lumaCard(padding: 16, shadowOpacity: 0.26)
    }

    private var scholarshipSummary: some View {
        let range = totalEstimatedRange
        let loanRange = totalLoanImpactRange

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Aid impact", systemImage: "sparkles")
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(LumaTheme.ink)

                Spacer()

                Text("\(opportunities.count) matches")
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(LumaTheme.coral)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 9)
                    .background(LumaTheme.coral.opacity(0.12), in: Capsule())
            }

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(rangeText(range))
                    .font(.system(size: 40, weight: .heavy))
                    .foregroundStyle(LumaTheme.valueGreen)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Text("/ year")
                    .font(.subheadline.weight(.heavy))
                    .foregroundStyle(LumaTheme.slate)
            }

            HStack(spacing: 10) {
                dataTile(
                    title: "Potential loan reduction",
                    value: rangeText(loanRange),
                    tint: LumaTheme.aqua
                )
                dataTile(
                    title: "Best match",
                    value: opportunities.first?.matchStrength.rawValue.replacingOccurrences(of: " match", with: "") ?? "None",
                    tint: LumaTheme.scoreGold
                )
            }

            Text("Estimate only. Confirm eligibility, deadlines, and award amounts with each scholarship provider.")
                .font(.caption.weight(.semibold))
                .foregroundStyle(LumaTheme.slate)
                .fixedSize(horizontal: false, vertical: true)
        }
        .lumaCard(padding: 16, shadowOpacity: 0.28)
    }

    private var financialPlanningWorkspace: some View {
        let summary = aidPlanningSummary

        return VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "chart.pie.fill")
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(LumaTheme.outcomeTeal, in: RoundedRectangle(cornerRadius: 12))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Aid planning workspace")
                        .font(.title3.weight(.heavy))
                        .foregroundStyle(LumaTheme.ink)

                    Text(summary.sourceDescription)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(LumaTheme.slate)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    planningSummaryTile(
                        title: "Estimated Cost",
                        value: summary.estimatedCost.formatted(LumaFormat.currency),
                        detail: "Annual school cost before aid.",
                        tint: LumaTheme.coral
                    )
                    planningSummaryTile(
                        title: "Monthly Repayment",
                        value: summary.monthlyRepayment.formatted(LumaFormat.currency),
                        detail: "Estimated payment on planned borrowing.",
                        tint: LumaTheme.aqua
                    )
                }

                HStack(spacing: 10) {
                    planningSummaryTile(
                        title: "Aid Received",
                        value: summary.aidReceived.formatted(LumaFormat.currency),
                        detail: "Grants plus family help.",
                        tint: LumaTheme.mint
                    )
                    planningSummaryTile(
                        title: "Amount to Borrow",
                        value: summary.amountToBorrow.formatted(LumaFormat.currency),
                        detail: "Remaining annual gap after aid.",
                        tint: LumaTheme.scorePurple
                    )
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                aidComponentRow(
                    title: "Grants",
                    value: summary.grants.formatted(LumaFormat.currency),
                    explanation: "Need-based or school aid that lowers cost and usually does not need repayment.",
                    tint: LumaTheme.mint,
                    systemImage: "gift.fill"
                )

                aidComponentRow(
                    title: "Scholarships",
                    value: summary.scholarships.formatted(LumaFormat.currency),
                    explanation: "Estimated merit, state, school, or program awards to verify before borrowing.",
                    tint: LumaTheme.sun,
                    systemImage: "sparkles"
                )

                aidComponentRow(
                    title: "Loans",
                    value: summary.loans.formatted(LumaFormat.currency),
                    explanation: "Borrowed money that drives the monthly repayment estimate.",
                    tint: LumaTheme.coral,
                    systemImage: "creditcard.fill"
                )

                aidComponentRow(
                    title: "Family Contribution",
                    value: summary.familyContribution.formatted(LumaFormat.currency),
                    explanation: "Planned family support from saved calculator inputs when available.",
                    tint: LumaTheme.outcomeTeal,
                    systemImage: "house.fill"
                )
            }

            Text("Estimated Cost - Grants - Scholarships - Family Contribution = Amount to Borrow. Monthly repayment uses the saved calculator plan when available, otherwise TuitionLuma estimates repayment from the borrowing gap.")
                .font(.caption.weight(.semibold))
                .foregroundStyle(LumaTheme.slate)
                .fixedSize(horizontal: false, vertical: true)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(LumaTheme.canvas.opacity(0.86), in: RoundedRectangle(cornerRadius: 14))
        }
        .lumaCard(padding: 16, shadowOpacity: 0.30)
    }

    private var priorityPlanCard: some View {
        let topActions = Array(opportunities.prefix(3))

        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "checklist.checked")
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(LumaTheme.coral)
                    .frame(width: 38, height: 38)
                    .background(LumaTheme.coral.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Your aid action plan")
                        .font(.title3.weight(.heavy))
                        .foregroundStyle(LumaTheme.ink)

                    Text("Start with the highest-fit aid paths and verify them before increasing loans.")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(LumaTheme.slate)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if topActions.isEmpty {
                Text("Save a school and complete your profile to build a personalized aid checklist.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(LumaTheme.slate)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                ForEach(Array(topActions.enumerated()), id: \.element.id) { index, opportunity in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(index + 1)")
                            .font(.caption.weight(.heavy))
                            .foregroundStyle(.white)
                            .frame(width: 24, height: 24)
                            .background(actionColor(for: opportunity).gradient, in: Circle())

                        VStack(alignment: .leading, spacing: 4) {
                            Text(opportunity.title)
                                .font(.subheadline.weight(.heavy))
                                .foregroundStyle(LumaTheme.ink)
                                .fixedSize(horizontal: false, vertical: true)

                            Text(opportunity.nextStep)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(LumaTheme.slate)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer(minLength: 8)

                        Text(rangeText(opportunity.estimatedAnnualMin...opportunity.estimatedAnnualMax))
                            .font(.caption.weight(.heavy))
                            .foregroundStyle(LumaTheme.valueGreen)
                            .padding(.vertical, 5)
                            .padding(.horizontal, 8)
                            .background(LumaTheme.valueGreen.opacity(0.10), in: Capsule())
                    }
                    .padding(12)
                    .background(actionColor(for: opportunity).opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                }
            }
        }
        .lumaCard(padding: 16, shadowOpacity: 0.26)
    }

    private var calculatorBridgeCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "function")
                .font(.headline.weight(.heavy))
                .foregroundStyle(LumaTheme.aqua)
                .frame(width: 38, height: 38)
                .background(LumaTheme.aqua.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text("Calculator updates your loan plan")
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(LumaTheme.ink)

                Text("Open Calculator to apply an aid estimate and see the monthly payment change before you borrow.")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(LumaTheme.slate)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .lumaCard(padding: 14, shadowOpacity: 0.22)
    }

    private var schoolMatchesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Matches for saved schools", subtitle: "Prioritized by fit, likely award size, and how much data LumaEngine can use.")

            ForEach(schoolSpecificOpportunities.prefix(8)) { opportunity in
                ScholarshipOpportunityCard(opportunity: opportunity)
            }
        }
    }

    private var generalAidSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("State and grant paths", subtitle: "Profile-based aid paths to verify before borrowing.")

            if generalOpportunities.isEmpty {
                Text("Add state residency and income to reveal state grant and need-based aid paths.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(LumaTheme.slate)
                    .lumaCard(padding: 16, shadowOpacity: 0.22)
            } else {
                ForEach(generalOpportunities.prefix(4)) { opportunity in
                    ScholarshipOpportunityCard(opportunity: opportunity)
                }
            }
        }
    }

    private var totalEstimatedRange: ClosedRange<Double> {
        let schoolOpportunities = schoolSpecificOpportunities
        let source = schoolOpportunities.isEmpty ? opportunities : schoolOpportunities
        let minAid = source.reduce(0) { $0 + $1.estimatedAnnualMin }
        let maxAid = source.reduce(0) { $0 + $1.estimatedAnnualMax }
        return minAid...maxAid
    }

    private var totalLoanImpactRange: ClosedRange<Double> {
        let years = 4.0
        return (totalEstimatedRange.lowerBound * years)...(totalEstimatedRange.upperBound * years)
    }

    private var aidPlanningSummary: AidPlanningSummary {
        let savedPlans = appViewModel.savedSchools.compactMap { appViewModel.savedAidPlan(for: $0) }

        if !savedPlans.isEmpty {
            let count = Double(savedPlans.count)
            let estimatedCost = savedPlans.reduce(0) { $0 + $1.annualCost } / count
            let grants = savedPlans.reduce(0) { $0 + $1.aidInput.grantsAndScholarships } / count
            let family = savedPlans.reduce(0) { $0 + $1.aidInput.familyContribution } / count
            let loans = savedPlans.reduce(0) { $0 + $1.aidInput.annualLoanAmount } / count
            let scholarships = planningScholarshipEstimate
            let amountToBorrow = max(0, loans)
            let monthly = savedPlans.reduce(0) { $0 + $1.monthlyPayment } / count

            return AidPlanningSummary(
                estimatedCost: estimatedCost,
                grants: grants,
                scholarships: scholarships,
                loans: loans,
                familyContribution: family,
                amountToBorrow: amountToBorrow,
                monthlyRepayment: monthly,
                sourceDescription: "Based on saved calculator aid plans across your shortlist."
            )
        }

        let schools = appViewModel.savedSchools
        let count = max(Double(schools.count), 1)
        let estimatedCost = schools.reduce(0) { $0 + $1.costEstimate.estimatedAnnualCost } / count
        let averageNetPrice = schools.reduce(0) { partial, school in
            let netPrice = school.costEstimate.averageNetPrice > 0 ? school.costEstimate.averageNetPrice : school.costEstimate.estimatedAnnualCost
            return partial + netPrice
        } / count
        let grants = max(0, estimatedCost - averageNetPrice)
        let scholarships = planningScholarshipEstimate
        let familyContribution = 0.0
        let amountToBorrow = max(0, estimatedCost - grants - scholarships - familyContribution)
        let monthly = CalculatorEngine.monthlyLoanPayment(
            principal: amountToBorrow * 4,
            annualInterestRate: AidInput.starter.interestRate,
            repaymentYears: 10
        )

        return AidPlanningSummary(
            estimatedCost: estimatedCost,
            grants: grants,
            scholarships: scholarships,
            loans: amountToBorrow,
            familyContribution: familyContribution,
            amountToBorrow: amountToBorrow,
            monthlyRepayment: monthly,
            sourceDescription: schools.isEmpty ? "Save schools to turn this into a live shortlist plan." : "Based on saved schools and estimated scholarship paths."
        )
    }

    private var planningScholarshipEstimate: Double {
        let range = totalEstimatedRange
        return max(0, (range.lowerBound + range.upperBound) / 2)
    }

    private func sectionHeader(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title3.weight(.heavy))
                .foregroundStyle(LumaTheme.ink)

            Text(subtitle)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(LumaTheme.slate)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func lockedBenefit(_ title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.subheadline.weight(.heavy))
                .foregroundStyle(LumaTheme.mint)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.heavy))
                    .foregroundStyle(LumaTheme.ink)

                Text(detail)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(LumaTheme.slate)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func dataTile(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.title3.weight(.heavy))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.78)

            Text(title)
                .font(.caption.weight(.heavy))
                .foregroundStyle(LumaTheme.slate)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 74, alignment: .leading)
        .padding(12)
        .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(tint.opacity(0.18))
        }
    }

    private func planningSummaryTile(title: String, value: String, detail: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value)
                .font(.title2.weight(.heavy))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Text(title)
                .font(.caption.weight(.heavy))
                .foregroundStyle(LumaTheme.ink)
                .fixedSize(horizontal: false, vertical: true)

            Text(detail)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(LumaTheme.slate)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 104, alignment: .leading)
        .padding(12)
        .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(tint.opacity(0.18))
        }
    }

    private func aidComponentRow(title: String, value: String, explanation: String, tint: Color, systemImage: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.heavy))
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(tint.opacity(0.13), in: RoundedRectangle(cornerRadius: 10))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(title)
                        .font(.subheadline.weight(.heavy))
                        .foregroundStyle(LumaTheme.ink)

                    Spacer(minLength: 8)

                    Text(value)
                        .font(.subheadline.weight(.heavy))
                        .foregroundStyle(tint)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }

                Text(explanation)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(LumaTheme.slate)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .background(tint.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))
    }

    private func actionColor(for opportunity: ScholarshipOpportunity) -> Color {
        switch opportunity.kind {
        case .schoolSpecific: LumaTheme.outcomeTeal
        case .merit: LumaTheme.scoreGold
        case .stateGrant: LumaTheme.aqua
        case .needBased: LumaTheme.mint
        case .program: LumaTheme.coral
        }
    }

    private func rangeText(_ range: ClosedRange<Double>) -> String {
        if range.upperBound <= 0 {
            return "$0"
        }

        if abs(range.lowerBound - range.upperBound) < 1 {
            return range.upperBound.formatted(LumaFormat.currency)
        }

        return "\(LumaFormat.compactCurrency(range.lowerBound))-\(LumaFormat.compactCurrency(range.upperBound))"
    }
}

private struct ScholarshipOpportunityCard: View {
    var opportunity: ScholarshipOpportunity

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: opportunity.kind.systemImage)
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(iconColor)
                    .frame(width: 40, height: 40)
                    .background(iconColor.opacity(0.14), in: RoundedRectangle(cornerRadius: 12))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(opportunity.title)
                        .font(.headline.weight(.heavy))
                        .foregroundStyle(LumaTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 6) {
                        Text(opportunity.matchStrength.rawValue)
                            .font(.caption.weight(.heavy))
                            .foregroundStyle(iconColor)
                            .padding(.vertical, 5)
                            .padding(.horizontal, 8)
                            .background(iconColor.opacity(0.12), in: Capsule())

                        Text(opportunity.kind.rawValue)
                            .font(.caption.weight(.heavy))
                            .foregroundStyle(LumaTheme.slate)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 8)
            }

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(rangeText)
                    .font(.title2.weight(.heavy))
                    .foregroundStyle(LumaTheme.valueGreen)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Text("estimated / year")
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(LumaTheme.slate)
            }

            Text(specificAidText)
                .font(.subheadline.weight(.heavy))
                .foregroundStyle(LumaTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, 8)
                .padding(.horizontal, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(iconColor.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))

            HStack(spacing: 10) {
                impactTile("4-year loan impact", value: fourYearLoanImpactText, tint: LumaTheme.aqua)
                impactTile("Verify", value: verificationLabel, tint: iconColor)
            }

            VStack(alignment: .leading, spacing: 7) {
                ForEach(opportunity.reasons.prefix(3), id: \.self) { reason in
                    Label(reason, systemImage: "checkmark")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(LumaTheme.slate)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Text(opportunity.nextStep)
                .font(.caption.weight(.semibold))
                .foregroundStyle(LumaTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(LumaTheme.canvas.opacity(0.86), in: RoundedRectangle(cornerRadius: 12))
        }
        .padding(16)
        .background(LumaTheme.card, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
        .overlay {
            RoundedRectangle(cornerRadius: LumaTheme.cardRadius)
                .stroke(iconColor.opacity(0.14), lineWidth: 1)
        }
        .shadow(color: LumaTheme.cardShadow.opacity(0.20), radius: 12, y: 6)
        .accessibilityElement(children: .combine)
    }

    private var iconColor: Color {
        switch opportunity.kind {
        case .schoolSpecific: LumaTheme.outcomeTeal
        case .merit: LumaTheme.sun
        case .stateGrant: LumaTheme.aqua
        case .needBased: LumaTheme.mint
        case .program: LumaTheme.coral
        }
    }

    private var specificAidText: String {
        switch opportunity.kind {
        case .schoolSpecific:
            if let school = opportunity.school {
                return "Look for \(school.name) first-year, transfer, and need-based scholarship pages."
            }
            return "Look for institutional scholarships from each saved school."
        case .merit:
            return "Merit path: GPA, test scores, AP/college coursework, and priority deadlines."
        case .stateGrant:
            return "State aid path: residency rules, state grant portal, and FAFSA timing."
        case .needBased:
            return "Grant path: FAFSA, institutional aid forms, and family income documentation."
        case .program:
            return "Program path: department scholarships tied to your selected course of study."
        }
    }

    private var rangeText: String {
        if abs(opportunity.estimatedAnnualMin - opportunity.estimatedAnnualMax) < 1 {
            return opportunity.estimatedAnnualMax.formatted(LumaFormat.currency)
        }

        return "\(LumaFormat.compactCurrency(opportunity.estimatedAnnualMin))-\(LumaFormat.compactCurrency(opportunity.estimatedAnnualMax))"
    }

    private var fourYearLoanImpactText: String {
        let minImpact = opportunity.estimatedAnnualMin * 4
        let maxImpact = opportunity.estimatedAnnualMax * 4
        if abs(minImpact - maxImpact) < 1 {
            return LumaFormat.compactCurrency(maxImpact)
        }

        return "\(LumaFormat.compactCurrency(minImpact))-\(LumaFormat.compactCurrency(maxImpact))"
    }

    private var verificationLabel: String {
        switch opportunity.kind {
        case .schoolSpecific: "Aid office"
        case .merit: "GPA rules"
        case .stateGrant: "State portal"
        case .needBased: "FAFSA"
        case .program: "Department"
        }
    }

    private func impactTile(_ title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.subheadline.weight(.heavy))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.78)

            Text(title)
                .font(.caption2.weight(.heavy))
                .foregroundStyle(LumaTheme.slate)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
        .padding(10)
        .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct AidPlanningSummary {
    var estimatedCost: Double
    var grants: Double
    var scholarships: Double
    var loans: Double
    var familyContribution: Double
    var amountToBorrow: Double
    var monthlyRepayment: Double
    var sourceDescription: String

    var aidReceived: Double {
        grants + scholarships + familyContribution
    }
}
