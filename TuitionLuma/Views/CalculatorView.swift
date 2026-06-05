import SwiftUI

struct CalculatorView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @StateObject private var viewModel = CalculatorViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    schoolPicker
                    headlineNumbers
                    aidInputs
                    repaymentCard
                }
                .padding()
            }
            .background(LumaTheme.canvas)
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

            Picker("Choose a school", selection: $viewModel.selectedSchool) {
                ForEach(appViewModel.schools) { school in
                    Text(school.name).tag(school)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
        }
    }

    private var headlineNumbers: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Your estimated price")
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.netAnnualCost.formatted(LumaFormat.currency))
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
                    Text(viewModel.netTotalCost.formatted(LumaFormat.currency))
                        .font(.title2.weight(.heavy))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)

                    Text("\(viewModel.aidInput.yearsInSchool)-year total")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.86))
                }
            }

            Text("This subtracts grants, scholarships, family help, and work-study from the annual sticker price.")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.88))
        }
        .padding(20)
        .background(LumaTheme.heroGradient, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
    }

    private var aidInputs: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Aid and borrowing")
                .font(.title3.weight(.bold))
                .foregroundStyle(LumaTheme.ink)

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
}
