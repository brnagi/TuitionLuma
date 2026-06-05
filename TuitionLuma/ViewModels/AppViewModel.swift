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
    @Published private(set) var knownSchools: [School] = []
    @Published private(set) var savedSchools: [School] = []
    @Published private(set) var comparedSchools: [School] = []

    var comparedSchoolIDs: [School.ID] {
        comparedSchools.map(\.id)
    }

    func remember(_ schools: [School]) {
        for school in schools where !knownSchools.contains(where: { $0.id == school.id }) {
            knownSchools.append(school)
        }
    }

    func toggleSaved(_ school: School, savedLimit: Int? = nil) -> SaveSchoolResult {
        if let index = savedSchools.firstIndex(where: { $0.id == school.id }) {
            savedSchools.remove(at: index)
            return .removed
        }

        if let savedLimit, savedSchools.count >= savedLimit {
            return .limitReached
        }

        savedSchools.append(school)
        remember([school])
        return .saved
    }

    func isSaved(_ school: School) -> Bool {
        savedSchools.contains { $0.id == school.id }
    }

    func addToCompare(_ school: School, compareLimit: Int) -> CompareSchoolResult {
        if comparedSchools.contains(where: { $0.id == school.id }) {
            return .alreadyCompared
        }

        guard comparedSchools.count < compareLimit else {
            return .limitReached
        }

        comparedSchools.append(school)
        remember([school])
        return .added
    }

    func removeFromCompare(_ school: School) -> CompareSchoolResult {
        guard comparedSchools.contains(where: { $0.id == school.id }) else {
            return .alreadyCompared
        }

        comparedSchools.removeAll { $0.id == school.id }
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

        remember([school])
    }

    func trimComparedSchools(to limit: Int) {
        guard comparedSchools.count > limit else { return }
        comparedSchools = Array(comparedSchools.prefix(limit))
    }

    func isCompared(_ school: School) -> Bool {
        comparedSchools.contains { $0.id == school.id }
    }
}
