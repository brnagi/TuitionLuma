import SwiftUI

enum LumaTheme {
    static let coral = Color(red: 1.0, green: 0.35, blue: 0.36)
    static let sun = Color(red: 1.0, green: 0.78, blue: 0.25)
    static let aqua = Color(red: 0.16, green: 0.75, blue: 0.78)
    static let mint = Color(red: 0.35, green: 0.84, blue: 0.52)
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
