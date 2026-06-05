import Foundation

protocol SchoolDataProviding {
    func fetchSchools() async throws -> [School]
}

struct MockSchoolService: SchoolDataProviding {
    func fetchSchools() async throws -> [School] {
        MockSchools.all
    }
}

struct CollegeScorecardService: SchoolDataProviding {
    func fetchSchools() async throws -> [School] {
        // TODO: Integrate College Scorecard API.
        // Map API fields into School, Program, and CostEstimate while keeping the app's view models unchanged.
        throw URLError(.badServerResponse)
    }
}
