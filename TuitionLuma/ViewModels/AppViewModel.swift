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

@MainActor
final class AppViewModel: ObservableObject {
    private enum StorageKey {
        static let savedSchoolIDs = "tuitionLuma.savedSchoolIDs"
        static let comparedSchoolIDs = "tuitionLuma.comparedSchoolIDs"
    }

    @Published private(set) var knownSchools: [School] = []
    @Published private(set) var savedSchools: [School] = []
    @Published private(set) var comparedSchools: [School] = []

    private var savedSchoolIDStrings: [String]
    private var comparedSchoolIDStrings: [String]
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.savedSchoolIDStrings = userDefaults.stringArray(forKey: StorageKey.savedSchoolIDs) ?? []
        self.comparedSchoolIDStrings = userDefaults.stringArray(forKey: StorageKey.comparedSchoolIDs) ?? []
    }

    var comparedSchoolIDs: [School.ID] {
        comparedSchools.map(\.id)
    }

    func remember(_ schools: [School]) {
        for school in schools where !knownSchools.contains(where: { $0.id == school.id }) {
            knownSchools.append(school)
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

        if let savedLimit, savedSchoolIDStrings.count >= savedLimit {
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
}

private extension School {
    var idString: String {
        String(describing: id)
    }
}
