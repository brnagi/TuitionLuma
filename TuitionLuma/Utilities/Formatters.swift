import Foundation

enum LumaFormat {
    static let currency: FloatingPointFormatStyle<Double>.Currency = .currency(code: "USD").precision(.fractionLength(0))
    static let percent: FloatingPointFormatStyle<Double>.Percent = .percent.precision(.fractionLength(0))

    static func number(_ value: Int) -> String {
        value.formatted(.number.notation(.compactName))
    }

    static func compactCurrency(_ value: Double) -> String {
        let absoluteValue = abs(value)
        let sign = value < 0 ? "-" : ""

        if absoluteValue >= 1_000_000 {
            return "\(sign)$\((absoluteValue / 1_000_000).formatted(.number.precision(.fractionLength(1))))M"
        }

        if absoluteValue >= 1_000 {
            return "\(sign)$\((absoluteValue / 1_000).formatted(.number.precision(.fractionLength(0))))K"
        }

        return "\(sign)$\(absoluteValue.formatted(.number.precision(.fractionLength(0))))"
    }
}
