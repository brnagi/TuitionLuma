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
            SchoolBrandBackdrop(school: school)
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

                VStack(alignment: .leading, spacing: 10) {
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
        .frame(height: 174)
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
                    brandHero
                @unknown default:
                    brandHero
                }
            }
        } else {
            brandHero
        }
    }

    @ViewBuilder
    private var logoMark: some View {
        if !logoURLs.isEmpty {
            ProgressiveRemoteImage(urls: logoURLs) { image in
                logoImageTreatment(image)
            } placeholder: {
                fallbackLogoMark
            }
        } else {
            fallbackLogoMark
        }
    }

    private var fallbackLogoMark: some View {
        SchoolInitialMark(initials: schoolInitials)
    }

    private func logoImageTreatment(_ image: Image) -> some View {
        image
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .padding(14)
            .frame(width: 108, height: 108)
            .background(.white.opacity(0.96), in: RoundedRectangle(cornerRadius: 24))
            .overlay {
                RoundedRectangle(cornerRadius: 24)
                    .stroke(.white.opacity(0.70), lineWidth: 1)
            }
            .shadow(color: brandShadow.opacity(0.26), radius: 18, y: 9)
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

    private var brandHero: some View {
        SchoolBrandBackdrop(school: school)
            .overlay(logoWatermark)
            .overlay(.black.opacity(0.08))
    }

    @ViewBuilder
    private var logoWatermark: some View {
        if !logoURLs.isEmpty {
            GeometryReader { proxy in
                ProgressiveRemoteImage(urls: logoURLs) { image in
                    image
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(width: proxy.size.width * 0.72, height: proxy.size.height * 0.92)
                        .opacity(0.16)
                        .blur(radius: 0.2)
                        .offset(x: proxy.size.width * 0.38, y: proxy.size.height * 0.03)
                } placeholder: {
                    EmptyView()
                }
            }
            .allowsHitTesting(false)
        }
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

    private var logoURLs: [URL] {
        school.logoURLs.isEmpty ? school.logoURL.map { [$0] } ?? [] : school.logoURLs
    }

    private var brandShadow: Color {
        LumaTheme.color(hex: school.primaryColor, fallback: LumaTheme.ink)
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
            .frame(width: 108, height: 108)
            .background(.white.opacity(0.16), in: RoundedRectangle(cornerRadius: 24))
            .overlay {
                RoundedRectangle(cornerRadius: 24)
                    .stroke(.white.opacity(0.26), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
            .accessibilityLabel("School initials")
    }
}

private struct ProgressiveRemoteImage<Content: View, Placeholder: View>: View {
    var urls: [URL]
    @ViewBuilder var content: (Image) -> Content
    @ViewBuilder var placeholder: () -> Placeholder

    @State private var index = 0

    var body: some View {
        if urls.indices.contains(index) {
            AsyncImage(url: urls[index]) { phase in
                switch phase {
                case .success(let image):
                    content(image)
                case .failure:
                    nextLogoCandidate
                case .empty:
                    placeholder()
                @unknown default:
                    nextLogoCandidate
                }
            }
        } else {
            placeholder()
        }
    }

    private var nextLogoCandidate: some View {
        placeholder()
            .task {
                if index < urls.count - 1 {
                    index += 1
                }
            }
    }
}

private struct SchoolBrandBackdrop: View {
    var school: School

    var body: some View {
        LinearGradient(
            colors: [
                primaryColor.opacity(0.96),
                secondaryColor.opacity(0.88),
                LumaTheme.aqua.opacity(0.38)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay {
            LinearGradient(
                colors: [.white.opacity(0.18), .clear, .black.opacity(0.08)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .accessibilityHidden(true)
    }

    private var primaryColor: Color {
        LumaTheme.color(hex: school.primaryColor, fallback: LumaTheme.aqua)
    }

    private var secondaryColor: Color {
        LumaTheme.color(hex: school.secondaryColor, fallback: LumaTheme.mint)
    }
}
