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
            ?? (school.averageDebt > 0 ? school.averageDebt : 24_000)
        let annualNetCost = max(estimatedNetCost ?? school.costEstimate.averageNetPrice, 1)
        let timeToDegree = Double(min(6, max(1, program?.typicalDurationYears ?? 4)))
        let totalCost = annualNetCost * timeToDegree
        let earningsToCost = earnings / totalCost
        let debtToEarnings = debt / max(earnings, 1)
        let hasProgramEarnings = (program?.medianEarnings ?? 0) > 0
        let hasProgramDebt = (program?.debt ?? 0) > 0
        let missingProgramDataPenalty = program == nil ? 0 : (hasProgramEarnings ? 0 : 12) + (hasProgramDebt ? 0 : 7)

        let rawScore = 2
            + scaledScore(value: earningsToCost, low: 0.22, high: 1.0, points: 31)
            + scaledInverseScore(value: debtToEarnings, low: 0.10, high: 0.70, points: 25)
            + scaledInverseScore(value: annualNetCost, low: 7_000, high: 50_000, points: 16)
            + scaledScore(value: school.graduationRate, low: 0.35, high: 0.85, points: 12)
            + (Double(school.lumaScore) / 100) * 7
            + completionConfidenceScore(for: program)
            - Double(missingProgramDataPenalty)

        let score = min(98, max(5, Int(rawScore.rounded())))

        return ROIOutcomeResult(
            score: score,
            grade: grade(for: score),
            earnings: earnings,
            debt: debt,
            usedProgramEarnings: hasProgramEarnings,
            usedProgramDebt: hasProgramDebt
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

    private static func completionConfidenceScore(for program: AcademicProgram?) -> Double {
        guard let completionCount = program?.completionCount, completionCount > 0 else {
            return 3
        }

        return scaledScore(
            value: log10(Double(completionCount)),
            low: log10(25),
            high: log10(800),
            points: 11
        )
    }

    private static func grade(for score: Int) -> String {
        if score >= 90 { return "A" }
        if score >= 80 { return "B+" }
        if score >= 70 { return "B" }
        if score >= 55 { return "C+" }
        return "C"
    }
}
