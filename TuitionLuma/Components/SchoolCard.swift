import SwiftUI

struct SchoolCard: View {
    var school: School
    var isSaved: Bool
    var isCompared: Bool
    var onSaveTapped: () -> Void
    var onCompareTapped: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            campusImage

            VStack(alignment: .leading, spacing: 14) {
                titleBlock
                valueBadge
                metricRow

                Text(school.campusVibe)
                    .font(.subheadline)
                    .foregroundStyle(LumaTheme.slate)
                    .lineLimit(2)
            }
            .padding(18)
            .background(.white.opacity(0.97), in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
            .padding(.horizontal, 10)
            .padding(.bottom, 10)
        }
        .background {
            StateFlagBackdrop(style: stateFlagStyle)
                .clipShape(RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
        }
        .overlay {
            RoundedRectangle(cornerRadius: LumaTheme.cardRadius)
                .stroke(.black.opacity(0.06))
        }
        .shadow(color: .black.opacity(0.06), radius: 16, y: 8)
    }

    private var campusImage: some View {
        ZStack(alignment: .topLeading) {
            stateFlagHero

            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    schoolTypeBadge

                    Spacer(minLength: 12)

                    actionButtons
                }
            }
            .padding(16)
        }
        .frame(height: 174)
        .clipShape(RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
        .padding(10)
        .padding(.bottom, -4)
    }

    private var schoolTypeBadge: some View {
        HStack(spacing: 7) {
            Image(systemName: school.type == .publicUniversity || school.type == .communityCollege ? "building.columns.fill" : "sparkle")
                .font(.caption.weight(.bold))

            Text(school.type.rawValue)
                .font(.subheadline.weight(.heavy))
        }
        .foregroundStyle(LumaTheme.ink)
        .padding(.vertical, 9)
        .padding(.horizontal, 12)
        .background(.white.opacity(0.92), in: Capsule())
        .shadow(color: .black.opacity(0.10), radius: 8, y: 4)
    }

    private var actionButtons: some View {
        HStack(spacing: 8) {
            labeledActionButton(
                title: isCompared ? "Added" : "Compare",
                systemImage: isCompared ? "checkmark.circle.fill" : "plus.circle",
                tint: isCompared ? LumaTheme.scorePurple : LumaTheme.ink,
                accessibilityLabel: isCompared ? "Remove school from compare" : "Compare school",
                action: onCompareTapped
            )

            labeledActionButton(
                title: isSaved ? "Saved" : "Save",
                systemImage: isSaved ? "bookmark.fill" : "bookmark",
                tint: isSaved ? LumaTheme.valueGreen : LumaTheme.ink,
                accessibilityLabel: isSaved ? "Remove saved school" : "Save school",
                action: onSaveTapped
            )
        }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(school.name)
                .font(.title2.weight(.heavy))
                .foregroundStyle(LumaTheme.ink)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Text("\(school.city), \(school.state)")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(LumaTheme.slate)
                .lineLimit(1)
        }
    }

    private var valueBadge: some View {
        HStack(spacing: 7) {
            Image(systemName: "star.fill")
                .font(.caption.weight(.bold))

            Text("\(school.valueLabel) • \(school.lumaScore)")
                .font(.caption.weight(.heavy))
                .lineLimit(1)
        }
        .foregroundStyle(scoreTint)
        .padding(.vertical, 7)
        .padding(.horizontal, 10)
        .background(scoreTint.opacity(0.10), in: Capsule())
    }

    private var metricRow: some View {
        HStack(spacing: 0) {
            compactMetric(
                title: "Net Price",
                value: school.costEstimate.averageNetPrice > 0 ? LumaFormat.compactCurrency(school.costEstimate.averageNetPrice) : "N/A",
                tint: netPriceTint
            )

            Divider()
                .frame(height: 32)

            compactMetric(
                title: "Earnings",
                value: school.medianEarnings > 0 ? LumaFormat.compactCurrency(school.medianEarnings) : "N/A",
                tint: LumaTheme.outcomeTeal
            )

            Divider()
                .frame(height: 32)

            compactMetric(
                title: "Grad Rate",
                value: school.graduationRate > 0 ? school.graduationRate.formatted(LumaFormat.percent) : "N/A",
                tint: LumaTheme.outcomeTeal
            )
        }
        .padding(.vertical, 12)
        .background(.black.opacity(0.025), in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
    }

    private var stateFlagHero: some View {
        StateFlagBackdrop(style: stateFlagStyle)
            .overlay(.black.opacity(0.04))
    }

    private var scoreTint: Color {
        switch school.valueLabel {
        case "Excellent Value":
            LumaTheme.valueGreen
        case "Good Value":
            LumaTheme.outcomeTeal
        case "Fair Value":
            LumaTheme.scoreGold
        case "Expensive":
            LumaTheme.warningOrange
        default:
            LumaTheme.scorePurple
        }
    }

    private var netPriceTint: Color {
        school.costEstimate.averageNetPrice > 45_000 ? LumaTheme.warningOrange : LumaTheme.valueGreen
    }

    private var stateFlagStyle: StateFlagStyle {
        StateFlagStyles.style(for: school.state)
    }

    private func compactMetric(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.headline.weight(.heavy))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(LumaTheme.slate)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
    }

    private func labeledActionButton(
        title: String,
        systemImage: String,
        tint: Color,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.semibold))

                Text(title)
                    .font(.caption.weight(.heavy))
            }
            .foregroundStyle(tint)
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(.white.opacity(0.94), in: Capsule())
            .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

private struct StateFlagBackdrop: View {
    var style: StateFlagStyle

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height

            ZStack {
                HStack(spacing: 0) {
                    primaryColor
                        .frame(width: width * 0.36)

                    VStack(spacing: 0) {
                        secondaryColor
                        accentColor
                    }
                }

                LinearGradient(
                    colors: [.white.opacity(0.08), .clear, .black.opacity(0.14)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Image(systemName: style.emblemSystemImage)
                    .font(.system(size: 76, weight: .heavy))
                    .foregroundStyle(.white.opacity(0.28))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .padding(.leading, width * 0.12)

                RoundedRectangle(cornerRadius: LumaTheme.cardRadius)
                    .stroke(.white.opacity(0.20), lineWidth: 1)
                    .padding(1)
            }
            .frame(width: width, height: height)
        }
        .accessibilityHidden(true)
    }

    private var primaryColor: Color {
        LumaTheme.color(hex: style.primaryHex, fallback: LumaTheme.aqua)
    }

    private var secondaryColor: Color {
        LumaTheme.color(hex: style.secondaryHex, fallback: LumaTheme.mint)
    }

    private var accentColor: Color {
        LumaTheme.color(hex: style.accentHex, fallback: .white)
    }
}
