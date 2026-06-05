import Foundation

enum SaveSchoolResult {
    case saved
    case removed
    case limitReached
}

@MainActor
final class AppViewModel: ObservableObject {
    @Published private(set) var savedSchoolIDs: Set<School.ID> = []

    let schools: [School]

    init(schools: [School] = MockSchools.all) {
        self.schools = schools
    }

    var savedSchools: [School] {
        schools.filter { savedSchoolIDs.contains($0.id) }
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
}
