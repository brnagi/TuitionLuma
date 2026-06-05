import SwiftUI

struct SchoolCard: View {
    var school: School
    var isSaved: Bool
    var isCompared: Bool
    var onSaveTapped: () -> Void
    var onCompareTapped: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: LumaTheme.cardRadius)
                        .fill(LumaTheme.coolGradient)

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
                    VStack(spacing: 4) {
                        Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                            .font(.headline.weight(.bold))

                        Text(isSaved ? "Saved" : "Save")
                            .font(.caption2.weight(.heavy))
                    }
                    .foregroundStyle(isSaved ? .white : LumaTheme.slate)
                    .frame(width: 54, height: 50)
                    .background(isSaved ? AnyShapeStyle(LumaTheme.valueGreen) : AnyShapeStyle(.black.opacity(0.04)), in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isSaved ? "Remove saved school" : "Save school")
            }

            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(school.lumaScore)/100")
                        .font(.title.weight(.heavy))
                        .foregroundStyle(LumaTheme.ink)
                        .lineLimit(1)

                    Text(school.valueLabel)
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(scoreTint)
                        .lineLimit(1)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("TuitionLuma Score")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(LumaTheme.slate)

                    HStack(spacing: 5) {
                        Image(systemName: "sparkles")
                        Text(scoreTone)
                    }
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(.white)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 9)
                    .background(scoreTint, in: Capsule())
                }
            }
            .padding(14)
            .background(scoreTint.opacity(0.10), in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))

            HStack(spacing: 10) {
                valueMetric(
                    title: "Net Price",
                    value: LumaFormat.compactCurrency(school.costEstimate.averageNetPrice),
                    systemImage: "dollarsign.circle.fill",
                    tint: netPriceTint
                )

                valueMetric(
                    title: "Earnings",
                    value: LumaFormat.compactCurrency(school.medianEarnings),
                    systemImage: "chart.line.uptrend.xyaxis.circle.fill",
                    tint: LumaTheme.outcomeTeal
                )
            }

            HStack(spacing: 10) {
                StatPill(
                    title: "Graduation Rate",
                    value: school.graduationRate.formatted(LumaFormat.percent),
                    systemImage: "graduationcap.fill",
                    tint: LumaTheme.outcomeTeal
                )

                Button(action: onCompareTapped) {
                    HStack(spacing: 7) {
                        Image(systemName: isCompared ? "checkmark.circle.fill" : "plus.circle.fill")
                            .font(.subheadline.weight(.bold))

                        Text(isCompared ? "Compared" : "Compare")
                            .font(.subheadline.weight(.heavy))
                    }
                    .foregroundStyle(isCompared ? .white : LumaTheme.scorePurple)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(isCompared ? AnyShapeStyle(LumaTheme.scorePurple) : AnyShapeStyle(LumaTheme.scorePurple.opacity(0.12)), in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isCompared ? "School added to compare" : "Compare school")
            }

            Text(school.campusVibe)
                .font(.subheadline)
                .foregroundStyle(LumaTheme.slate)
                .lineLimit(2)
        }
        .padding(16)
        .background(LumaTheme.card, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
        .overlay {
            RoundedRectangle(cornerRadius: LumaTheme.cardRadius)
                .stroke(.black.opacity(0.06))
        }
        .shadow(color: .black.opacity(0.06), radius: 16, y: 8)
    }

    private var scoreTint: Color {
        school.lumaScore >= 90 ? LumaTheme.scoreGold : LumaTheme.scorePurple
    }

    private var scoreTone: String {
        school.lumaScore >= 90 ? "Top Pick" : "Value"
    }

    private var netPriceTint: Color {
        school.costEstimate.averageNetPrice > 45_000 ? LumaTheme.warningOrange : LumaTheme.valueGreen
    }

    private func valueMetric(title: String, value: String, systemImage: String, tint: Color) -> some View {
        HStack(alignment: .center, spacing: 9) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(tint)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title2.weight(.heavy))
                    .foregroundStyle(LumaTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(LumaTheme.slate)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(tint.opacity(0.11), in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
    }
}
