import Foundation

enum PlanningMode: String, CaseIterable, Identifiable {
    case student = "Student"
    case parent = "Parent"

    var id: String { rawValue }
}

enum LivingScenario: String, CaseIterable, Identifiable {
    case onCampus = "On campus"
    case offCampus = "Off campus"

    var id: String { rawValue }
}

enum ResidencyScenario: String, CaseIterable, Identifiable {
    case inState = "In-state"
    case outOfState = "Out-of-state"

    var id: String { rawValue }
}

enum DegreePathScenario: Int, CaseIterable, Identifiable {
    case twoYear = 2
    case fourYear = 4

    var id: Int { rawValue }

    var title: String {
        "\(rawValue)-year path"
    }
}

@MainActor
final class CalculatorViewModel: ObservableObject {
    @Published var selectedSchool: School?
    @Published var aidInput: AidInput
    @Published var planningMode: PlanningMode = .student
    @Published var livingScenario: LivingScenario = .onCampus
    @Published var residencyScenario: ResidencyScenario = .inState
    @Published var degreePathScenario: DegreePathScenario = .fourYear

    init(school: School? = nil, aidInput: AidInput = .starter) {
        self.selectedSchool = school
        self.aidInput = aidInput
    }

    var annualCost: Double {
        selectedSchool.map { modeledAnnualCost(for: $0) } ?? 0
    }

    var totalDegreeCost: Double {
        annualCost * Double(aidInput.yearsInSchool)
    }

    var netAnnualCost: Double {
        max(0, annualCost - annualAidTotal)
    }

    var netTotalCost: Double {
        netAnnualCost * Double(aidInput.yearsInSchool)
    }

    var loanPrincipal: Double {
        min(netTotalCost, aidInput.annualLoanAmount * Double(aidInput.yearsInSchool))
    }

    var monthlyPayment: Double {
        CalculatorEngine.monthlyLoanPayment(
            principal: loanPrincipal,
            annualInterestRate: aidInput.interestRate
        )
    }

    var totalTenYearRepayment: Double {
        monthlyPayment * 120
    }

    var annualAidTotal: Double {
        aidInput.grantsAndScholarships + aidInput.familyContribution + aidInput.workStudy
    }

    var scenarioSummary: String {
        "\(livingScenario.rawValue) • \(residencyScenario.rawValue) • \(degreePathScenario.title)"
    }

    var planningModeSummary: String {
        switch planningMode {
        case .student:
            "Student view focuses on yearly cost, borrowing, and monthly repayment."
        case .parent:
            "Parent view highlights family contribution, aid gaps, and total plan cost."
        }
    }

    var affordabilityFocus: String {
        switch planningMode {
        case .student:
            "Student focus"
        case .parent:
            "Family focus"
        }
    }

    func selectDegreePath(_ scenario: DegreePathScenario) {
        degreePathScenario = scenario
        aidInput.yearsInSchool = scenario.rawValue
    }

    private func modeledAnnualCost(for school: School) -> Double {
        let cost = school.costEstimate
        var annualCost = cost.estimatedAnnualCost

        if residencyScenario == .outOfState,
           let outOfStateTuition = cost.outOfStateTuition,
           outOfStateTuition > cost.tuitionAndFees {
            annualCost += outOfStateTuition - cost.tuitionAndFees
        }

        if livingScenario == .offCampus {
            let livingAdjustment = cost.housingAndMeals > 0 ? cost.housingAndMeals * 0.12 : annualCost * 0.06
            annualCost = max(0, annualCost - livingAdjustment)
        }

        return annualCost
    }
}
