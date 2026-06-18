import SwiftUI

struct LumaButton: View {
    enum Style {
        case primary
        case secondary
    }

    var title: String
    var systemImage: String?
    var style: Style = .primary
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.headline)
                }

                Text(title)
                    .font(.headline)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 44)
            .padding(.vertical, 15)
            .foregroundStyle(style == .primary ? .white : LumaTheme.ink)
            .background(buttonBackground)
            .shadow(color: style == .primary ? LumaTheme.gradientTextShadow : .clear, radius: style == .primary ? 3 : 0, y: style == .primary ? 1 : 0)
            .overlay {
                Capsule()
                    .stroke(style == .primary ? .white.opacity(0.24) : LumaTheme.ink.opacity(0.20), lineWidth: style == .primary ? 1 : 1.5)
            }
            .shadow(color: style == .primary ? LumaTheme.coral.opacity(0.30) : .black.opacity(0.08), radius: 14, y: 8)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
    }

    @ViewBuilder
    private var buttonBackground: some View {
        switch style {
        case .primary:
            ZStack {
                LumaTheme.heroGradient
                LumaTheme.readableGradientOverlay.opacity(0.34)
            }
            .clipShape(Capsule())
        case .secondary:
            Capsule()
                .fill(.white)
        }
    }
}
