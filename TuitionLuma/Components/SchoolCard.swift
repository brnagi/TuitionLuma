import SwiftUI

struct SchoolCard: View {
    var school: School
    var recommendation: ProfileRecommendation? = nil
    var isSaved: Bool
    var isCompared: Bool
    var coachMarkHighlight: ExploreCoachMarkTarget? = nil
    var onSaveTapped: () -> Void
    var onCompareTapped: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            campusImage

            VStack(alignment: .leading, spacing: 12) {
                controlRow
                titleBlock

                if let recommendation {
                    personalizedRecommendation(recommendation)
                } else {
                    valueBadge
                }

                metricRow

                Text(school.campusVibe)
                    .font(.subheadline)
                    .foregroundStyle(LumaTheme.slate)
                    .lineLimit(2)
            }
            .padding(18)
        }
        .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
        .clipShape(RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
        .overlay {
            RoundedRectangle(cornerRadius: LumaTheme.cardRadius)
                .stroke(LumaTheme.cardStroke)
        }
        .shadow(color: LumaTheme.cardShadow, radius: 22, y: 12)
    }

    private var campusImage: some View {
        valueSignalHero
            .frame(maxWidth: .infinity)
            .frame(height: 124)
            .clipped()
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Value signal")
            .accessibilityValue("\(valueSignalTitle), Luma Score \(school.lumaScore)")
    }

    private var controlRow: some View {
        HStack(alignment: .center, spacing: 10) {
            schoolTypeBadge

            Spacer(minLength: 8)

            actionButtons
        }
    }

    private var schoolTypeBadge: some View {
        HStack(spacing: 7) {
            Image(systemName: school.type == .publicUniversity || school.type == .communityCollege ? "building.columns.fill" : "sparkle")
                .font(.caption.weight(.bold))

            Text(school.type.rawValue)
                .font(.subheadline.weight(.heavy))
        }
        .foregroundStyle(.white)
        .padding(.vertical, 9)
        .padding(.horizontal, 12)
        .background(LumaTheme.ink, in: Capsule())
    }

    private var actionButtons: some View {
        HStack(spacing: 8) {
            labeledActionButton(
                title: isCompared ? "Added" : "Compare",
                systemImage: isCompared ? "checkmark.circle.fill" : "plus.circle",
                tint: isCompared ? LumaTheme.scorePurple : LumaTheme.ink,
                accessibilityLabel: isCompared ? "Remove school from compare" : "Compare school",
                isHighlighted: coachMarkHighlight == .compare,
                action: onCompareTapped
            )

            labeledActionButton(
                title: isSaved ? "Saved" : "Save",
                systemImage: isSaved ? "bookmark.fill" : "bookmark",
                tint: isSaved ? LumaTheme.valueGreen : LumaTheme.ink,
                accessibilityLabel: isSaved ? "Remove saved school" : "Save school",
                isHighlighted: coachMarkHighlight == .save,
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
        .background(scoreTint.opacity(0.15), in: Capsule())
        .overlay {
            Capsule()
                .stroke(scoreTint.opacity(0.20))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("TuitionLuma score")
        .accessibilityValue("\(school.lumaScore), \(school.valueLabel)")
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
        .background(LumaTheme.canvas.opacity(0.85), in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
        .overlay {
            RoundedRectangle(cornerRadius: LumaTheme.cardRadius)
                .stroke(LumaTheme.cardStroke.opacity(0.55))
        }
        .accessibilityElement(children: .contain)
    }

    private func personalizedRecommendation(_ recommendation: ProfileRecommendation) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(.white)
                    .frame(width: 26, height: 26)
                    .background(recommendationTint(for: recommendation).gradient, in: Circle())
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    Text(recommendation.fitLabel)
                        .font(.subheadline.weight(.heavy))
                        .foregroundStyle(LumaTheme.ink)

                    Text(recommendation.summary)
                        .font(.caption)
                        .foregroundStyle(LumaTheme.slate)
                        .lineLimit(2)
                }
            }

            HStack(spacing: 10) {
                recommendationMetric(
                    title: "Estimated net cost",
                    value: recommendation.estimatedNetCost.formatted(LumaFormat.currency),
                    tint: affordabilityTint(for: recommendation.affordability)
                )

                recommendationMetric(
                    title: "ROI score",
                    value: recommendation.roiGrade,
                    tint: recommendationTint(for: recommendation)
                )
            }

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(recommendation.affordability.rawValue)
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(affordabilityTint(for: recommendation.affordability))

                Text(recommendation.affordability.explanation)
                    .font(.caption)
                    .foregroundStyle(LumaTheme.slate)
                    .lineLimit(2)
            }
        }
        .padding(14)
        .background(recommendationTint(for: recommendation).opacity(0.11), in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
        .overlay {
            RoundedRectangle(cornerRadius: LumaTheme.cardRadius)
                .stroke(recommendationTint(for: recommendation).opacity(0.24))
        }
    }

    private var valueSignalHero: some View {
        ZStack {
            LinearGradient(
                colors: [
                    scoreTint.opacity(0.96),
                    scoreTint.opacity(0.68),
                    LumaTheme.ink.opacity(0.92)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [.white.opacity(0.20), .clear],
                center: .topLeading,
                startRadius: 20,
                endRadius: 220
            )

            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 7) {
                    Text(valueSignalTitle)
                        .font(.title2.weight(.heavy))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Text(valueSignalSubtitle)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.84))
                        .lineLimit(2)
                }

                Spacer()

                VStack(spacing: 0) {
                    Text("\(school.lumaScore)")
                        .font(.system(size: 38, weight: .heavy))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text("LumaScore")
                        .font(.caption2.weight(.heavy))
                        .foregroundStyle(.white.opacity(0.82))
                }
                .frame(width: 74, height: 74)
                .background(.white.opacity(0.18), in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
                .overlay {
                    RoundedRectangle(cornerRadius: LumaTheme.cardRadius)
                        .stroke(.white.opacity(0.20))
                }
            }
            .padding(18)
        }
    }

    private var valueSignalTitle: String {
        if school.valueLabel == "Expensive" {
            return "High Risk"
        }

        return school.valueLabel
    }

    private var valueSignalSubtitle: String {
        switch valueSignalTitle {
        case "Excellent Value":
            "Strong cost and outcome signal"
        case "Good Value":
            "Worth a closer look"
        case "Fair Value":
            "Compare aid and debt carefully"
        case "High Risk":
            "Watch cost, debt, and payoff"
        default:
            "Compare value before deciding"
        }
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
                .lineLimit(2)

            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(LumaTheme.slate)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(value)
    }

    private func recommendationMetric(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value)
                .font(.headline.weight(.heavy))
                .foregroundStyle(tint)
                .lineLimit(2)

            Text(title)
                .font(.caption2.weight(.bold))
                .foregroundStyle(LumaTheme.slate)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.white.opacity(0.88), in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
        .overlay {
            RoundedRectangle(cornerRadius: LumaTheme.cardRadius)
                .stroke(tint.opacity(0.16))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(value)
    }

    private func recommendationTint(for recommendation: ProfileRecommendation) -> Color {
        switch recommendation.roiGrade {
        case "A":
            LumaTheme.valueGreen
        case "B+", "B":
            LumaTheme.outcomeTeal
        case "C+":
            LumaTheme.scoreGold
        default:
            LumaTheme.warningOrange
        }
    }

    private func affordabilityTint(for affordability: AffordabilityClassification) -> Color {
        switch affordability {
        case .affordable:
            LumaTheme.valueGreen
        case .stretch:
            LumaTheme.scoreGold
        case .highRisk:
            LumaTheme.warningOrange
        }
    }

    private func labeledActionButton(
        title: String,
        systemImage: String,
        tint: Color,
        accessibilityLabel: String,
        isHighlighted: Bool = false,
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
            .frame(minHeight: 44)
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(isHighlighted ? LumaTheme.coral.opacity(0.13) : .white, in: Capsule())
            .overlay {
                Capsule()
                    .stroke(isHighlighted ? LumaTheme.coral : tint.opacity(0.28), lineWidth: isHighlighted ? 3 : 1)
            }
            .shadow(
                color: isHighlighted ? LumaTheme.coral.opacity(0.38) : .black.opacity(0.07),
                radius: isHighlighted ? 14 : 6,
                y: isHighlighted ? 6 : 3
            )
            .scaleEffect(isHighlighted ? 1.04 : 1)
            .animation(.easeInOut(duration: 0.18), value: isHighlighted)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(title)
        .accessibilityHint(title == "Added" || title == "Saved" ? "Double tap to remove." : "Double tap to add.")
        .accessibilityAddTraits(.isButton)
    }

}

