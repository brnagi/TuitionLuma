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
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(scoreFactorGroups) { group in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: group.systemImage)
                                .font(.subheadline.weight(.heavy))
                                .foregroundStyle(group.tint)
                                .frame(width: 28, height: 28)
                                .background(group.tint.opacity(0.12), in: Circle())
                                .accessibilityHidden(true)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(group.title)
                                    .font(.subheadline.weight(.heavy))
                                    .foregroundStyle(LumaTheme.ink)

                                Text(group.explanation)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(LumaTheme.slate)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(10)
                        .background(group.tint.opacity(0.07), in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(20)
        .background(LumaTheme.card, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
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

    private var scoreFactorGroups: [ScoreFactorGroup] {
        [
            ScoreFactorGroup(
                title: "Cost",
                explanation: costExplanation,
                systemImage: "dollarsign.circle.fill",
                tint: LumaTheme.valueGreen
            ),
            ScoreFactorGroup(
                title: "Outcomes",
                explanation: outcomesExplanation,
                systemImage: "chart.line.uptrend.xyaxis.circle.fill",
                tint: LumaTheme.outcomeTeal
            ),
            ScoreFactorGroup(
                title: "Debt",
                explanation: debtExplanation,
                systemImage: "creditcard.fill",
                tint: LumaTheme.sun
            )
        ]
    }

    private var costExplanation: String {
        if school.costEstimate.averageNetPrice > 0, school.costEstimate.averageNetPrice <= 18_000 {
            return "Competitive net price strengthens the value signal."
        }

        if school.costEstimate.averageNetPrice > 0 {
            return "Net price is part of the score and should be compared with aid."
        }

        return "Cost is based on the best reported school data available."
    }

    private var outcomesExplanation: String {
        if school.medianEarnings >= 65_000, school.graduationRate >= 0.65 {
            return "Strong earnings and completion outcomes support this score."
        }

        if school.medianEarnings > 0 {
            return "Reported earnings help estimate long-term payoff."
        }

        if school.graduationRate > 0 {
            return "Graduation outcomes are included in the value picture."
        }

        return "Outcome data is limited, so compare carefully."
    }

    private var debtExplanation: String {
        if school.averageDebt > 0, school.averageDebt <= 24_000 {
            return "Reported student debt appears manageable compared with many schools."
        }

        if school.averageDebt > 0 {
            return "Debt is included so lower cost does not hide borrowing risk."
        }

        return "Debt information is limited for this school."
    }
}

private struct ScoreFactorGroup: Identifiable {
    let id = UUID()
    var title: String
    var explanation: String
    var systemImage: String
    var tint: Color
}
