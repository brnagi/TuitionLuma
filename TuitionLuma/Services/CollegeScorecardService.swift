import Foundation

enum CollegeScorecardError: LocalizedError, Equatable {
    case missingAPIKey
    case invalidURL
    case requestFailed(Int)
    case noResults
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            "Add COLLEGE_SCORECARD_API_KEY to use live College Scorecard data."
        case .invalidURL:
            "TuitionLuma could not build a College Scorecard request."
        case .requestFailed(let statusCode):
            "College Scorecard returned HTTP \(statusCode)."
        case .noResults:
            "No colleges matched this request."
        case .decodingFailed:
            "TuitionLuma could not read the College Scorecard response."
        }
    }
}

struct PaginatedSchools {
    var schools: [School]
    var page: Int
    var perPage: Int
    var total: Int

    var hasMore: Bool {
        (page + 1) * perPage < total
    }
}

protocol SchoolDataProviding {
    func searchSchools(query: String, page: Int, perPage: Int) async throws -> PaginatedSchools
    func fetchSchoolDetails(schoolId: Int) async throws -> School
    func fetchProgramsForSchool(schoolId: Int) async throws -> [Program]
    func fetchSchoolsByState(state: String, page: Int, perPage: Int) async throws -> PaginatedSchools
    func fetchFeaturedSchools(page: Int, perPage: Int) async throws -> PaginatedSchools
}

enum APIConfig {
    static var collegeScorecardAPIKey: String? {
        if let value = ProcessInfo.processInfo.environment["COLLEGE_SCORECARD_API_KEY"], !value.isEmpty {
            return value
        }

        for key in ["CollegeScorecardAPIKey", "COLLEGE_SCORECARD_API_KEY"] {
            if let value = Bundle.main.object(forInfoDictionaryKey: key) as? String,
               !value.isEmpty,
               !value.hasPrefix("$(") {
                return value
            }
        }

        return nil
    }
}

struct CollegeScorecardService: SchoolDataProviding {
    private let baseURL = URL(string: "https://api.data.gov/ed/collegescorecard/v1/schools")!
    private let session: URLSession
    private let apiKey: String?

    private let schoolFields = [
        "id",
        "school.name",
        "school.city",
        "school.state",
        "school.school_url",
        "school.ownership",
        "school.degrees_awarded.predominant",
        "latest.cost.tuition.in_state",
        "latest.cost.tuition.out_of_state",
        "latest.cost.avg_net_price.overall",
        "latest.cost.attendance.academic_year",
        "latest.completion.rate_suppressed.overall",
        "latest.admissions.admission_rate.overall",
        "latest.earnings.10_yrs_after_entry.median",
        "latest.aid.median_debt.completers.overall",
        "latest.student.size"
    ]

    init(session: URLSession = .shared, apiKey: String? = APIConfig.collegeScorecardAPIKey) {
        self.session = session
        self.apiKey = apiKey
    }

    func searchSchools(query: String, page: Int = 0, perPage: Int = 20) async throws -> PaginatedSchools {
        var parameters = baseParameters(page: page, perPage: perPage)
        parameters["school.name"] = query
        parameters["school.degrees_awarded.predominant"] = "2,3"
        parameters["sort"] = "latest.student.size:desc"
        return try await fetchSchools(parameters: parameters)
    }

    func fetchSchoolDetails(schoolId: Int) async throws -> School {
        var parameters = baseParameters(page: 0, perPage: 1)
        parameters["id"] = String(schoolId)
        let page = try await fetchSchools(parameters: parameters)

        guard let school = page.schools.first else {
            throw CollegeScorecardError.noResults
        }

        return school
    }

    func fetchProgramsForSchool(schoolId: Int) async throws -> [Program] {
        var parameters = [
            "id": String(schoolId),
            "fields": "id,latest.programs.cip_4_digit",
            "all_programs_nested": "true",
            "per_page": "1",
            "page": "0"
        ]
        parameters["api_key"] = try requireAPIKey()

        let response = try await request(parameters: parameters)
        guard let first = response.results.first else { return [] }

        let programValues = first.array("latest.programs.cip_4_digit")
            ?? first.value(at: ["latest", "programs", "cip_4_digit"])?.arrayValue
            ?? []

        return programValues.compactMap { value in
            guard case .object(let object) = value else { return nil }
            return mapProgram(object)
        }
        .sorted { $0.medianEarnings > $1.medianEarnings }
    }

