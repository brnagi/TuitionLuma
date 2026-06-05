import Foundation

enum LumaFormat {
    static let currency: FloatingPointFormatStyle<Double>.Currency = .currency(code: "USD").precision(.fractionLength(0))
    static let compactCurrency: FloatingPointFormatStyle<Double>.Currency = .currency(code: "USD").notation(.compactName)
    static let percent: FloatingPointFormatStyle<Double>.Percent = .percent.precision(.fractionLength(0))

    static func number(_ value: Int) -> String {
        value.formatted(.number.notation(.compactName))
    }
}
