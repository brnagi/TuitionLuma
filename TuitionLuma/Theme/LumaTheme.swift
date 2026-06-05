import SwiftUI

enum LumaTheme {
    static let coral = Color(red: 1.0, green: 0.35, blue: 0.36)
    static let sun = Color(red: 1.0, green: 0.78, blue: 0.25)
    static let aqua = Color(red: 0.16, green: 0.75, blue: 0.78)
    static let mint = Color(red: 0.35, green: 0.84, blue: 0.52)
    static let valueGreen = Color(red: 0.10, green: 0.66, blue: 0.38)
    static let outcomeTeal = Color(red: 0.04, green: 0.58, blue: 0.72)
    static let scorePurple = Color(red: 0.43, green: 0.27, blue: 0.86)
    static let scoreGold = Color(red: 0.92, green: 0.62, blue: 0.12)
    static let warningOrange = Color(red: 0.95, green: 0.38, blue: 0.16)
    static let ink = Color(red: 0.09, green: 0.10, blue: 0.18)
    static let slate = Color(red: 0.32, green: 0.36, blue: 0.46)
    static let canvas = Color(red: 0.98, green: 0.98, blue: 1.0)
    static let card = Color.white

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
}