    func fetchSchoolsByState(state: String, page: Int = 0, perPage: Int = 20) async throws -> PaginatedSchools {
        var parameters = baseParameters(page: page, perPage: perPage)
        parameters["school.state"] = state.uppercased()
        parameters["school.degrees_awarded.predominant"] = "2,3"
        parameters["sort"] = "latest.student.size:desc"
        return try await fetchSchools(parameters: parameters)
    }

    func fetchFeaturedSchools(page: Int = 0, perPage: Int = 20) async throws -> PaginatedSchools {
        var parameters = baseParameters(page: page, perPage: perPage)
        parameters["school.degrees_awarded.predominant"] = "2,3"
        parameters["latest.student.size__range"] = "2000.."
        parameters["sort"] = "latest.student.size:desc"
        return try await fetchSchools(parameters: parameters)
    }

    private func baseParameters(page: Int, perPage: Int) -> [String: String] {
        [
            "fields": schoolFields.joined(separator: ","),
            "page": String(page),
            "per_page": String(perPage)
        ]
    }

    private func fetchSchools(parameters: [String: String]) async throws -> PaginatedSchools {
        var requestParameters = parameters
        requestParameters["api_key"] = try requireAPIKey()

        let response = try await request(parameters: requestParameters)
        let schools = response.results.map(mapSchool)

        return PaginatedSchools(
            schools: schools,
            page: response.metadata.page,
            perPage: response.metadata.perPage,
            total: response.metadata.total
        )
    }

    private func requireAPIKey() throws -> String {
        guard let apiKey, !apiKey.isEmpty else {
            throw CollegeScorecardError.missingAPIKey
        }

        return apiKey
    }

    private func request(parameters: [String: String]) async throws -> ScorecardResponse {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            throw CollegeScorecardError.invalidURL
        }

        components.queryItems = parameters
            .sorted { $0.key < $1.key }
            .map { URLQueryItem(name: $0.key, value: $0.value) }

