import Foundation

struct AidInput: Hashable {
    var grantsAndScholarships: Double
    var familyContribution: Double
    var workStudy: Double
    var annualLoanAmount: Double
    var interestRate: Double
    var yearsInSchool: Int

    static let starter = AidInput(
        grantsAndScholarships: 10_000,
        familyContribution: 5_000,
        workStudy: 2_000,
        annualLoanAmount: 7_500,
        interestRate: 0.055,
        yearsInSchool: 4
    )
}
