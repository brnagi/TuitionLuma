import SwiftUI

struct OnboardingView: View {
    var onContinue: () -> Void

    var body: some View {
        ZStack {
            LumaTheme.canvas
                .ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Image(systemName: "sun.max.fill")
                            .font(.title2)
                        Text("TuitionLuma")
                            .font(.title3.weight(.heavy))
                    }
                    .foregroundStyle(.white)

                    Spacer()

                    VStack(alignment: .leading, spacing: 14) {
                        Text("Make the college decision with the full picture.")
                            .font(.system(size: 40, weight: .heavy))
                            .foregroundStyle(.white)
                            .lineLimit(4)
                            .minimumScaleFactor(0.72)

                        Text("TuitionLuma brings real college cost, financial aid, debt, outcomes, and value into one friendly plan.")
                            .font(.title3.weight(.medium))
                            .foregroundStyle(.white.opacity(0.9))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    HStack(spacing: 10) {
                        StatPill(title: "Cost data", value: "Real", systemImage: "dollarsign.circle.fill", tint: .white.opacity(0.24))
                        StatPill(title: "Value", value: "Luma", systemImage: "sparkles", tint: .white.opacity(0.24))
                    }
                }
                .padding(26)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .background(LumaTheme.heroGradient)

                VStack(spacing: 14) {
                    decisionExample

                    LumaButton(title: "Start Exploring", systemImage: "arrow.right", action: onContinue)
                }
                .padding(22)
                .background(LumaTheme.canvas)
            }
        }
    }

    private var decisionExample: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Best value for you")
                        .font(.headline.weight(.heavy))
                        .foregroundStyle(LumaTheme.ink)

                    Text("Compare real affordability, debt, earnings, and outcomes before you choose.")
                        .font(.caption)
                        .foregroundStyle(LumaTheme.slate)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                VStack(spacing: 2) {
                    Text("92")
                        .font(.title.weight(.heavy))
                        .foregroundStyle(LumaTheme.valueGreen)

                    Text("Luma")
                        .font(.caption2.weight(.heavy))
                        .foregroundStyle(LumaTheme.slate)
                }
                .frame(width: 66, height: 66)
                .background(LumaTheme.valueGreen.opacity(0.12), in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
            }

            HStack(spacing: 8) {
                examplePill("Lower debt", tint: LumaTheme.sun)
                examplePill("Higher earnings", tint: LumaTheme.outcomeTeal)
                examplePill("Affordable", tint: LumaTheme.valueGreen)
            }
        }
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
    }

    private func examplePill(_ title: String, tint: Color) -> some View {
        Text(title)
            .font(.caption2.weight(.heavy))
            .foregroundStyle(tint)
            .lineLimit(1)
            .minimumScaleFactor(0.78)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .background(tint.opacity(0.10), in: Capsule())
    }
}
