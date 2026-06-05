import SwiftUI

struct SchoolCard: View {
    var school: School
    var isSaved: Bool
    var onSaveTapped: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: LumaTheme.cardRadius)
                        .fill(LumaTheme.heroGradient)

                    Text(school.state)
                        .font(.headline.weight(.heavy))
                        .foregroundStyle(.white)
                }
                .frame(width: 54, height: 54)

                VStack(alignment: .leading, spacing: 5) {
                    Text(school.name)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(LumaTheme.ink)
                        .lineLimit(2)

                    Text("\(school.city), \(school.state) • \(school.type.rawValue)")
                        .font(.subheadline)
                        .foregroundStyle(LumaTheme.slate)
                        .lineLimit(1)
                }

                Spacer()

                Button(action: onSaveTapped) {
                    Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                        .font(.headline)
                        .foregroundStyle(isSaved ? LumaTheme.coral : LumaTheme.slate)
                        .frame(width: 36, height: 36)
                        .background(.black.opacity(0.04), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isSaved ? "Remove saved school" : "Save school")
            }

            Text(school.campusVibe)
                .font(.subheadline)
                .foregroundStyle(LumaTheme.slate)
                .lineLimit(2)

            HStack {
                StatPill(
                    title: "Net price",
                    value: LumaFormat.compactCurrency(school.costEstimate.averageNetPrice),
                    systemImage: "dollarsign",
                    tint: LumaTheme.mint
                )

                StatPill(
                    title: "Earnings",
                    value: LumaFormat.compactCurrency(school.medianEarnings),
                    systemImage: "chart.line.uptrend.xyaxis",
                    tint: LumaTheme.aqua
                )
            }
        }
        .padding(16)
        .background(LumaTheme.card, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
        .overlay {
            RoundedRectangle(cornerRadius: LumaTheme.cardRadius)
                .stroke(.black.opacity(0.06))
        }
        .shadow(color: .black.opacity(0.06), radius: 16, y: 8)
    }
}
