import SwiftUI

struct LoadingStateView: View {
    var title: String = "Finding bright options..."

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(LumaTheme.coral)
                .scaleEffect(1.15)
                .accessibilityLabel(title)

            Text(title)
                .font(.headline)
                .foregroundStyle(LumaTheme.ink)
        }
        .frame(maxWidth: .infinity, minHeight: 240)
    }
}

struct EmptyStateView: View {
    var title: String
    var message: String
    var systemImage: String

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(LumaTheme.heroGradient)
                .frame(width: 76, height: 76)
                .background(LumaTheme.aqua.opacity(0.12), in: Circle())
                .accessibilityHidden(true)

            Text(title)
                .font(.title3.weight(.bold))
                .foregroundStyle(LumaTheme.ink)
                .multilineTextAlignment(.center)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(LumaTheme.slate)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 280)
        }
        .frame(maxWidth: .infinity, minHeight: 280)
        .padding()
        .accessibilityElement(children: .combine)
    }
}

struct EmptyStateCard<CTA: View>: View {
    var title: String
    var message: String
    var systemImage: String
    @ViewBuilder var cta: () -> CTA

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: systemImage)
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(LumaTheme.heroGradient)
                .frame(width: 76, height: 76)
                .background(LumaTheme.aqua.opacity(0.14), in: Circle())
                .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text(title)
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(LumaTheme.ink)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(LumaTheme.slate)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 310)
            }

            cta()
        }
        .frame(maxWidth: .infinity)
        .lumaCard(padding: 24, shadowOpacity: 0.42)
        .accessibilityElement(children: .contain)
    }
}

extension EmptyStateCard where CTA == EmptyView {
    init(title: String, message: String, systemImage: String) {
        self.title = title
        self.message = message
        self.systemImage = systemImage
        self.cta = { EmptyView() }
    }
}

struct EmptyStateActionLabel: View {
    var title: String
    var systemImage: String

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.headline.weight(.heavy))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 50)
            .background(LumaTheme.heroGradient, in: Capsule())
    }
}

struct ErrorStateView: View {
    var message: String
    var retry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            EmptyStateView(
                title: "Live data did not load",
                message: message,
                systemImage: "exclamationmark.triangle.fill"
            )

            LumaButton(title: "Try Again", systemImage: "arrow.clockwise", style: .secondary, action: retry)
                .padding(.horizontal)
        }
    }
}
