import Foundation

struct CostEstimate: Hashable, Codable {
    var tuitionAndFees: Double
    var outOfStateTuition: Double?
    var housingAndMeals: Double
    var booksAndSupplies: Double
    var transportation: Double
    var personalExpenses: Double
    var averageGrantAid: Double

    init(
        tuitionAndFees: Double,
        outOfStateTuition: Double? = nil,
        housingAndMeals: Double,
        booksAndSupplies: Double,
        transportation: Double,
        personalExpenses: Double,
        averageGrantAid: Double
    ) {
        self.tuitionAndFees = tuitionAndFees
        self.outOfStateTuition = outOfStateTuition
        self.housingAndMeals = housingAndMeals
        self.booksAndSupplies = booksAndSupplies
        self.transportation = transportation
        self.personalExpenses = personalExpenses
        self.averageGrantAid = averageGrantAid
    }

    var annualStickerCost: Double {
        tuitionAndFees + housingAndMeals + booksAndSupplies + transportation + personalExpenses
    }

    var averageNetPrice: Double {
        max(0, annualStickerCost - averageGrantAid)
    }
}
