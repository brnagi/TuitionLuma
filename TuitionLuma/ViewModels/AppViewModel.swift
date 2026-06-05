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
    @Published private(set) var savedSchoolIDs: Set<School.ID> = []
    @Published private(set) var comparedSchoolIDs: [School.ID] = []

    let schools: [School]

    init(schools: [School] = MockSchools.all) {
        self.schools = schools
        self.savedSchoolIDs = Set(schools.filter(\.isSaved).map(\.id))

        let mockedComparedIDs = schools.filter(\.isCompared).map(\.id)
        self.comparedSchoolIDs = mockedComparedIDs.isEmpty ? Array(schools.prefix(2).map(\.id)) : mockedComparedIDs
    }

    var savedSchools: [School] {
        schools.filter { savedSchoolIDs.contains($0.id) }
    }

    var comparedSchools: [School] {
        comparedSchoolIDs.compactMap { id in
            schools.first { $0.id == id }
        }
    }

    func toggleSaved(_ school: School, savedLimit: Int? = nil) -> SaveSchoolResult {
        if savedSchoolIDs.contains(school.id) {
            savedSchoolIDs.remove(school.id)
            return .removed
        }

        if let savedLimit, savedSchoolIDs.count >= savedLimit {
            return .limitReached
        } else {
            savedSchoolIDs.insert(school.id)
            return .saved
        }
    }

    func isSaved(_ school: School) -> Bool {
        savedSchoolIDs.contains(school.id)
    }

    func addToCompare(_ school: School, compareLimit: Int) -> CompareSchoolResult {
        if comparedSchoolIDs.contains(school.id) {
            return .alreadyCompared
        }

        guard comparedSchoolIDs.count < compareLimit else {
            return .limitReached
        }

        comparedSchoolIDs.append(school.id)
        return .added
    }

    func removeFromCompare(_ school: School) -> CompareSchoolResult {
        guard comparedSchoolIDs.contains(school.id) else {
            return .alreadyCompared
        }

        comparedSchoolIDs.removeAll { $0 == school.id }
        return .removed
    }

    func replaceComparedSchool(at index: Int, with school: School) {
        guard comparedSchoolIDs.indices.contains(index) else { return }

        if let existingIndex = comparedSchoolIDs.firstIndex(of: school.id), existingIndex != index {
            comparedSchoolIDs.remove(at: existingIndex)
        }

        comparedSchoolIDs[index] = school.id
    }

    func trimComparedSchools(to limit: Int) {
        guard comparedSchoolIDs.count > limit else { return }
        comparedSchoolIDs = Array(comparedSchoolIDs.prefix(limit))
    }

    func isCompared(_ school: School) -> Bool {
        comparedSchoolIDs.contains(school.id)
    }
}
