import SwiftUI

struct ComparisonRow: View {
    var title: String
    var values: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(LumaTheme.slate)
                .textCase(.uppercase)

            HStack(spacing: 8) {
                ForEach(Array(values.enumerated()), id: \.offset) { _, value in
                    Text(value)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(LumaTheme.ink)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                        .background(LumaTheme.aqua.opacity(0.10), in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
                        .accessibilityLabel(title)
                        .accessibilityValue(value)
                }
            }
        }
        .padding(.vertical, 10)
    }
}
