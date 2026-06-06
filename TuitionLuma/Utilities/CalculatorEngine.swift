import Foundation

enum CalculatorEngine {
    static func annualCost(for school: School) -> Double {
        school.costEstimate.estimatedAnnualCost
    }

    static func totalDegreeCost(for school: School, years: Int) -> Double {
        annualCost(for: school) * Double(years)
    }

    static func netAnnualCost(for school: School, aid: AidInput) -> Double {
        let aidTotal = aid.grantsAndScholarships + aid.workStudy
        return max(0, annualCost(for: school) - aidTotal)
    }

    static func netTotalCost(for school: School, aid: AidInput) -> Double {
        netAnnualCost(for: school, aid: aid) * Double(aid.yearsInSchool)
    }

    static func loanPrincipal(for school: School, aid: AidInput) -> Double {
        min(netTotalCost(for: school, aid: aid), aid.annualLoanAmount * Double(aid.yearsInSchool))
    }

    static func monthlyLoanPayment(principal: Double, annualInterestRate: Double, repaymentYears: Int = 10) -> Double {
        guard principal > 0 else { return 0 }

        let monthCount = Double(repaymentYears * 12)
        let monthlyRate = annualInterestRate / 12

        guard monthlyRate > 0 else {
            return principal / monthCount
        }

        let growth = pow(1 + monthlyRate, monthCount)
        return principal * (monthlyRate * growth) / (growth - 1)
    }

    static func monthlyLoanPayment(for school: School, aid: AidInput) -> Double {
        monthlyLoanPayment(
            principal: loanPrincipal(for: school, aid: aid),
            annualInterestRate: aid.interestRate
        )
    }

    static func totalTenYearRepayment(for school: School, aid: AidInput) -> Double {
        monthlyLoanPayment(for: school, aid: aid) * 120
    }
}
