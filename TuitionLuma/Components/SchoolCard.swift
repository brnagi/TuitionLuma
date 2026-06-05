import SwiftUI

struct SchoolCard: View {
    var school: School
    var isSaved: Bool
    var isCompared: Bool
    var onSaveTapped: () -> Void
    var onCompareTapped: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header
            score
            metricRow

            Text(school.campusVibe)
                .font(.subheadline)
                .foregroundStyle(LumaTheme.slate)
                .lineLimit(2)
        }
        .padding(18)
        .background(LumaTheme.card, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
        .overlay {
            RoundedRectangle(cornerRadius: LumaTheme.cardRadius)
                .stroke(.black.opacity(0.06))
        }
        .shadow(color: .black.opacity(0.05), radius: 14, y: 7)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: LumaTheme.cardRadius)
                    .fill(LumaTheme.coolGradient)

                Text(school.state)
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(.white)
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 6) {
                Text(school.name)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(LumaTheme.ink)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text("\(school.city), \(school.state) • \(school.type.rawValue)")
                    .font(.subheadline)
                    .foregroundStyle(LumaTheme.slate)
                    .lineLimit(1)
            }
            .layoutPriority(1)

            Spacer()

            HStack(spacing: 6) {
                iconButton(
                    systemImage: isCompared ? "checkmark.circle.fill" : "plus.circle",
                    tint: isCompared ? LumaTheme.scorePurple : LumaTheme.slate,
                    label: isCompared ? "Remove school from compare" : "Compare school",
                    action: onCompareTapped
                )

                iconButton(
                    systemImage: isSaved ? "bookmark.fill" : "bookmark",
                    tint: isSaved ? LumaTheme.valueGreen : LumaTheme.slate,
                    label: isSaved ? "Remove saved school" : "Save school",
                    action: onSaveTapped
                )
            }
        }
    }

    private var score: some View {
        HStack(alignment: .firstTextBaseline, spacing: 14) {
            Text("\(school.lumaScore)")
                .font(.system(size: 54, weight: .heavy))
                .foregroundStyle(scoreTint)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            VStack(alignment: .leading, spacing: 4) {
                Text("/100")
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(LumaTheme.slate)

                Text(school.valueLabel)
                    .font(.subheadline.weight(.heavy))
                    .foregroundStyle(LumaTheme.ink)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var metricRow: some View {
        HStack(spacing: 0) {
            compactMetric(
                title: "Net",
                value: LumaFormat.compactCurrency(school.costEstimate.averageNetPrice),
                tint: netPriceTint
            )

            Divider()
                .frame(height: 34)

            compactMetric(
                title: "Earn",
                value: LumaFormat.compactCurrency(school.medianEarnings),
                tint: LumaTheme.outcomeTeal
            )

            Divider()
                .frame(height: 34)

            compactMetric(
                title: "Grad",
                value: school.graduationRate.formatted(LumaFormat.percent),
                tint: LumaTheme.outcomeTeal
            )
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 4)
        .background(.black.opacity(0.025), in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
    }

    private var scoreTint: Color {
        school.lumaScore >= 90 ? LumaTheme.scoreGold : LumaTheme.scorePurple
    }

    private var netPriceTint: Color {
        school.costEstimate.averageNetPrice > 45_000 ? LumaTheme.warningOrange : LumaTheme.valueGreen
    }

    private func compactMetric(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .center, spacing: 4) {
            Text(value)
                .font(.headline.weight(.heavy))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(LumaTheme.slate)
        }
        .frame(maxWidth: .infinity)
    }

    private func iconButton(systemImage: String, tint: Color, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.headline.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(.black.opacity(0.04), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
