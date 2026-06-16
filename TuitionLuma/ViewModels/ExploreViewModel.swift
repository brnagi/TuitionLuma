import Foundation

enum LoadState: Equatable {
    case idle
    case loading
    case loaded
    case empty
    case missingAPIKey
    case failed(String)
}

@MainActor
final class ExploreViewModel: ObservableObject {
    @Published var schools: [School] = []
    @Published var query = ""
    @Published var selectedType: School.SchoolType?
    @Published var loadState: LoadState = .idle
    @Published var isLoadingMore = false

    private let provider: SchoolDataProviding
    private var currentPage = 0
    private var hasMoreResults = false
    private let perPage = 20
    private var programCache: [Int: [AcademicProgram]] = [:]
    private var failedProgramSchoolIDs: Set<Int> = []

    init(provider: SchoolDataProviding = CollegeScorecardService()) {
        self.provider = provider
    }

    var visibleSchools: [School] {
        guard let selectedType else { return schools }
        return schools.filter { $0.type == selectedType }
    }

    var canLoadMore: Bool {
        hasMoreResults && loadState == .loaded && !isLoadingMore
    }

    func refreshForCurrentQuery(homeState: String? = nil) async {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        currentPage = 0
        hasMoreResults = false
        loadState = .loading

        do {
            let page = try await fetchPage(query: trimmedQuery, page: 0, homeState: homeState)
            schools = rankedSchools(page.schools, query: trimmedQuery)
            hasMoreResults = page.hasMore
            loadState = schools.isEmpty ? .empty : .loaded
        } catch CollegeScorecardError.missingAPIKey {
            schools = []
            loadState = .missingAPIKey
        } catch {
            schools = []
            loadState = .failed(userFacingMessage(for: error))
        }
    }

    func searchDebounced(homeState: String? = nil) async {
        try? await Task.sleep(nanoseconds: 350_000_000)
        guard !Task.isCancelled else { return }
        await refreshForCurrentQuery(homeState: homeState)
    }

    func loadMore(homeState: String? = nil) async {
        guard canLoadMore else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            let nextPage = currentPage + 1
            let page = try await fetchPage(query: query.trimmingCharacters(in: .whitespacesAndNewlines), page: nextPage, homeState: homeState)
            currentPage = page.page
            hasMoreResults = page.hasMore
            schools.append(contentsOf: rankedSchools(page.schools, query: query))
        } catch {
            hasMoreResults = false
            if schools.isEmpty {
                loadState = .failed(userFacingMessage(for: error))
            } else {
                loadState = .loaded
            }
        }
    }

    func refreshProgramsForMajorRecommendations(profile: StudentProfile) async {
        guard profile.isComplete else { return }

        let keywords = StudentProfileRecommendationEngine.majorKeywords(from: profile.normalizedMajor)
        guard !keywords.isEmpty else { return }

        var updatedSchools = schools

        for index in updatedSchools.indices {
            guard updatedSchools[index].programs.isEmpty,
                  let scorecardID = updatedSchools[index].scorecardID else {
                continue
            }

            if let cachedPrograms = programCache[scorecardID] {
                updatedSchools[index].programs = cachedPrograms
                continue
            }

            guard !failedProgramSchoolIDs.contains(scorecardID) else { continue }

            do {
                let programs = try await provider.fetchProgramsForSchool(schoolId: scorecardID)
                programCache[scorecardID] = programs
                updatedSchools[index].programs = programs
            } catch {
                failedProgramSchoolIDs.insert(scorecardID)
                continue
            }
        }

        schools = updatedSchools
    }

    func useSampleFallback() {
        schools = MockSchools.all
        hasMoreResults = false
        currentPage = 0
        loadState = .loaded
    }

    private func fetchPage(query: String, page: Int, homeState: String? = nil) async throws -> PaginatedSchools {
        let result: PaginatedSchools

        if query.count == 2, query.rangeOfCharacter(from: CharacterSet.letters.inverted) == nil {
            result = try await provider.fetchSchoolsByState(state: query, page: page, perPage: perPage)
        } else if query.isEmpty {
            let normalizedHomeState = homeState?.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() ?? ""
            if normalizedHomeState.count == 2 {
                result = try await provider.fetchSchoolsByState(state: normalizedHomeState, page: page, perPage: perPage)
            } else {
                result = try await provider.fetchFeaturedSchools(page: page, perPage: perPage)
            }
        } else {
            result = try await provider.searchSchools(query: query, page: page, perPage: perPage)
        }

        currentPage = result.page
        return result
    }

    private func rankedSchools(_ schools: [School], query: String) -> [School] {
        let normalizedQuery = normalizedSearchText(query)
        guard !normalizedQuery.isEmpty, normalizedQuery.count > 2 else {
            return schools
        }

        return schools.enumerated().sorted { lhs, rhs in
            let leftRank = searchRank(for: lhs.element.name, query: normalizedQuery)
            let rightRank = searchRank(for: rhs.element.name, query: normalizedQuery)

            if leftRank == rightRank {
                return lhs.offset < rhs.offset
            }

            return leftRank < rightRank
        }.map(\.element)
    }

    private func searchRank(for name: String, query: String) -> Int {
        let normalizedName = normalizedSearchText(name)

        if normalizedName == query {
            return 0
        }

        if normalizedName.hasPrefix(query) {
            return 1
        }

        return 2
    }

    private func normalizedSearchText(_ text: String) -> String {
        text
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }

    private func userFacingMessage(for error: Error) -> String {
        if let scorecardError = error as? CollegeScorecardError {
            return scorecardError.localizedDescription
        }

        return "TuitionLuma could not load live college data. Check your connection and try again."
    }
}
