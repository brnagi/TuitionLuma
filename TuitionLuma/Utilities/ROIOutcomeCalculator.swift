import Foundation

struct ROIOutcomeResult: Equatable {
    var score: Int
    var grade: String
    var earnings: Double
    var debt: Double
    var usedProgramEarnings: Bool
    var usedProgramDebt: Bool
}

enum ROIOutcomeCalculator {
    static func result(
        for school: School,
        program: AcademicProgram? = nil,
        estimatedNetCost: Double? = nil
    ) -> ROIOutcomeResult {
        let earnings = program.flatMap { $0.medianEarnings > 0 ? $0.medianEarnings : nil }
            ?? (school.medianEarnings > 0 ? school.medianEarnings : 45_000)
        let debt = program?.debt.flatMap { $0 > 0 ? $0 : nil }
            ?? (school.averageDebt > 0 ? school.averageDebt : 20_000)
        let netCost = max(estimatedNetCost ?? school.costEstimate.averageNetPrice, 1)
        let earningsToCost = earnings / netCost
        let debtToEarnings = debt / max(earnings, 1)

        let rawScore = 20
            + scaledScore(value: earningsToCost, low: 1.0, high: 5.0, points: 34)
            + scaledInverseScore(value: debtToEarnings, low: 0.18, high: 0.85, points: 26)
            + scaledScore(value: school.graduationRate, low: 0.35, high: 0.85, points: 20)
            + (Double(school.lumaScore) / 100) * 19

        let score = min(99, max(35, Int(rawScore.rounded())))

        return ROIOutcomeResult(
            score: score,
            grade: grade(for: score),
            earnings: earnings,
            debt: debt,
            usedProgramEarnings: (program?.medianEarnings ?? 0) > 0,
            usedProgramDebt: (program?.debt ?? 0) > 0
        )
    }

    private static func scaledScore(value: Double, low: Double, high: Double, points: Double) -> Double {
        guard high > low else { return 0 }
        let progress = (value - low) / (high - low)
        return min(1, max(0, progress)) * points
    }

    private static func scaledInverseScore(value: Double, low: Double, high: Double, points: Double) -> Double {
        guard high > low else { return 0 }
        let progress = (high - value) / (high - low)
        return min(1, max(0, progress)) * points
    }

    private static func grade(for score: Int) -> String {
        if score >= 92 { return "A" }
        if score >= 84 { return "B+" }
        if score >= 76 { return "B" }
        if score >= 66 { return "C+" }
        return "C"
    }
}
