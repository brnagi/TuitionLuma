import Foundation

enum LoadState: Equatable {
    case idle
    case loading
    case loaded
    case empty
    case failed(String)
}

@MainActor
final class ExploreViewModel: ObservableObject {
    @Published var schools: [School] = []
    @Published var query = ""
    @Published var selectedType: School.SchoolType?
    @Published var loadState: LoadState = .idle

    private let provider: SchoolDataProviding

    init(provider: SchoolDataProviding = MockSchoolService()) {
        self.provider = provider
    }

    var filteredSchools: [School] {
        let searched = query.trimmingCharacters(in: .whitespacesAndNewlines)

        return schools.filter { school in
            let matchesQuery = searched.isEmpty
                || school.name.localizedCaseInsensitiveContains(searched)
                || school.city.localizedCaseInsensitiveContains(searched)
                || school.state.localizedCaseInsensitiveContains(searched)
                || school.programs.contains { $0.name.localizedCaseInsensitiveContains(searched) }

            let matchesType = selectedType == nil || school.type == selectedType
            return matchesQuery && matchesType
        }
    }

    func load() async {
        loadState = .loading

        do {
            schools = try await provider.fetchSchools()
            loadState = schools.isEmpty ? .empty : .loaded
        } catch {
            loadState = .failed("We could not load schools right now. Try again in a moment.")
        }
    }
}
