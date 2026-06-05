import SwiftUI

struct CostBreakdownCard: View {
    var cost: CostEstimate

    private var rows: [(String, Double, Color)] {
        [
            ("Tuition and fees", cost.tuitionAndFees, LumaTheme.coral),
            ("Housing and meals", cost.housingAndMeals, LumaTheme.sun),
            ("Books and supplies", cost.booksAndSupplies, LumaTheme.aqua),
            ("Transportation", cost.transportation, LumaTheme.mint),
            ("Personal expenses", cost.personalExpenses, LumaTheme.slate)
        ]
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

                Text(cost.annualStickerCost.formatted(LumaFormat.currency))
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

                        Text(row.1.formatted(LumaFormat.currency))
                            .fontWeight(.semibold)
                            .foregroundStyle(LumaTheme.ink)
                    }
                    .font(.subheadline)
                }
            }

            HStack {
                Label("Avg aid", systemImage: "sparkles")
                    .foregroundStyle(LumaTheme.slate)

                Spacer()

                Text(cost.averageGrantAid.formatted(LumaFormat.currency))
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
}
