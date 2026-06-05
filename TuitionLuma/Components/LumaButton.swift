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
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .foregroundStyle(style == .primary ? .white : LumaTheme.ink)
            .background(backgroundStyle, in: Capsule())
            .shadow(color: LumaTheme.coral.opacity(style == .primary ? 0.25 : 0), radius: 14, y: 8)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }

    private var backgroundStyle: AnyShapeStyle {
        switch style {
        case .primary:
            AnyShapeStyle(LumaTheme.heroGradient)
        case .secondary:
            AnyShapeStyle(LumaTheme.aqua.opacity(0.14))
        }
    }
}