        guard let url = components.url else {
            throw CollegeScorecardError.invalidURL
        }

        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CollegeScorecardError.decodingFailed
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw CollegeScorecardError.requestFailed(httpResponse.statusCode)
        }

        do {
            return try JSONDecoder().decode(ScorecardResponse.self, from: data)
        } catch {
            throw CollegeScorecardError.decodingFailed
        }
    }

    private func mapSchool(_ object: [String: ScorecardValue]) -> School {
        let schoolID = object.int("id")
        let name = object.string("school.name") ?? "Unknown college"
        let city = object.string("school.city") ?? "Unknown city"
        let state = object.string("school.state") ?? ""
        let schoolWebsite = object.string("school.school_url")
        let ownership = object.int("school.ownership")
        let tuitionInState = object.double("latest.cost.tuition.in_state")
        let tuitionOutOfState = object.double("latest.cost.tuition.out_of_state")
        let averageNetPrice = object.double("latest.cost.avg_net_price.overall")
        let costOfAttendance = object.double("latest.cost.attendance.academic_year")
        let graduationRate = object.double("latest.completion.rate_suppressed.overall")
            ?? object.double("latest.completion.rate")
        let admissionRate = object.double("latest.admissions.admission_rate.overall")
        let medianEarnings = object.double("latest.earnings.10_yrs_after_entry.median")
        let averageDebt = object.double("latest.aid.median_debt.completers.overall")
        let studentSize = object.int("latest.student.size")
        let stateFlagStyle = StateFlagStyles.style(for: state)
        let brandProfile = SchoolBrandProfile.profile(for: schoolWebsite)
        let logoURLs = SchoolLogoURLBuilder.logoURLs(from: schoolWebsite)

        var missingFields: [String] = []
        if tuitionInState == nil { missingFields.append("In-state tuition") }
        if tuitionOutOfState == nil { missingFields.append("Out-of-state tuition") }
        if averageNetPrice == nil { missingFields.append("Average net price") }
        if costOfAttendance == nil { missingFields.append("Cost of attendance") }
        if graduationRate == nil { missingFields.append("Graduation rate") }
        if medianEarnings == nil { missingFields.append("Median earnings") }
        if averageDebt == nil { missingFields.append("Average debt") }
        if admissionRate == nil { missingFields.append("Admission rate") }

        let averageGrantAid: Double
        if let costOfAttendance, let averageNetPrice {
            averageGrantAid = max(0, costOfAttendance - averageNetPrice)
        } else {
            averageGrantAid = 0
        }

        let cost = CostEstimate(
            tuitionAndFees: tuitionInState ?? 0,
            outOfStateTuition: tuitionOutOfState,
            costOfAttendance: costOfAttendance,
            reportedAverageNetPrice: averageNetPrice,
            housingAndMeals: costOfAttendance.map { max(0, $0 - (tuitionInState ?? 0)) } ?? 0,
            booksAndSupplies: 0,
            transportation: 0,
            personalExpenses: 0,
            averageGrantAid: averageGrantAid
        )

        let score = LumaScoreCalculator.score(
            netPrice: averageNetPrice,
            earnings: medianEarnings,
            graduationRate: graduationRate
        )

        return School(
            scorecardID: schoolID,
            name: name,
            city: city,
            state: state,
            type: ownershipType(ownership),
            acceptanceRate: admissionRate ?? 0,
            graduationRate: graduationRate ?? 0,
            lumaScore: score,
            valueLabel: LumaScoreCalculator.label(for: score),
            primaryColor: brandProfile?.primaryHex ?? stateFlagStyle.primaryHex,
            secondaryColor: brandProfile?.secondaryHex ?? stateFlagStyle.secondaryHex,
            logoURL: logoURLs.first,
            logoURLs: logoURLs,
            medianEarnings: medianEarnings ?? 0,
            averageDebt: averageDebt ?? 0,
            studentCount: studentSize ?? 0,
            campusVibe: campusVibe(for: ownershipType(ownership), city: city, state: state),
            programs: [],
            costEstimate: cost,
            highlights: highlights(for: averageNetPrice, medianEarnings: medianEarnings, graduationRate: graduationRate),
            admissionRate: admissionRate,
            missingDataFields: missingFields
        )
    }

    private func mapProgram(_ object: [String: ScorecardValue]) -> Program? {
        let title = object.string("title")
            ?? object.string(at: ["cip_4_digit", "title"])
            ?? object.string("cipdesc")
        let cipCode = object.string("code")
            ?? object.string(at: ["cip_4_digit", "code"])
            ?? object.string("cipcode")
        let credential = object.string(at: ["credential", "title"])
            ?? object.string(at: ["credential", "level"])
            ?? object.string("credential.title")
            ?? object.string("credential.level")
            ?? object.string("credlev")
            ?? "Credential"
        let earnings = object.double(at: ["earnings", "highest", "1_yr", "overall_median_earnings"])
            ?? object.double(at: ["earnings", "1_yr", "overall_median_earnings"])
            ?? object.double(at: ["earnings", "4_yr", "overall_median_earnings"])
            ?? object.double(at: ["earnings", "4_yr", "overall_median_earnings_national"])
            ?? object.double("earnings.median_earnings")
            ?? object.double("earnings.highest.1_yr.overall_median_earnings")
            ?? object.double("earnings.1_yr.overall_median_earnings")
            ?? object.double("earn_mdn_1yr")
            ?? 0
        let debt = object.double(at: ["debt", "staff_grad_plus", "all", "all_inst", "median"])
            ?? object.double(at: ["debt", "staff_grad_plus", "all", "eval_inst", "median"])
            ?? object.double(at: ["debt", "parent_plus", "all", "all_inst", "median"])
            ?? object.double(at: ["debt", "parent_plus", "all", "eval_inst", "median"])
            ?? object.double("debt.median_debt")
            ?? object.double("debt.all.median_debt")
            ?? object.double("debt_mdn")
        let completionCount = object.int(at: ["counts", "ipeds_awards2"])
            ?? object.int(at: ["counts", "ipeds_awards1"])
            ?? object.int("counts.ipeds_awards2")
            ?? object.int("counts.completers")
            ?? object.int("completers")

        guard let title else { return nil }

        return Program(
            name: title,
            credential: credential,
            cipCode: cipCode,
            medianEarnings: earnings,
            debt: debt,
            completionCount: completionCount,
            typicalDurationYears: credential.localizedCaseInsensitiveContains("associate") ? 2 : 4
        )
    }

    private func ownershipType(_ ownership: Int?) -> School.SchoolType {
        switch ownership {
        case 1:
            .publicUniversity
        case 2:
            .privateNonprofit
        default:
            .privateNonprofit
        }
    }

    private func campusVibe(for type: School.SchoolType, city: String, state: String) -> String {
        switch type {
        case .publicUniversity:
            "A public college option with real cost and outcome data for \(city), \(state)."
        case .privateNonprofit:
            "A private nonprofit college with federal cost, aid, and outcome data."
        case .liberalArts:
            "A smaller academic environment with real Scorecard outcome data."
        case .communityCollege:
            "A practical pathway with affordability and transfer planning potential."
        }
    }

    private func highlights(for netPrice: Double?, medianEarnings: Double?, graduationRate: Double?) -> [String] {
        [
            netPrice.map { "Avg net price \($0.formatted(LumaFormat.currency))" },
            medianEarnings.map { "Median earnings \($0.formatted(LumaFormat.currency))" },
            graduationRate.map { "Graduation rate \($0.formatted(LumaFormat.percent))" }
        ]
        .compactMap { $0 }
    }
}

