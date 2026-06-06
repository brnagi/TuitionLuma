import SwiftUI

struct CostBreakdownCard: View {
    var cost: CostEstimate

    private var rows: [(String, String, Color)] {
        var rows = [
            ("In-state tuition", moneyText(cost.tuitionAndFees), LumaTheme.valueGreen),
            ("Out-of-state tuition", moneyText(cost.outOfStateTuition), LumaTheme.outcomeTeal),
            ("Housing and meals", moneyText(cost.housingAndMeals), LumaTheme.sun),
            ("Books and supplies", moneyText(cost.booksAndSupplies), LumaTheme.aqua),
            ("Transportation", moneyText(cost.transportation), LumaTheme.mint),
            ("Personal expenses", moneyText(cost.personalExpenses), LumaTheme.slate)
        ]

        if cost.outOfStateTuition == nil {
            rows.removeAll { $0.0 == "Out-of-state tuition" }
        }

        return rows
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Estimated annual cost")
                        .font(.headline)
                        .foregroundStyle(LumaTheme.ink)

                    Text("Before grants, scholarships, or family contributions.")
                        .font(.caption)
                        .foregroundStyle(LumaTheme.slate)
                }

                Spacer()

                Text(moneyText(cost.estimatedAnnualCost))
                    .font(.title2.weight(.heavy))
                    .foregroundStyle(LumaTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }

            VStack(spacing: 10) {
                ForEach(rows, id: \.0) { row in
                    HStack(spacing: 10) {
                        Circle()
                            .fill(row.2)
                            .frame(width: 10, height: 10)

                        Text(row.0)
                            .foregroundStyle(LumaTheme.slate)

                        Spacer()

                        Text(row.1)
                            .fontWeight(.semibold)
                            .foregroundStyle(row.1 == "Not reported" ? LumaTheme.slate : LumaTheme.ink)
                    }
                    .font(.subheadline)
                }
            }

            HStack {
                Label("Avg aid", systemImage: "sparkles")
                    .foregroundStyle(LumaTheme.slate)

                Spacer()

                Text(moneyText(cost.averageGrantAid))
                    .fontWeight(.bold)
                    .foregroundStyle(LumaTheme.mint)
            }
            .font(.subheadline)
            .padding(12)
            .background(LumaTheme.mint.opacity(0.12), in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
        }
        .padding(18)
        .background(LumaTheme.card, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
        .overlay {
            RoundedRectangle(cornerRadius: LumaTheme.cardRadius)
                .stroke(.black.opacity(0.06))
        }
    }

    private func moneyText(_ value: Double?) -> String {
        guard let value, value > 0 else {
            return "Not reported"
        }

        return value.formatted(LumaFormat.currency)
    }
}
