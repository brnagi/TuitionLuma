import SwiftUI

struct OnboardingView: View {
    @Binding var profile: StudentProfile
    @State private var nickname = ""
    @FocusState private var isNicknameFocused: Bool
    var onContinue: () -> Void

    var body: some View {
        GeometryReader { proxy in
            let isCompact = proxy.size.height < 740

            LumaTheme.canvas
                .ignoresSafeArea()

            VStack(spacing: 0) {
                hero(isCompact: isCompact)
                    .frame(maxWidth: .infinity, minHeight: min(max(proxy.size.height * 0.34, 240), 310), alignment: .leading)

                VStack(spacing: isCompact ? 9 : 12) {
                    decisionExample
                    nicknamePrompt
                    actionRow
                }
                .padding(.horizontal, isCompact ? 16 : 18)
                .padding(.top, isCompact ? 12 : 16)
                .padding(.bottom, isCompact ? 12 : 18)
                .frame(maxWidth: .infinity)
                .background(LumaTheme.canvas)
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
            .scrollDismissesKeyboard(.interactively)
        }
    }

    private func hero(isCompact: Bool) -> some View {
        VStack(alignment: .leading, spacing: isCompact ? 12 : 16) {
            HStack {
                Image(systemName: "sun.max.fill")
                    .font(.title3)
                Text("TuitionLuma")
                    .font(.title3.weight(.heavy))
            }
            .foregroundStyle(.white)

            Spacer(minLength: 6)

            VStack(alignment: .leading, spacing: 10) {
                Text("See what college will really cost.")
                    .font(.system(size: isCompact ? 30 : 34, weight: .heavy))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                    .minimumScaleFactor(0.92)

                Text("Compare tuition, aid, debt, earnings, and outcomes before making one of the biggest financial decisions of your life.")
                    .font((isCompact ? Font.subheadline : Font.body).weight(.medium))
                    .foregroundStyle(.white.opacity(0.92))
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 8) {
                StatPill(title: "Affordability", value: "Clear", systemImage: "dollarsign.circle.fill", tint: .white.opacity(0.24))
                StatPill(title: "Outcomes", value: "Compared", systemImage: "chart.line.uptrend.xyaxis", tint: .white.opacity(0.24))
            }
        }
        .padding(.horizontal, isCompact ? 20 : 24)
        .padding(.top, isCompact ? 18 : 22)
        .padding(.bottom, isCompact ? 16 : 20)
        .background(LumaTheme.heroGradient)
    }

    private var actionRow: some View {
        HStack(spacing: 10) {
            Button("Skip") {
                finishOnboarding()
            }
            .font(.headline.weight(.heavy))
            .foregroundStyle(LumaTheme.slate)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(.white, in: Capsule())

            LumaButton(title: "Continue", systemImage: "arrow.right", action: finishOnboarding)
        }
    }

    private var nicknamePrompt: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("What should we call you?")
                .font(.headline.weight(.heavy))
                .foregroundStyle(LumaTheme.ink)

            Text("Optional. Add a friendly name for personalized recommendations.")
                .font(.caption)
                .foregroundStyle(LumaTheme.slate)

            TextField(
                text: $nickname,
                prompt: Text("Alex, Sam, or Taylor")
                    .foregroundStyle(LumaTheme.slate)
            ) {
                Text("Nickname")
            }
            .focused($isNicknameFocused)
            .submitLabel(.done)
            .textInputAutocapitalization(.words)
            .onSubmit {
                finishOnboarding()
            }
            .lumaTextField(isFocused: isNicknameFocused)
            .accessibilityLabel("Optional nickname")
        }
        .padding(14)
        .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
        .onAppear {
            nickname = profile.displayNickname
        }
    }

    private func finishOnboarding() {
        profile.nickname = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        onContinue()
    }

    private var decisionExample: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Which school is the best value?")
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(LumaTheme.ink)

                Text("TuitionLuma turns cost and outcome data into a simple decision signal.")
                    .font(.caption)
                    .foregroundStyle(LumaTheme.slate)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 8) {
                exampleMetric(title: "Net Price", value: "$14K", tint: LumaTheme.valueGreen)
                exampleMetric(title: "Earnings", value: "$62K", tint: LumaTheme.outcomeTeal)
                exampleMetric(title: "Luma Score", value: "69", tint: LumaTheme.scoreGold)
            }

            HStack(spacing: 8) {
                Label("Fair Value", systemImage: "star.fill")
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(LumaTheme.scoreGold)
                    .padding(.vertical, 7)
                    .padding(.horizontal, 10)
                    .background(LumaTheme.scoreGold.opacity(0.12), in: Capsule())

                Text("Good earnings, but watch total debt.")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(LumaTheme.slate)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
    }

    private func exampleMetric(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.headline.weight(.heavy))
                .foregroundStyle(tint)
                .lineLimit(1)

            Text(title)
                .font(.caption2.weight(.bold))
                .foregroundStyle(LumaTheme.slate)
                .fixedSize(horizontal: false, vertical: true)
        }
            .frame(maxWidth: .infinity)
            .padding(10)
            .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
    }
}
