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
            .background(backgroundStyle, in: Capsule())
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

    private var backgroundStyle: AnyShapeStyle {
        switch style {
        case .primary:
            AnyShapeStyle(LumaTheme.heroGradient)
        case .secondary:
            AnyShapeStyle(.white)
        }
    }
}
