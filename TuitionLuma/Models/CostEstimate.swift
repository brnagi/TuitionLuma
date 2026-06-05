import Foundation

struct CostEstimate: Hashable, Codable {
    var tuitionAndFees: Double
    var housingAndMeals: Double
    var booksAndSupplies: Double
    var transportation: Double
    var personalExpenses: Double
    var averageGrantAid: Double

    var annualStickerCost: Double {
        tuitionAndFees + housingAndMeals + booksAndSupplies + transportation + personalExpenses
    }

    var averageNetPrice: Double {
        max(0, annualStickerCost - averageGrantAid)
    }
}
