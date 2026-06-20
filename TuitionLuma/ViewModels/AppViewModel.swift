import Foundation

enum SaveSchoolResult {
    case saved
    case removed
    case limitReached
}

enum CompareSchoolResult {
    case added
    case removed
    case alreadyCompared
    case limitReached
}

struct SavedProgramChoice: Codable, Equatable {
    var name: String
    var credential: String
    var cipCode: String?
    var medianEarnings: Double? = nil
    var debt: Double? = nil
    var category: String? = nil
    var typicalDurationYears: Int? = nil
}

struct SavedAidPlan: Codable, Equatable {
    var aidInput: AidInput
    var annualCost: Double
    var netAnnualCost: Double
    var netTotalCost: Double
    var annualAidTotal: Double
    var loanPrincipal: Double
    var monthlyPayment: Double
    var totalRepayment: Double
    var scenarioSummary: String
    var updatedAt: Date
}

@MainActor
final class AppViewModel: ObservableObject {
    private enum StorageKey {
        static let savedSchoolIDs = "tuitionLuma.savedSchoolIDs"
        static let comparedSchoolIDs = "tuitionLuma.comparedSchoolIDs"
        static let savedProgramChoices = "tuitionLuma.savedProgramChoices"
        static let savedAidPlans = "tuitionLuma.savedAidPlans"
    }

    @Published private(set) var knownSchools: [School] = []
    @Published private(set) var savedSchools: [School] = []
    @Published private(set) var comparedSchools: [School] = []
    @Published private(set) var savedProgramChoices: [String: SavedProgramChoice] = [:]
    @Published private(set) var savedAidPlans: [String: SavedAidPlan] = [:]

