import Foundation

@MainActor
final class CalculatorViewModel: ObservableObject {
    @Published var selectedSchool: School?
    @Published var aidInput: AidInput

    init(school: School? = nil, aidInput: AidInput = .starter) {
        self.selectedSchool = school
        self.aidInput = aidInput
    }

    var annualCost: Double {
        selectedSchool.map { CalculatorEngine.annualCost(for: $0) } ?? 0
    }

    var totalDegreeCost: Double {
        selectedSchool.map { CalculatorEngine.totalDegreeCost(for: $0, years: aidInput.yearsInSchool) } ?? 0
    }

    var netAnnualCost: Double {
        selectedSchool.map { CalculatorEngine.netAnnualCost(for: $0, aid: aidInput) } ?? 0
    }

    var netTotalCost: Double {
        selectedSchool.map { CalculatorEngine.netTotalCost(for: $0, aid: aidInput) } ?? 0
    }

    var loanPrincipal: Double {
        selectedSchool.map { CalculatorEngine.loanPrincipal(for: $0, aid: aidInput) } ?? 0
    }

    var monthlyPayment: Double {
        selectedSchool.map { CalculatorEngine.monthlyLoanPayment(for: $0, aid: aidInput) } ?? 0
    }

    var totalTenYearRepayment: Double {
        selectedSchool.map { CalculatorEngine.totalTenYearRepayment(for: $0, aid: aidInput) } ?? 0
    }
}