enum LumaScoreCalculator {
    static func score(netPrice: Double?, earnings: Double?, graduationRate: Double?) -> Int {
        let priceComponent = max(0, min(35, 35 - ((netPrice ?? 35_000) / 2_000)))
        let earningsComponent = max(0, min(40, ((earnings ?? 45_000) / 100_000) * 40))
        let graduationComponent = max(0, min(25, (graduationRate ?? 0.45) * 25))
        return max(35, min(98, Int((priceComponent + earningsComponent + graduationComponent).rounded())))
    }

    static func label(for score: Int) -> String {
        switch score {
        case 85...:
            "Excellent Value"
        case 70..<85:
            "Good Value"
        case 55..<70:
            "Fair Value"
        default:
            "Expensive"
        }
    }
}

enum SchoolLogoURLBuilder {
    static func logoURL(from website: String?) -> URL? {
        logoURLs(from: website).first
    }

    static func logoURLs(from website: String?) -> [URL] {
        guard let domain = normalizedDomain(from: website) else { return [] }
        let hosts = orderedHosts(for: domain)

        // TODO: Replace these public logo candidates with a licensed school-logo provider or stored image CDN.
        let candidateStrings = curatedLogoURLs(for: domain) + hosts.flatMap { host in
            [
                "https://\(host)/apple-touch-icon-precomposed.png",
                "https://\(host)/apple-touch-icon.png",
                "https://\(host)/favicon.ico"
            ]
        } + [
            "https://www.google.com/s2/favicons?sz=256&domain=\(domain)"
        ]

        var seen: Set<String> = []
        return candidateStrings.compactMap { string in
            guard seen.insert(string).inserted else { return nil }
            return URL(string: string)
        }
    }

    static func normalizedDomain(from website: String?) -> String? {
        guard var value = website?.trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty else {
            return nil
        }

        if !value.localizedCaseInsensitiveContains("://") {
            value = "https://\(value)"
        }

        guard let host = URL(string: value)?.host(percentEncoded: false)?
            .lowercased()
            .replacingOccurrences(of: "www.", with: "") else {
            return nil
        }

        return host
    }

    private static func orderedHosts(for domain: String) -> [String] {
        domain.hasPrefix("www.") ? [domain] : ["www.\(domain)", domain]
    }

    private static func curatedLogoURLs(for domain: String) -> [String] {
        switch domain {
        case "snhu.edu":
            [
                "https://www.snhu.edu/assets/img/icons/apple-touch-icon-precomposed.png",
                "https://www.snhu.edu/assets/img/favicon.ico"
            ]
        default:
            []
        }
    }
}

struct SchoolBrandProfile {
    var primaryHex: String
    var secondaryHex: String

