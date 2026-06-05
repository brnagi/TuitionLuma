import SwiftUI

struct LoadingStateView: View {
    var title: String = "Finding bright options..."

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(LumaTheme.coral)
                .scaleEffect(1.15)

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
    }
}

struct ErrorStateView: View {
    var message: String
    var retry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            EmptyStateView(
                title: "Something went sideways",
                message: message,
                systemImage: "exclamationmark.triangle.fill"
            )

            LumaButton(title: "Try Again", systemImage: "arrow.clockwise", style: .secondary, action: retry)
                .padding(.horizontal)
        }
    }
}

struct MissingAPIKeyStateView: View {
    var useSampleData: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            EmptyStateView(
                title: "Connect live college data",
                message: "Set COLLEGE_SCORECARD_API_KEY to search real U.S. colleges from the College Scorecard API.",
                systemImage: "key.fill"
            )

            VStack(spacing: 10) {
                LumaButton(title: "Use Sample Data", systemImage: "tray.full", style: .secondary, action: useSampleData)

                Text("Sample data is only for local development, previews, or missing-key demos.")
                    .font(.footnote)
                    .foregroundStyle(LumaTheme.slate)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)
        }
    }
}
