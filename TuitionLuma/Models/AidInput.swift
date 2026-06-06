import Foundation

struct AidInput: Hashable {
    var grantsAndScholarships: Double
    var familyContribution: Double
    var workStudy: Double
    var annualLoanAmount: Double
    var interestRate: Double
    var yearsInSchool: Int

    static let starter = AidInput(
        grantsAndScholarships: 0,
        familyContribution: 0,
        workStudy: 0,
        annualLoanAmount: 5_500,
        interestRate: 0.055,
        yearsInSchool: 4
    )
}
