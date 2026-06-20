import SwiftUI

struct CostBreakdownCard: View {
    var cost: CostEstimate

    private struct CostRow: Identifiable {
        var component: CostComponent
        var title: String
        var value: Double?
        var tint: Color

        var id: CostComponent { component }
    }

    private var rows: [CostRow] {
        var rows = [
            CostRow(component: .tuitionAndFees, title: "In-state tuition", value: cost.tuitionAndFees, tint: LumaTheme.valueGreen),
            CostRow(component: .outOfStateTuition, title: "Out-of-state tuition", value: cost.outOfStateTuition, tint: LumaTheme.outcomeTeal),
            CostRow(component: .housingAndMeals, title: "Housing and meals", value: cost.housingAndMeals, tint: LumaTheme.sun),
            CostRow(component: .booksAndSupplies, title: "Books and supplies", value: cost.booksAndSupplies, tint: LumaTheme.aqua),
            CostRow(component: .transportation, title: "Transportation", value: cost.transportation, tint: LumaTheme.mint),
            CostRow(component: .personalExpenses, title: "Personal expenses", value: cost.personalExpenses, tint: LumaTheme.slate)
        ]

        if cost.outOfStateTuition == nil {
            rows.removeAll { $0.component == .outOfStateTuition }
        }

        return rows
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("School cost estimate")
                        .font(.title3.weight(.heavy))
                        .foregroundStyle(LumaTheme.ink)

                    Text("School-wide estimate before your personal aid or planning inputs.")
                        .font(.caption)
                        .foregroundStyle(LumaTheme.slate)
                }

                Spacer()

                Text(moneyText(cost.estimatedAnnualCost))
                    .font(.system(size: 30, weight: .heavy))
                    .foregroundStyle(LumaTheme.valueGreen)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .padding(14)
            .background(LumaTheme.valueGreen.opacity(0.08), in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
            .overlay {
                RoundedRectangle(cornerRadius: LumaTheme.cardRadius)
                    .stroke(LumaTheme.valueGreen.opacity(0.18))
            }

            VStack(spacing: 10) {
                ForEach(rows) { row in
                    costRow(row)
                }
            }

            HStack {
                Label("Avg aid", systemImage: "sparkles")
                    .foregroundStyle(LumaTheme.slate)

                Spacer()

                HStack(spacing: 6) {
                    if cost.isEstimated(.averageGrantAid) {
                        estimateBadge
                    }

                    Text(moneyText(cost.averageGrantAid))
                        .fontWeight(.bold)
                        .foregroundStyle(LumaTheme.mint)
                }
            }
            .font(.subheadline)
            .padding(12)
            .background(LumaTheme.mint.opacity(0.16), in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
            .overlay {
                RoundedRectangle(cornerRadius: LumaTheme.cardRadius)
                    .stroke(LumaTheme.mint.opacity(0.22))
            }

            if cost.hasEstimatedComponents {
                Label("Estimated rows use reported College Scorecard data where available, then TuitionLuma planning assumptions for missing line items.", systemImage: "info.circle.fill")
                    .font(.caption)
                    .foregroundStyle(LumaTheme.slate)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(18)
        .background(LumaTheme.card, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
        .overlay {
            RoundedRectangle(cornerRadius: LumaTheme.cardRadius)
                .stroke(LumaTheme.cardStroke)
        }
        .shadow(color: LumaTheme.cardShadow.opacity(0.78), radius: 18, y: 10)
    }

    private func costRow(_ row: CostRow) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(row.tint)
                .frame(width: 10, height: 10)

            Text(row.title)
                .fontWeight(.medium)
                .foregroundStyle(LumaTheme.slate)

            if cost.isEstimated(row.component) {
                estimateBadge
            }

            Spacer()

            Text(moneyText(row.value))
                .fontWeight(.heavy)
                .foregroundStyle((row.value ?? 0) > 0 ? LumaTheme.ink : LumaTheme.slate)
        }
        .font(.subheadline)
    }

    private var estimateBadge: some View {
        Text("est.")
            .font(.caption2.weight(.heavy))
            .foregroundStyle(LumaTheme.outcomeTeal)
            .padding(.vertical, 3)
            .padding(.horizontal, 6)
            .background(LumaTheme.aqua.opacity(0.12), in: Capsule())
    }

    private func moneyText(_ value: Double?) -> String {
        guard let value, value > 0 else {
            return "Not reported"
        }

        return value.formatted(LumaFormat.currency)
    }
}
