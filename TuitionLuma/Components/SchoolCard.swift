import SwiftUI

struct SchoolCard: View {
    var school: School
    var isSaved: Bool
    var isCompared: Bool
    var onSaveTapped: () -> Void
    var onCompareTapped: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            campusImage

            VStack(alignment: .leading, spacing: 12) {
                controlRow
                titleBlock
                valueBadge
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
                .stroke(.black.opacity(0.06))
        }
        .shadow(color: .black.opacity(0.06), radius: 16, y: 8)
    }

    private var campusImage: some View {
        stateFlagHero
            .frame(maxWidth: .infinity)
            .frame(height: 124)
            .clipped()
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
            .scaleEffect(1.02)
            .saturation(1.10)
            .contrast(1.04)
            .overlay(flagDepthOverlay)
    }

    private var flagDepthOverlay: some View {
        ZStack {
            LinearGradient(
                colors: [.white.opacity(0.12), .clear, .black.opacity(0.12)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [.clear, .black.opacity(0.14)],
                center: .center,
                startRadius: 90,
                endRadius: 260
            )
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
            .background(.white, in: Capsule())
            .overlay {
                Capsule()
                    .stroke(tint.opacity(0.14))
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

private struct StateFlagBackdrop: View {
    var style: StateFlagStyle

    var body: some View {
        AsyncImage(url: flagURL) { phase in
            switch phase {
            case .success(let image):
                GeometryReader { proxy in
                    flagImage(image, in: proxy.size)
                        .overlay(readabilityOverlay)
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

    @ViewBuilder
    private func flagImage(_ image: Image, in size: CGSize) -> some View {
        if usesCenteredFullFlag {
            ZStack {
                image
                    .resizable()
                    .interpolation(.high)
                    .scaledToFill()
                    .frame(width: size.width, height: size.height)
                    .scaleEffect(1.08)
                    .blur(radius: 10)
                    .opacity(0.65)

                image
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: size.width - 36, height: size.height - 16)
            }
            .frame(width: size.width, height: size.height)
        } else {
            image
                .resizable()
                .interpolation(.high)
                .scaledToFill()
                .frame(width: size.width, height: size.height, alignment: flagAlignment)
        }
    }

    private var usesCenteredFullFlag: Bool {
        ["CA", "IL", "MA", "RI", "WV"].contains(style.code)
    }

    private var flagAlignment: Alignment {
        switch style.code {
        case "CA":
            .bottom
        default:
            .center
        }
    }

    private var readabilityOverlay: some View {
        LinearGradient(
            colors: [.black.opacity(0.16), .clear, .black.opacity(0.10)],
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
        .overlay(readabilityOverlay)
    }
}
