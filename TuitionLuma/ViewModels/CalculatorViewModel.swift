import Foundation

@MainActor
final class CalculatorViewModel: ObservableObject {
    @Published var selectedSchool: School
    @Published var aidInput: AidInput

    init(school: School = MockSchools.all[0], aidInput: AidInput = .starter) {
        self.selectedSchool = school
        self.aidInput = aidInput
    }

    var annualCost: Double {
        CalculatorEngine.annualCost(for: selectedSchool)
    }

    var totalDegreeCost: Double {
        CalculatorEngine.totalDegreeCost(for: selectedSchool, years: aidInput.yearsInSchool)
    }

    var netAnnualCost: Double {
        CalculatorEngine.netAnnualCost(for: selectedSchool, aid: aidInput)
    }

    var netTotalCost: Double {
        CalculatorEngine.netTotalCost(for: selectedSchool, aid: aidInput)
    }

    var loanPrincipal: Double {
        CalculatorEngine.loanPrincipal(for: selectedSchool, aid: aidInput)
    }

    var monthlyPayment: Double {
        CalculatorEngine.monthlyLoanPayment(for: selectedSchool, aid: aidInput)
    }

    var totalTenYearRepayment: Double {
        CalculatorEngine.totalTenYearRepayment(for: selectedSchool, aid: aidInput)
    }
}
