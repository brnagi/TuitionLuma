import SwiftUI

enum LumaTheme {
    static let coral = Color(red: 1.0, green: 0.35, blue: 0.36)
    static let sun = Color(red: 0.94, green: 0.64, blue: 0.08)
    static let aqua = Color(red: 0.16, green: 0.75, blue: 0.78)
    static let mint = Color(red: 0.35, green: 0.84, blue: 0.52)
    static let valueGreen = Color(red: 0.04, green: 0.54, blue: 0.29)
    static let outcomeTeal = Color(red: 0.02, green: 0.48, blue: 0.64)
    static let scorePurple = Color(red: 0.35, green: 0.21, blue: 0.76)
    static let scoreGold = Color(red: 0.78, green: 0.45, blue: 0.02)
    static let warningOrange = Color(red: 0.88, green: 0.27, blue: 0.10)
    static let ink = Color(red: 0.09, green: 0.10, blue: 0.18)
    static let slate = Color(red: 0.25, green: 0.29, blue: 0.39)
    static let canvas = Color(red: 0.94, green: 0.948, blue: 0.972)
    static let card = Color.white
    static let cardStroke = Color.black.opacity(0.16)
    static let cardShadow = Color.black.opacity(0.14)

    static let cardRadius: CGFloat = 8

    static let heroGradient = LinearGradient(
        colors: [coral, sun, aqua],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let coolGradient = LinearGradient(
        colors: [aqua, mint],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let warmGradient = LinearGradient(
        colors: [sun, coral],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static func color(hex: String?, fallback: Color) -> Color {
        guard let hex else { return fallback }

        let sanitized = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        guard sanitized.count == 6, let value = Int(sanitized, radix: 16) else {
            return fallback
        }

        let red = Double((value >> 16) & 0xFF) / 255
        let green = Double((value >> 8) & 0xFF) / 255
        let blue = Double(value & 0xFF) / 255
        return Color(red: red, green: green, blue: blue)
    }
}

struct LumaTextFieldModifier: ViewModifier {
    var isFocused: Bool = false

    func body(content: Content) -> some View {
        content
            .foregroundStyle(LumaTheme.ink)
            .tint(LumaTheme.coral)
            .padding(13)
            .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
            .overlay {
                RoundedRectangle(cornerRadius: LumaTheme.cardRadius)
                    .stroke(isFocused ? LumaTheme.coral : LumaTheme.cardStroke, lineWidth: isFocused ? 2 : 1)
            }
            .shadow(color: isFocused ? LumaTheme.coral.opacity(0.18) : .black.opacity(0.03), radius: isFocused ? 10 : 4, y: isFocused ? 4 : 2)
    }
}

extension View {
    func lumaTextField(isFocused: Bool = false) -> some View {
        modifier(LumaTextFieldModifier(isFocused: isFocused))
    }
}
