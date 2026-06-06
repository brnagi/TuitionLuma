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
            .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
            .padding(.horizontal, 10)
            .padding(.bottom, 10)
        }
        .background {
            StateFlagBackdrop(style: stateFlagStyle)
                .blur(radius: 2.4)
                .clipShape(RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
        }
        .overlay {
            RoundedRectangle(cornerRadius: LumaTheme.cardRadius)
                .stroke(.black.opacity(0.06))
        }
        .shadow(color: .black.opacity(0.06), radius: 16, y: 8)
    }

    private var campusImage: some View {
        ZStack(alignment: .topTrailing) {
            ZStack(alignment: .bottomLeading) {
                campusBackground

                VStack(alignment: .leading, spacing: 8) {
                    logoMark

                    Text(school.type.rawValue)
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(.white.opacity(0.92))
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(.white.opacity(0.20), in: Capsule())
                }
                .padding(18)
            }

            HStack(spacing: 8) {
                iconButton(
                    systemImage: isCompared ? "checkmark.circle.fill" : "plus.circle",
                    tint: isCompared ? LumaTheme.scorePurple : LumaTheme.ink.opacity(0.72),
                    label: isCompared ? "Remove school from compare" : "Compare school",
                    action: onCompareTapped
                )

                iconButton(
                    systemImage: isSaved ? "bookmark.fill" : "bookmark",
                    tint: isSaved ? LumaTheme.valueGreen : LumaTheme.ink.opacity(0.72),
                    label: isSaved ? "Remove saved school" : "Save school",
                    action: onSaveTapped
                )
            }
            .padding(12)
        }
        .frame(height: 150)
        .clipShape(RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
        .padding(10)
        .padding(.bottom, -4)
    }

    @ViewBuilder
    private var campusBackground: some View {
        if let campusImageURL = school.campusImageURL {
            // TODO: Replace mock URLs with verified campus image URLs from a licensed data source.
            AsyncImage(url: campusImageURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .overlay(.black.opacity(0.18))
                case .failure, .empty:
                    stateFlagHero
                @unknown default:
                    stateFlagHero
                }
            }
        } else {
            stateFlagHero
        }
    }

    @ViewBuilder
    private var logoMark: some View {
        if let logoURL = school.logoURL {
            // TODO: Connect logoURL once school logo assets are available.
            AsyncImage(url: logoURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .padding(10)
                        .frame(width: 70, height: 70)
                        .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
                case .failure, .empty:
                    fallbackLogoMark
                @unknown default:
                    fallbackLogoMark
                }
            }
        } else {
            fallbackLogoMark
        }
    }

    private var fallbackLogoMark: some View {
        SchoolInitialMark(initials: schoolInitials)
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
            .blur(radius: 1.2)
            .overlay(.black.opacity(0.08))
    }

    private var stateFlagStyle: StateFlagStyle {
        StateFlagStyles.style(for: school.state)
    }

    private var schoolInitials: String {
        let ignoredWords: Set<String> = ["of", "the", "and", "at", "for"]
        let words = school.name
            .split(separator: " ")
            .filter { !ignoredWords.contains($0.lowercased()) }

        let initials = words
            .prefix(2)
            .compactMap(\.first)
            .map { String($0).uppercased() }
            .joined()

        return initials.isEmpty ? school.state : initials
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

    private func iconButton(systemImage: String, tint: Color, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.headline.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 36, height: 36)
                .background(.white.opacity(0.92), in: Circle())
                .shadow(color: .black.opacity(0.10), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

private struct SchoolInitialMark: View {
    var initials: String

    var body: some View {
        Text(initials)
            .font(.system(size: initials.count > 2 ? 24 : 30, weight: .heavy))
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .frame(width: 70, height: 70)
            .background(.white.opacity(0.16), in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
            .overlay {
                RoundedRectangle(cornerRadius: LumaTheme.cardRadius)
                    .stroke(.white.opacity(0.26), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
            .accessibilityLabel("School initials")
    }
}

private struct StateFlagBackdrop: View {
    var style: StateFlagStyle

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height

            ZStack {
                LinearGradient(
                    colors: [primaryColor, secondaryColor],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Rectangle()
                    .fill(.white.opacity(0.18))
                    .frame(width: width * 0.38)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)

                Rectangle()
                    .fill(accentColor.opacity(0.30))
                    .frame(width: width * 0.62, height: height * 0.22)
                    .rotationEffect(.degrees(-16))
                    .offset(x: width * 0.18, y: -height * 0.08)

                Rectangle()
                    .fill(.white.opacity(0.13))
                    .frame(width: width * 0.84, height: height * 0.18)
                    .rotationEffect(.degrees(-16))
                    .offset(x: width * 0.28, y: height * 0.16)

                Image(systemName: style.emblemSystemImage)
                    .font(.system(size: 118, weight: .heavy))
                    .foregroundStyle(accentColor.opacity(0.17))
                    .offset(x: width * 0.30, y: -height * 0.18)
            }
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
