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

enum RepaymentTerm: Int, CaseIterable, Identifiable, Codable {
    case five = 5
    case ten = 10
    case fifteen = 15
    case twenty = 20

    var id: Int { rawValue }

    var title: String {
        "\(rawValue) years"
    }
}

struct SavedRepaymentPlan: Identifiable, Codable, Equatable {
    var id: UUID
    var schoolName: String
    var savedAt: Date
    var repaymentYears: Int
    var principal: Double
    var monthlyPayment: Double
    var totalRepayment: Double
    var interestRate: Double
    var scenarioSummary: String
}

@MainActor
final class CalculatorViewModel: ObservableObject {
    private let savedRepaymentPlansKey = "tuitionluma.savedRepaymentPlans"

    @Published var selectedSchool: School?
    @Published var selectedProgram: AcademicProgram?
    @Published var availablePrograms: [AcademicProgram] = []
    @Published var isLoadingPrograms = false
    @Published var programErrorMessage: String?
    @Published var aidInput: AidInput
    @Published var planningMode: PlanningMode = .student
    @Published var livingScenario: LivingScenario = .onCampus
    @Published var residencyScenario: ResidencyScenario = .inState
    @Published var degreePathScenario: DegreePathScenario = .fourYear
    @Published var repaymentTerm: RepaymentTerm = .ten
    @Published private(set) var savedRepaymentPlans: [SavedRepaymentPlan] = []
    @Published var repaymentSaveMessage: String?

    private let provider: SchoolDataProviding

