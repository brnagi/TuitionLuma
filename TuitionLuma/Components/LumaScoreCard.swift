import SwiftUI

struct LumaScoreCard: View {
    var school: School
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Luma Score")
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(scoreTint)
                        .textCase(.uppercase)

                    Text("\(school.lumaScore)")
                        .font(.system(size: 56, weight: .heavy))
                        .foregroundStyle(scoreTint)
                        .lineLimit(1)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(scoreTint.opacity(0.10), in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
                .overlay {
                    RoundedRectangle(cornerRadius: LumaTheme.cardRadius)
                        .stroke(scoreTint.opacity(0.20), lineWidth: 1.5)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(school.valueLabel)
                        .font(.title3.weight(.heavy))
                        .foregroundStyle(LumaTheme.ink)

                    Text(summary)
                        .font(.subheadline)
                        .foregroundStyle(LumaTheme.slate)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text("Why This Score?")
                        .font(.subheadline.weight(.heavy))
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.bold))
                }
                .foregroundStyle(LumaTheme.ink)
                .padding(12)
            .background(LumaTheme.canvas.opacity(0.95), in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
                .overlay {
                    RoundedRectangle(cornerRadius: LumaTheme.cardRadius)
                        .stroke(LumaTheme.cardStroke.opacity(0.55))
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Why this score")
            .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")
            .accessibilityHint(isExpanded ? "Hides score details." : "Shows score details.")

            if isExpanded {
                VStack(alignment: .leading, spacing: 9) {
                    ForEach(explanationBullets, id: \.self) { bullet in
                        Label(bullet, systemImage: "checkmark.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(LumaTheme.slate)
                            .labelStyle(.titleAndIcon)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(20)
        .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
        .overlay {
            RoundedRectangle(cornerRadius: LumaTheme.cardRadius)
                .stroke(scoreTint.opacity(0.34), lineWidth: 1.5)
        }
        .shadow(color: LumaTheme.cardShadow.opacity(0.92), radius: 22, y: 12)
        .accessibilityElement(children: .contain)
    }

    private var scoreTint: Color {
        if school.lumaScore >= 85 { return LumaTheme.valueGreen }
        if school.lumaScore >= 70 { return LumaTheme.outcomeTeal }
        if school.lumaScore >= 55 { return LumaTheme.scoreGold }
        return LumaTheme.warningOrange
    }

    private var summary: String {
        "A quick read on cost, earnings, debt, and completion outcomes."
    }

    private var explanationBullets: [String] {
        var bullets: [String] = []

        if school.medianEarnings >= 65_000 {
            bullets.append("Strong earnings outcomes")
        } else if school.medianEarnings > 0 {
            bullets.append("Earnings outcomes are available")
        }

        if school.averageDebt > 0, school.averageDebt <= 24_000 {
            bullets.append("Manageable student debt")
        } else if school.averageDebt > 0 {
            bullets.append("Student debt is part of the value picture")
        }

        if school.graduationRate >= 0.65 {
            bullets.append("Above-average graduation rate")
        } else if school.graduationRate > 0 {
            bullets.append("Graduation outcomes are included")
        }

        if school.costEstimate.averageNetPrice > 0, school.costEstimate.averageNetPrice <= 18_000 {
            bullets.append("Competitive net price")
        } else if school.costEstimate.averageNetPrice > 0 {
            bullets.append("Net price is included in the score")
        }

        if bullets.isEmpty {
            bullets.append("Uses the best available cost and outcome data")
        }

        return Array(bullets.prefix(4))
    }
}