private struct StateFlagBackdrop: View {
    var style: StateFlagStyle

    var body: some View {
        AsyncImage(url: flagURL) { phase in
            switch phase {
            case .success(let image):
                GeometryReader { proxy in
                    ZStack {
                        flagBackground

                        image
                            .resizable()
                            .interpolation(.high)
                            .scaledToFill()
                            .frame(width: proxy.size.width, height: proxy.size.height)
                            .saturation(1.12)
                            .contrast(1.05)
                            .brightness(0.02)
                    }
                    .overlay(flagFinishOverlay)
                }
            case .failure, .empty:
                fallbackFlag
            @unknown default:
                fallbackFlag
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .accessibilityHidden(true)
    }

    private var flagURL: URL? {
        URL(string: "https://flagcdn.com/w640/us-\(style.code.lowercased()).png")
    }

    private var flagFinishOverlay: some View {
        ZStack {
            LinearGradient(
                colors: [.white.opacity(0.24), .clear, .black.opacity(0.12)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            LinearGradient(
                colors: [.clear, .black.opacity(0.16)],
                startPoint: .top,
                endPoint: .bottom
            )

            RadialGradient(
                colors: [.clear, .black.opacity(0.10)],
                center: .center,
                startRadius: 80,
                endRadius: 260
            )

            Capsule()
                .fill(.white.opacity(0.16))
                .frame(width: 280, height: 34)
                .blur(radius: 18)
                .rotationEffect(.degrees(-16))
                .offset(x: -54, y: -42)
        }
    }

    private var flagBackground: some View {
        LinearGradient(
            colors: [
                LumaTheme.color(hex: style.primaryHex, fallback: LumaTheme.aqua).opacity(0.22),
                LumaTheme.color(hex: style.secondaryHex, fallback: LumaTheme.mint).opacity(0.18),
                .white.opacity(0.35)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var fallbackFlag: some View {
        LinearGradient(
            colors: [
                LumaTheme.color(hex: style.primaryHex, fallback: LumaTheme.aqua),
                LumaTheme.color(hex: style.secondaryHex, fallback: LumaTheme.mint),
                LumaTheme.color(hex: style.accentHex, fallback: .white)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(flagFinishOverlay)
    }
}