    init(
        school: School? = nil,
        aidInput: AidInput = .starter,
        provider: SchoolDataProviding = CollegeScorecardService()
    ) {
        self.selectedSchool = school
        self.aidInput = aidInput
        self.provider = provider
        self.savedRepaymentPlans = Self.loadSavedRepaymentPlans()
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
            annualInterestRate: aidInput.interestRate,
            repaymentYears: repaymentTerm.rawValue
        )
    }

    var totalRepayment: Double {
        monthlyPayment * Double(repaymentTerm.rawValue * 12)
    }

    var roiOutcome: ROIOutcomeResult? {
        guard let selectedSchool else { return nil }
        return ROIOutcomeCalculator.result(
            for: selectedSchool,
            program: selectedProgram,
            estimatedNetCost: netAnnualCost
        )
    }

    var annualFamilyContribution: Double {
        aidInput.familyContribution
    }

    var totalFamilyContribution: Double {
        annualFamilyContribution * Double(aidInput.yearsInSchool)
    }

    var annualStudentOutOfPocketGap: Double {
        max(0, netAnnualCost - aidInput.familyContribution - aidInput.annualLoanAmount)
    }

    var annualFamilyFundingGap: Double {
        let plannedAnnualSupport = aidInput.grantsAndScholarships
            + aidInput.workStudy
            + aidInput.familyContribution
            + aidInput.annualLoanAmount
        return max(0, annualCost - plannedAnnualSupport)
    }

    var annualAidTotal: Double {
        aidInput.grantsAndScholarships + aidInput.workStudy
    }

    var scenarioSummary: String {
        "\(livingScenario.rawValue) • \(residencyScenario.rawValue) • \(degreePathScenario.title)"
    }

    var planningModeSummary: String {
        switch planningMode {
        case .student:
            "Student view highlights borrowing, monthly repayment, and the cash gap after loans."
        case .parent:
            "Parent view highlights family contribution, remaining annual gap, and total family support."
        }
    }

    var planningGuidance: String {
        switch planningMode {
        case .student:
            "Use this view to decide whether the loan amount and monthly payment feel manageable after graduation."
        case .parent:
            "Use this view to see what the family is committing each year and whether there is an unfunded gap to solve."
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

    func applySchoolDefaults(for school: School?) {
        selectedSchool = school
        selectedProgram = nil
        availablePrograms = school?.programs ?? []
        programErrorMessage = nil

        guard let school else {
            aidInput = .starter
            return
        }

        let cost = school.costEstimate
        let modeledCost = modeledAnnualCost(for: school)
        let reportedNetPrice = cost.averageNetPrice > 0 ? cost.averageNetPrice : modeledCost
        let estimatedGrantAid = max(0, modeledCost - reportedNetPrice)
        let annualLoanAmount = min(max(reportedNetPrice, 0), 5_500)

        aidInput = AidInput(
            grantsAndScholarships: estimatedGrantAid,
            familyContribution: 0,
            workStudy: 0,
            annualLoanAmount: annualLoanAmount,
            interestRate: aidInput.interestRate,
            yearsInSchool: aidInput.yearsInSchool
        )
    }

    func loadProgramsForSelectedSchool() async {
        guard let selectedSchool else {
            availablePrograms = []
            selectedProgram = nil
            return
        }

        guard let scorecardID = selectedSchool.scorecardID else {
            availablePrograms = selectedSchool.programs
            selectedProgram = nil
            return
        }

        isLoadingPrograms = true
        programErrorMessage = nil
        defer { isLoadingPrograms = false }

        do {
            let programs = try await provider.fetchProgramsForSchool(schoolId: scorecardID)
            availablePrograms = programs
            selectedProgram = nil
        } catch CollegeScorecardError.missingAPIKey {
            availablePrograms = selectedSchool.programs
            selectedProgram = nil
            programErrorMessage = "Set COLLEGE_SCORECARD_API_KEY to load program outcomes."
        } catch let error as CollegeScorecardError {
            availablePrograms = selectedSchool.programs
            selectedProgram = nil
            programErrorMessage = selectedSchool.programs.isEmpty
                ? "Program outcomes are not available right now. You can still use school-wide cost and outcome data."
                : error.localizedDescription
        } catch {
            availablePrograms = selectedSchool.programs
            selectedProgram = nil
            programErrorMessage = selectedSchool.programs.isEmpty ? "Program outcomes are not available for this school yet." : nil
        }
    }

    func saveRepaymentPlan() {
        guard let selectedSchool else {
            repaymentSaveMessage = "Choose a school before saving."
            return
        }

        let plan = SavedRepaymentPlan(
            id: UUID(),
            schoolName: selectedSchool.name,
            savedAt: Date(),
            repaymentYears: repaymentTerm.rawValue,
            principal: loanPrincipal,
            monthlyPayment: monthlyPayment,
            totalRepayment: totalRepayment,
            interestRate: aidInput.interestRate,
            scenarioSummary: scenarioSummary
        )

        savedRepaymentPlans.insert(plan, at: 0)
        savedRepaymentPlans = Array(savedRepaymentPlans.prefix(12))
        persistSavedRepaymentPlans()
        repaymentSaveMessage = "Repayment plan saved. View it below in Saved Plans."
    }

    func deleteSavedRepaymentPlans(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) {
            savedRepaymentPlans.remove(at: index)
        }
        persistSavedRepaymentPlans()
    }

    private func modeledAnnualCost(for school: School) -> Double {
        let cost = school.costEstimate
        var annualCost = cost.estimatedAnnualCost
        let modeledTuition = tuitionForSelectedResidency(in: school)

        if modeledTuition > cost.tuitionAndFees {
            annualCost += modeledTuition - cost.tuitionAndFees
        }

        if livingScenario == .offCampus {
            let livingAdjustment = cost.housingAndMeals > 0 ? cost.housingAndMeals * 0.12 : annualCost * 0.06
            annualCost = max(0, annualCost - livingAdjustment)
        }

        return annualCost
    }

    private func tuitionForSelectedResidency(in school: School) -> Double {
        let cost = school.costEstimate

        guard residencyScenario == .outOfState else {
            return cost.tuitionAndFees
        }

        if let outOfStateTuition = cost.outOfStateTuition,
           outOfStateTuition > cost.tuitionAndFees {
            return outOfStateTuition
        }

        switch school.type {
        case .publicUniversity, .communityCollege:
            return cost.tuitionAndFees > 0 ? cost.tuitionAndFees * 2.35 : cost.outOfStateTuition ?? 0
        case .privateNonprofit, .liberalArts:
            return cost.outOfStateTuition ?? cost.tuitionAndFees
        }
    }

    private func persistSavedRepaymentPlans() {
        if let data = try? JSONEncoder().encode(savedRepaymentPlans) {
            UserDefaults.standard.set(data, forKey: savedRepaymentPlansKey)
        }
    }

    private static func loadSavedRepaymentPlans() -> [SavedRepaymentPlan] {
        guard let data = UserDefaults.standard.data(forKey: "tuitionluma.savedRepaymentPlans"),
              let plans = try? JSONDecoder().decode([SavedRepaymentPlan].self, from: data) else {
            return []
        }

        return plans
    }
}
