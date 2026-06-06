import Foundation

struct CostEstimate: Hashable, Codable {
    var tuitionAndFees: Double
    var outOfStateTuition: Double?
    var costOfAttendance: Double?
    var reportedAverageNetPrice: Double?
    var housingAndMeals: Double
    var booksAndSupplies: Double
    var transportation: Double
    var personalExpenses: Double
    var averageGrantAid: Double

    init(
        tuitionAndFees: Double,
        outOfStateTuition: Double? = nil,
        costOfAttendance: Double? = nil,
        reportedAverageNetPrice: Double? = nil,
        housingAndMeals: Double,
        booksAndSupplies: Double,
        transportation: Double,
        personalExpenses: Double,
        averageGrantAid: Double
    ) {
        self.tuitionAndFees = tuitionAndFees
        self.outOfStateTuition = outOfStateTuition
        self.costOfAttendance = costOfAttendance
        self.reportedAverageNetPrice = reportedAverageNetPrice
        self.housingAndMeals = housingAndMeals
        self.booksAndSupplies = booksAndSupplies
        self.transportation = transportation
        self.personalExpenses = personalExpenses
        self.averageGrantAid = averageGrantAid
    }

    var annualStickerCost: Double {
        tuitionAndFees + housingAndMeals + booksAndSupplies + transportation + personalExpenses
    }

    var estimatedAnnualCost: Double {
        if let costOfAttendance, costOfAttendance > 0 {
            return costOfAttendance
        }

        if annualStickerCost > 0 {
            return annualStickerCost
        }

        return reportedAverageNetPrice ?? 0
    }

    var averageNetPrice: Double {
        if let reportedAverageNetPrice, reportedAverageNetPrice > 0 {
            return reportedAverageNetPrice
        }

        return max(0, estimatedAnnualCost - averageGrantAid)
    }
}