    static func profile(for website: String?) -> SchoolBrandProfile? {
        guard let domain = SchoolLogoURLBuilder.normalizedDomain(from: website) else { return nil }

        return profiles[domain]
    }

    private static let profiles: [String: SchoolBrandProfile] = [
        "snhu.edu": SchoolBrandProfile(primaryHex: "#00244D", secondaryHex: "#F7C948"),
        "wgu.edu": SchoolBrandProfile(primaryHex: "#003057", secondaryHex: "#F3B61F"),
        "liberty.edu": SchoolBrandProfile(primaryHex: "#002D62", secondaryHex: "#A6192E"),
        "asu.edu": SchoolBrandProfile(primaryHex: "#8C1D40", secondaryHex: "#FFC627"),
        "purdue.edu": SchoolBrandProfile(primaryHex: "#111111", secondaryHex: "#CEB888"),
        "umich.edu": SchoolBrandProfile(primaryHex: "#00274C", secondaryHex: "#FFCB05"),
        "utexas.edu": SchoolBrandProfile(primaryHex: "#BF5700", secondaryHex: "#333F48"),
        "northeastern.edu": SchoolBrandProfile(primaryHex: "#CC0000", secondaryHex: "#111111"),
        "howard.edu": SchoolBrandProfile(primaryHex: "#003A70", secondaryHex: "#E51937"),
        "mdc.edu": SchoolBrandProfile(primaryHex: "#005DAA", secondaryHex: "#F7B500"),
        "smc.edu": SchoolBrandProfile(primaryHex: "#0057B8", secondaryHex: "#F6C343"),
        "reed.edu": SchoolBrandProfile(primaryHex: "#A6192E", secondaryHex: "#111111"),
        "spelman.edu": SchoolBrandProfile(primaryHex: "#005EB8", secondaryHex: "#9ED9FF")
    ]
}

private struct ScorecardResponse: Decodable {
    var metadata: Metadata
    var results: [[String: ScorecardValue]]

    struct Metadata: Decodable {
        var total: Int
        var page: Int
        var perPage: Int

        enum CodingKeys: String, CodingKey {
            case total
            case page
            case perPage = "per_page"
        }
    }
}

private enum ScorecardValue: Decodable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: ScorecardValue])
    case array([ScorecardValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([ScorecardValue].self) {
            self = .array(value)
        } else if let value = try? container.decode([String: ScorecardValue].self) {
            self = .object(value)
        } else {
            self = .null
        }
    }

    var arrayValue: [ScorecardValue]? {
        if case .array(let value) = self { return value }
        return nil
    }
}

private extension Dictionary where Key == String, Value == ScorecardValue {
    func string(_ key: String) -> String? {
        guard let value = self[key] else { return nil }

        return value.stringValue
    }

    func string(at path: [String]) -> String? {
        value(at: path)?.stringValue
    }

    func double(_ key: String) -> Double? {
        guard let value = self[key] else { return nil }

        return value.doubleValue
    }

    func double(at path: [String]) -> Double? {
        value(at: path)?.doubleValue
    }

    func int(_ key: String) -> Int? {
        guard let value = self[key] else { return nil }

        return value.intValue
    }

    func int(at path: [String]) -> Int? {
        value(at: path)?.intValue
    }

    func array(_ key: String) -> [ScorecardValue]? {
        guard case .array(let array)? = self[key] else { return nil }
        return array
    }

    func value(at path: [String]) -> ScorecardValue? {
        guard let first = path.first else { return nil }
        guard let value = self[first] else { return nil }

        if path.count == 1 {
            return value
        }

        guard case .object(let object) = value else {
            return nil
        }

        return object.value(at: Array(path.dropFirst()))
    }
}

private extension ScorecardValue {
    var stringValue: String? {
        switch self {
        case .string(let string):
            return string
        case .number(let number):
            return number.formatted(.number)
        default:
            return nil
        }
    }

    var doubleValue: Double? {
        switch self {
        case .number(let number):
            return number
        case .string(let string):
            return Double(string)
        default:
            return nil
        }
    }

    var intValue: Int? {
        switch self {
        case .number(let number):
            return Int(number)
        case .string(let string):
            return Int(string)
        default:
            return nil
        }
    }
}