    private var savedSchoolIDStrings: [String]
    private var comparedSchoolIDStrings: [String]
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.savedSchoolIDStrings = userDefaults.stringArray(forKey: StorageKey.savedSchoolIDs) ?? []
        self.comparedSchoolIDStrings = userDefaults.stringArray(forKey: StorageKey.comparedSchoolIDs) ?? []
        self.savedProgramChoices = Self.loadSavedProgramChoices(from: userDefaults)
        self.savedAidPlans = Self.loadSavedAidPlans(from: userDefaults)
    }

    var comparedSchoolIDs: [School.ID] {
        comparedSchools.map(\.id)
    }

    func remember(_ schools: [School]) {
        for school in schools {
            if let index = knownSchools.firstIndex(where: { $0.id == school.id }) {
                knownSchools[index] = school
            } else {
                knownSchools.append(school)
            }
        }

        restorePersistedSchools()
    }

    func toggleSaved(_ school: School, savedLimit: Int? = nil) -> SaveSchoolResult {
        if let index = savedSchools.firstIndex(where: { $0.id == school.id }) {
            savedSchools.remove(at: index)
            savedSchoolIDStrings.removeAll { $0 == school.idString }
            persistSavedSchools()
            return .removed
        }

        if let savedLimit, savedSchools.count >= savedLimit {
            return .limitReached
        }

        savedSchools.append(school)
        if !savedSchoolIDStrings.contains(school.idString) {
            savedSchoolIDStrings.append(school.idString)
        }
        remember([school])
        persistSavedSchools()
        return .saved
    }

    func isSaved(_ school: School) -> Bool {
        savedSchoolIDStrings.contains(school.idString)
    }

    func addToCompare(_ school: School, compareLimit: Int) -> CompareSchoolResult {
        let enforcedLimit = min(compareLimit, 3)

        if comparedSchoolIDStrings.contains(school.idString) {
            return .alreadyCompared
        }

        guard comparedSchoolIDStrings.count < enforcedLimit else {
            return .limitReached
        }

        comparedSchools.append(school)
        comparedSchoolIDStrings.append(school.idString)
        remember([school])
        persistComparedSchools()
        return .added
    }

    func removeFromCompare(_ school: School) -> CompareSchoolResult {
        guard comparedSchoolIDStrings.contains(school.idString) else {
            return .alreadyCompared
        }

        comparedSchools.removeAll { $0.id == school.id }
        comparedSchoolIDStrings.removeAll { $0 == school.idString }
        persistComparedSchools()
        return .removed
    }

    func replaceComparedSchool(at index: Int, with school: School) {
        guard comparedSchools.indices.contains(index) else { return }

        var updatedSchools = comparedSchools
        updatedSchools[index] = school

        var seenIDs: Set<School.ID> = []
        comparedSchools = updatedSchools.filter { school in
            seenIDs.insert(school.id).inserted
        }

        comparedSchoolIDStrings = comparedSchools.map(\.idString)
        remember([school])
        persistComparedSchools()
    }

    func trimComparedSchools(to limit: Int) {
        let enforcedLimit = min(limit, 3)
        guard comparedSchoolIDStrings.count > enforcedLimit else { return }
        comparedSchools = Array(comparedSchools.prefix(enforcedLimit))
        comparedSchoolIDStrings = Array(comparedSchoolIDStrings.prefix(enforcedLimit))
        persistComparedSchools()
    }

    func isCompared(_ school: School) -> Bool {
        comparedSchoolIDStrings.contains(school.idString)
    }

    func savePreferredProgram(_ program: AcademicProgram?, for school: School) {
        if let program {
            savedProgramChoices[school.idString] = SavedProgramChoice(
                name: program.name,
                credential: program.credential,
                cipCode: program.cipCode,
                medianEarnings: program.medianEarnings,
                debt: program.debt,
                category: program.category,
                typicalDurationYears: program.typicalDurationYears
            )
        } else {
            savedProgramChoices.removeValue(forKey: school.idString)
        }

        remember([school])
        persistSavedProgramChoices()
    }

    func preferredProgramChoice(for school: School) -> SavedProgramChoice? {
        savedProgramChoices[school.idString]
    }

    func saveAidPlan(_ plan: SavedAidPlan, for school: School) {
        guard isSaved(school) else { return }

        savedAidPlans[school.idString] = plan
        remember([school])
        persistSavedAidPlans()
    }

    func savedAidPlan(for school: School) -> SavedAidPlan? {
        savedAidPlans[school.idString]
    }

    func preferredProgram(for school: School, in programs: [AcademicProgram]) -> AcademicProgram? {
        guard let choice = preferredProgramChoice(for: school) else { return nil }

        return programs.first { program in
            choice.matches(program)
        }
    }

    func isPreferredProgram(_ program: AcademicProgram, for school: School) -> Bool {
        preferredProgramChoice(for: school)?.matches(program) == true
    }

    private func restorePersistedSchools() {
        savedSchools = schools(matching: savedSchoolIDStrings)
        comparedSchools = schools(matching: comparedSchoolIDStrings)
    }

    private func schools(matching idStrings: [String]) -> [School] {
        idStrings.compactMap { idString in
            knownSchools.first { $0.idString == idString }
        }
    }

    private func persistSavedSchools() {
        userDefaults.set(savedSchoolIDStrings, forKey: StorageKey.savedSchoolIDs)
    }

    private func persistComparedSchools() {
        userDefaults.set(comparedSchoolIDStrings, forKey: StorageKey.comparedSchoolIDs)
    }

    private func persistSavedProgramChoices() {
        if let data = try? JSONEncoder().encode(savedProgramChoices) {
            userDefaults.set(data, forKey: StorageKey.savedProgramChoices)
        }
    }

    private func persistSavedAidPlans() {
        if let data = try? JSONEncoder().encode(savedAidPlans) {
            userDefaults.set(data, forKey: StorageKey.savedAidPlans)
        }
    }

    private static func loadSavedProgramChoices(from userDefaults: UserDefaults) -> [String: SavedProgramChoice] {
        guard let data = userDefaults.data(forKey: StorageKey.savedProgramChoices),
              let choices = try? JSONDecoder().decode([String: SavedProgramChoice].self, from: data) else {
            return [:]
        }

        return choices
    }

    private static func loadSavedAidPlans(from userDefaults: UserDefaults) -> [String: SavedAidPlan] {
        guard let data = userDefaults.data(forKey: StorageKey.savedAidPlans),
              let plans = try? JSONDecoder().decode([String: SavedAidPlan].self, from: data) else {
            return [:]
        }

        return plans
    }
}

private extension School {
    var idString: String {
        String(describing: id)
    }
}

private extension SavedProgramChoice {
    func matches(_ program: AcademicProgram) -> Bool {
        if let cipCode, let programCIPCode = program.cipCode, normalized(cipCode) == normalized(programCIPCode) {
            return normalized(credential) == normalized(program.credential)
        }

        return normalized(name) == normalized(program.name)
            && normalized(credential) == normalized(program.credential)
    }

    private func normalized(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
    }
}
