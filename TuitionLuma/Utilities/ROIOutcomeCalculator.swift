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
        let earningsRatio = earnings / netCost
        let debtRatio = earnings / max(debt, 1)
        let graduationSignal = max(0.30, school.graduationRate)

        let rawScore = earningsRatio * 14
            + debtRatio * 9
            + Double(school.lumaScore) * 0.38
            + graduationSignal * 16

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

    private static func grade(for score: Int) -> String {
        if score >= 92 { return "A" }
        if score >= 84 { return "B+" }
        if score >= 76 { return "B" }
        if score >= 66 { return "C+" }
        return "C"
    }
}
