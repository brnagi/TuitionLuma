import SwiftUI

struct OnboardingView: View {
    var onContinue: () -> Void

    var body: some View {
        ZStack {
            LumaTheme.canvas
                .ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 22) {
                    HStack {
                        Image(systemName: "sun.max.fill")
                            .font(.title2)
                        Text("TuitionLuma")
                            .font(.title3.weight(.heavy))
                    }
                    .foregroundStyle(.white)

                    Spacer()

                    VStack(alignment: .leading, spacing: 12) {
                        Text("See the real college price before you commit.")
                            .font(.system(size: 42, weight: .heavy))
                            .foregroundStyle(.white)
                            .lineLimit(4)
                            .minimumScaleFactor(0.72)

                        Text("Compare cost, aid, debt, and likely outcomes in one friendly place.")
                            .font(.title3.weight(.medium))
                            .foregroundStyle(.white.opacity(0.9))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    HStack(spacing: 10) {
                        StatPill(title: "Schools", value: "Live", systemImage: "building.columns.fill", tint: .white.opacity(0.24))
                        StatPill(title: "Loan view", value: "10 yrs", systemImage: "calendar", tint: .white.opacity(0.24))
                    }
                }
                .padding(26)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .background(LumaTheme.heroGradient)

                VStack(spacing: 14) {
                    HStack(spacing: 12) {
                        benefit("dollarsign.circle.fill", "Net price")
                        benefit("chart.bar.fill", "Outcomes")
                        benefit("heart.fill", "Saved")
                    }

                    LumaButton(title: "Start Exploring", systemImage: "arrow.right", action: onContinue)
                }
                .padding(22)
                .background(LumaTheme.canvas)
            }
        }
    }

    private func benefit(_ icon: String, _ title: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(LumaTheme.coral)

            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(LumaTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
    }
}
