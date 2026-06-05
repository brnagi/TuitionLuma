import Foundation

@MainActor
final class AppViewModel: ObservableObject {
    @Published var hasCompletedOnboarding = false
    @Published private(set) var savedSchoolIDs: Set<School.ID> = []

    let schools: [School]

    init(schools: [School] = MockSchools.all) {
        self.schools = schools
    }

    var savedSchools: [School] {
        schools.filter { savedSchoolIDs.contains($0.id) }
    }

    func toggleSaved(_ school: School) {
        if savedSchoolIDs.contains(school.id) {
            savedSchoolIDs.remove(school.id)
        } else {
            savedSchoolIDs.insert(school.id)
        }
    }

    func isSaved(_ school: School) -> Bool {
        savedSchoolIDs.contains(school.id)
    }
}
