import Foundation

struct USState: Identifiable, Hashable {
    let name: String
    let abbreviation: String

    var id: String { abbreviation }
}

extension USState {
    static let all: [USState] = [
        USState(name: "Alabama", abbreviation: "AL"),
        USState(name: "Alaska", abbreviation: "AK"),
        USState(name: "Arizona", abbreviation: "AZ"),
        USState(name: "Arkansas", abbreviation: "AR"),
        USState(name: "California", abbreviation: "CA"),
        USState(name: "Colorado", abbreviation: "CO"),
        USState(name: "Connecticut", abbreviation: "CT"),
        USState(name: "Delaware", abbreviation: "DE"),
        USState(name: "District of Columbia", abbreviation: "DC"),
        USState(name: "Florida", abbreviation: "FL"),
        USState(name: "Georgia", abbreviation: "GA"),
        USState(name: "Hawaii", abbreviation: "HI"),
        USState(name: "Idaho", abbreviation: "ID"),
        USState(name: "Illinois", abbreviation: "IL"),
        USState(name: "Indiana", abbreviation: "IN"),
        USState(name: "Iowa", abbreviation: "IA"),
        USState(name: "Kansas", abbreviation: "KS"),
        USState(name: "Kentucky", abbreviation: "KY"),
        USState(name: "Louisiana", abbreviation: "LA"),
        USState(name: "Maine", abbreviation: "ME"),
        USState(name: "Maryland", abbreviation: "MD"),
        USState(name: "Massachusetts", abbreviation: "MA"),
        USState(name: "Michigan", abbreviation: "MI"),
        USState(name: "Minnesota", abbreviation: "MN"),
        USState(name: "Mississippi", abbreviation: "MS"),
        USState(name: "Missouri", abbreviation: "MO"),
        USState(name: "Montana", abbreviation: "MT"),
        USState(name: "Nebraska", abbreviation: "NE"),
        USState(name: "Nevada", abbreviation: "NV"),
        USState(name: "New Hampshire", abbreviation: "NH"),
        USState(name: "New Jersey", abbreviation: "NJ"),
        USState(name: "New Mexico", abbreviation: "NM"),
        USState(name: "New York", abbreviation: "NY"),
        USState(name: "North Carolina", abbreviation: "NC"),
        USState(name: "North Dakota", abbreviation: "ND"),
        USState(name: "Ohio", abbreviation: "OH"),
        USState(name: "Oklahoma", abbreviation: "OK"),
        USState(name: "Oregon", abbreviation: "OR"),
        USState(name: "Pennsylvania", abbreviation: "PA"),
        USState(name: "Rhode Island", abbreviation: "RI"),
        USState(name: "South Carolina", abbreviation: "SC"),
        USState(name: "South Dakota", abbreviation: "SD"),
        USState(name: "Tennessee", abbreviation: "TN"),
        USState(name: "Texas", abbreviation: "TX"),
        USState(name: "Utah", abbreviation: "UT"),
        USState(name: "Vermont", abbreviation: "VT"),
        USState(name: "Virginia", abbreviation: "VA"),
        USState(name: "Washington", abbreviation: "WA"),
        USState(name: "West Virginia", abbreviation: "WV"),
        USState(name: "Wisconsin", abbreviation: "WI"),
        USState(name: "Wyoming", abbreviation: "WY")
    ]

    static func normalizedAbbreviation(from value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }

        let cleaned = trimmed
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ",", with: "")
        let uppercased = cleaned.uppercased()

        if let exactMatch = all.first(where: {
            $0.abbreviation == uppercased || $0.name.uppercased() == uppercased
        }) {
            return exactMatch.abbreviation
        }

        if uppercased == "PENN" || uppercased == "PENNA" {
            return "PA"
        }

        if let prefixMatch = all.first(where: {
            uppercased.count >= 4 && $0.name.uppercased().hasPrefix(uppercased)
        }) {
            return prefixMatch.abbreviation
        }

        return uppercased
    }

    static func displayName(for value: String) -> String {
        let abbreviation = normalizedAbbreviation(from: value)
        return all.first(where: { $0.abbreviation == abbreviation })?.name ?? value
    }
}

enum FamilyIncomeRange: String, CaseIterable, Identifiable, Codable {
    case under30k = "Under $30K"
    case range30to75k = "$30K-$75K"
    case range75to110k = "$75K-$110K"
    case range110to150k = "$110K-$150K"
    case over150k = "$150K+"

    var id: String { rawValue }

    var midpoint: Double {
        switch self {
        case .under30k: 22_500
        case .range30to75k: 52_500
        case .range75to110k: 92_500
        case .range110to150k: 130_000
        case .over150k: 175_000
        }
    }

    var netPriceMultiplier: Double {
        switch self {
        case .under30k: 0.62
        case .range30to75k: 0.78
        case .range75to110k: 0.96
        case .range110to150k: 1.12
        case .over150k: 1.26
        }
    }
}

enum DebtTolerance: String, CaseIterable, Identifiable, Codable {
    case low = "Low"
    case medium = "Moderate"
    case high = "Flexible"

    var id: String { rawValue }

    var summary: String {
        switch self {
        case .low:
            "Prioritize schools with lower borrowing."
        case .medium:
            "Balance debt with outcomes."
        case .high:
            "Consider higher debt if outcomes are strong."
        }
    }

    var maximumComfortableDebt: Double {
        switch self {
        case .low: 18_000
        case .medium: 30_000
        case .high: 45_000
        }
    }
}

enum SchoolOwnershipPreference: String, CaseIterable, Identifiable, Codable {
    case any = "Any"
    case publicOnly = "Public"
    case privateOnly = "Private"

    var id: String { rawValue }

    var summary: String {
        switch self {
        case .any:
            "Show public and private options."
        case .publicOnly:
            "Prefer public colleges and universities."
        case .privateOnly:
            "Prefer private nonprofit colleges."
        }
    }
}

enum DistanceFromHomePreference: String, CaseIterable, Identifiable, Codable {
    case closeToHome = "Close to Home"
    case withinFewHours = "Within a Few Hours"
    case anywhere = "Anywhere"
    case noPreference = "No Preference"

    var id: String { rawValue }
}

enum CampusSizePreference: String, CaseIterable, Identifiable, Codable {
    case small = "Small"
    case medium = "Medium"
    case large = "Large"
    case noPreference = "No Preference"

    var id: String { rawValue }
}

enum LearningFormatPreference: String, CaseIterable, Identifiable, Codable {
    case inPerson = "In Person"
    case hybrid = "Hybrid"
    case online = "Online"
    case noPreference = "No Preference"

    var id: String { rawValue }
}

struct StudentProfile: Codable, Equatable {
    var nickname: String
    var gpa: Double
    var testScore: String
    var stateResidency: String
    var intendedMajor: String
    var familyIncomeRange: FamilyIncomeRange
    var debtTolerance: DebtTolerance
    var ownershipPreference: SchoolOwnershipPreference
    var distanceFromHomePreference: DistanceFromHomePreference
    var campusSizePreference: CampusSizePreference
    var learningFormatPreference: LearningFormatPreference

    init(
        nickname: String = "",
        gpa: Double,
        testScore: String,
        stateResidency: String,
        intendedMajor: String,
        familyIncomeRange: FamilyIncomeRange,
        debtTolerance: DebtTolerance = .medium,
        ownershipPreference: SchoolOwnershipPreference = .any,
        distanceFromHomePreference: DistanceFromHomePreference = .noPreference,
        campusSizePreference: CampusSizePreference = .noPreference,
        learningFormatPreference: LearningFormatPreference = .noPreference
    ) {
        self.nickname = nickname
        self.gpa = gpa
        self.testScore = testScore
        self.stateResidency = USState.normalizedAbbreviation(from: stateResidency)
        self.intendedMajor = intendedMajor
        self.familyIncomeRange = familyIncomeRange
        self.debtTolerance = debtTolerance
        self.ownershipPreference = ownershipPreference
        self.distanceFromHomePreference = distanceFromHomePreference
        self.campusSizePreference = campusSizePreference
        self.learningFormatPreference = learningFormatPreference
    }

    private enum CodingKeys: String, CodingKey {
        case nickname
        case gpa
        case testScore
        case stateResidency
        case intendedMajor
        case familyIncomeRange
        case debtTolerance
        case ownershipPreference
        case distanceFromHomePreference
        case campusSizePreference
        case learningFormatPreference
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        nickname = try container.decodeIfPresent(String.self, forKey: .nickname) ?? ""
        gpa = try container.decode(Double.self, forKey: .gpa)
        testScore = try container.decode(String.self, forKey: .testScore)
        let decodedStateResidency = try container.decode(String.self, forKey: .stateResidency)
        stateResidency = USState.normalizedAbbreviation(from: decodedStateResidency)
        intendedMajor = try container.decode(String.self, forKey: .intendedMajor)
        familyIncomeRange = try container.decode(FamilyIncomeRange.self, forKey: .familyIncomeRange)
        debtTolerance = try container.decodeIfPresent(DebtTolerance.self, forKey: .debtTolerance) ?? .medium
        ownershipPreference = try container.decodeIfPresent(SchoolOwnershipPreference.self, forKey: .ownershipPreference) ?? .any
        distanceFromHomePreference = try container.decodeIfPresent(DistanceFromHomePreference.self, forKey: .distanceFromHomePreference) ?? .noPreference
        campusSizePreference = try container.decodeIfPresent(CampusSizePreference.self, forKey: .campusSizePreference) ?? .noPreference
        learningFormatPreference = try container.decodeIfPresent(LearningFormatPreference.self, forKey: .learningFormatPreference) ?? .noPreference
    }

    static let empty = StudentProfile(
        nickname: "",
        gpa: 3.3,
        testScore: "",
        stateResidency: "",
        intendedMajor: "",
        familyIncomeRange: .range75to110k,
        debtTolerance: .medium,
        ownershipPreference: .any,
        distanceFromHomePreference: .noPreference,
        campusSizePreference: .noPreference,
        learningFormatPreference: .noPreference
    )

    var normalizedStateResidency: String {
        USState.normalizedAbbreviation(from: stateResidency)
    }

    var stateResidencyDisplayName: String {
        USState.displayName(for: stateResidency)
    }

    var displayNickname: String {
        nickname.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var normalizedMajor: String {
        intendedMajor.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    var isComplete: Bool {
        !normalizedStateResidency.isEmpty && !normalizedMajor.isEmpty && gpa > 0
    }
}

struct ProfileRecommendation: Equatable {
    var fitLabel: String
    var estimatedNetCost: Double
    var affordability: AffordabilityClassification
    var roiGrade: String
    var summary: String
}

enum AffordabilityClassification: String, Equatable {
    case affordable = "Affordable"
    case stretch = "Stretch"
    case highRisk = "High Risk"

    var explanation: String {
        switch self {
        case .affordable:
            "Estimated cost looks manageable for this income range."
        case .stretch:
            "May need careful aid, savings, or borrowing planning."
        case .highRisk:
            "Likely needs more aid or lower borrowing to stay manageable."
        }
    }
}

enum StudentProfileRecommendationEngine {
    static func rankedSchools(_ schools: [School], profile: StudentProfile) -> [School] {
        guard profile.isComplete else { return schools }

        return schools.sorted { lhs, rhs in
            let lhsProgram = bestMatchingProgram(for: lhs, profile: profile)
            let rhsProgram = bestMatchingProgram(for: rhs, profile: profile)
            let lhsNetCost = estimateNetCost(for: lhs, profile: profile)
            let rhsNetCost = estimateNetCost(for: rhs, profile: profile)
            let lhsScore = recommendationRankingScore(for: lhs, profile: profile, program: lhsProgram, estimatedNetCost: lhsNetCost)
            let rhsScore = recommendationRankingScore(for: rhs, profile: profile, program: rhsProgram, estimatedNetCost: rhsNetCost)

            if lhsScore != rhsScore {
                return lhsScore > rhsScore
            }

            if lhs.lumaScore != rhs.lumaScore {
                return lhs.lumaScore > rhs.lumaScore
            }

            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }

    static func recommendation(for school: School, profile: StudentProfile) -> ProfileRecommendation {
        let estimatedNetCost = estimateNetCost(for: school, profile: profile)
        let fitScore = calculateFitScore(for: school, profile: profile, estimatedNetCost: estimatedNetCost)
        let matchedProgram = bestMatchingProgram(for: school, profile: profile)
        let roiGrade = personalizedROIOutcome(for: school, profile: profile).grade

        return ProfileRecommendation(
            fitLabel: fitLabel(for: fitScore),
            estimatedNetCost: estimatedNetCost,
            affordability: affordabilityClassification(for: profile, estimatedNetCost: estimatedNetCost),
            roiGrade: roiGrade,
            summary: summary(for: school, profile: profile, matchedProgram: matchedProgram)
        )
    }

    static func matchingProgram(for school: School, profile: StudentProfile) -> AcademicProgram? {
        bestMatchingProgram(for: school, profile: profile)
    }

    static func matchingProgram(
        in programs: [AcademicProgram],
        for school: School,
        profile: StudentProfile
    ) -> AcademicProgram? {
        bestMatchingProgram(in: programs, for: school, profile: profile)
    }

    static func personalizedROIOutcome(for school: School, profile: StudentProfile) -> ROIOutcomeResult {
        ROIOutcomeCalculator.result(
            for: school,
            program: bestMatchingProgram(for: school, profile: profile),
            estimatedNetCost: estimateNetCost(for: school, profile: profile)
        )
    }

    static func majorKeywords(from major: String) -> [String] {
        let normalizedMajor = major.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        var keywords = normalizedMajor
            .split { !$0.isLetter && !$0.isNumber }
            .map(String.init)
            .filter { $0.count >= 4 }

        if normalizedMajor.contains("computer") || normalizedMajor.contains("software") || normalizedMajor.contains("data") {
            keywords.append(contentsOf: ["computer", "software", "information"])
        }

        if normalizedMajor.contains("business") || normalizedMajor.contains("finance") || normalizedMajor.contains("account") {
            keywords.removeAll { $0 == "administration" || $0 == "operations" }
            keywords.append(contentsOf: ["business", "management", "finance", "marketing"])
        }

        if normalizedMajor.contains("nurs") || normalizedMajor.contains("health") || normalizedMajor.contains("medical") {
            keywords.append(contentsOf: ["nursing", "health", "medical"])
        }

        if normalizedMajor.contains("engineer") {
            keywords.append("engineering")
        }

        return Array(Set(keywords))
    }

    private static func estimateNetCost(for school: School, profile: StudentProfile) -> Double {
        let cost = school.costEstimate
        var estimate = cost.averageNetPrice > 0 ? cost.averageNetPrice : cost.estimatedAnnualCost

        if school.type == .publicUniversity || school.type == .communityCollege {
            if profile.normalizedStateResidency == school.state.uppercased() {
                estimate = min(estimate, max(0, cost.estimatedAnnualCost - cost.averageGrantAid))
            } else if let outOfStateTuition = cost.outOfStateTuition,
                      outOfStateTuition > cost.tuitionAndFees {
                estimate += (outOfStateTuition - cost.tuitionAndFees) * 0.55
            }
        }

        estimate *= profile.familyIncomeRange.netPriceMultiplier

        if profile.gpa >= 3.8 {
            estimate *= 0.92
        } else if profile.gpa >= 3.5 {
            estimate *= 0.96
        }

        if let score = numericTestScore(from: profile.testScore) {
            if score >= 1350 || (score >= 30 && score <= 36) {
                estimate *= 0.96
            }
        }

        let maxAnnualCost = max(cost.estimatedAnnualCost, cost.averageNetPrice)
        return max(0, min(estimate, maxAnnualCost).roundedToNearestHundred())
    }

    private static func calculateFitScore(for school: School, profile: StudentProfile, estimatedNetCost: Double) -> Double {
        var score = Double(school.lumaScore) * 0.34
        score += residencyScore(for: school, profile: profile)
        score += majorScore(for: school, profile: profile)
        score += academicScore(for: school, profile: profile)
        score += affordabilityScore(for: profile, estimatedNetCost: estimatedNetCost)
        return min(100, max(0, score))
    }

    private static func residencyScore(for school: School, profile: StudentProfile) -> Double {
        guard school.type == .publicUniversity || school.type == .communityCollege else { return 9 }
        return profile.normalizedStateResidency == school.state.uppercased() ? 14 : 6
    }

    private static func majorScore(for school: School, profile: StudentProfile) -> Double {
        let major = profile.normalizedMajor
        guard !major.isEmpty else { return 4 }

        let programMatch = bestMatchingProgram(for: school, profile: profile) != nil
        let highlightMatch = school.highlights.contains { highlight in
            majorKeywords(from: major).contains { highlight.lowercased().contains($0) }
        }

        if programMatch { return 16 }
        if highlightMatch { return 12 }
        if school.medianEarnings >= 70_000 { return 10 }
        return 7
    }

    private static func bestMatchingProgram(for school: School, profile: StudentProfile) -> AcademicProgram? {
        bestMatchingProgram(in: school.programs, for: school, profile: profile)
    }

    private static func bestMatchingProgram(
        in programs: [AcademicProgram],
        for school: School,
        profile: StudentProfile
    ) -> AcademicProgram? {
        let major = profile.normalizedMajor
        guard !major.isEmpty else { return nil }

        let keywords = majorKeywords(from: major)
        return programs
            .compactMap { program -> (program: AcademicProgram, score: Int)? in
                let score = programMatchScore(program, major: major, keywords: keywords)
                guard score > 0 else { return nil }
                return (program, score)
            }
            .sorted { lhs, rhs in
                if lhs.score != rhs.score {
                    return lhs.score > rhs.score
                }

                let lhsROI = ROIOutcomeCalculator.result(for: school, program: lhs.program).score
                let rhsROI = ROIOutcomeCalculator.result(for: school, program: rhs.program).score

                if lhsROI != rhsROI {
                    return lhsROI > rhsROI
                }

                return (lhs.program.completionCount ?? 0) > (rhs.program.completionCount ?? 0)
            }
            .map(\.program)
            .first
    }

    private static func programMatchScore(
        _ program: AcademicProgram,
        major: String,
        keywords: [String]
    ) -> Int {
        let normalizedName = program.name.lowercased()
        let normalizedCategory = program.category?.lowercased() ?? ""
        let normalizedCIP = program.cipCode ?? ""
        var score = 0

        if normalizedName.contains(major) {
            score += 80
        }

        for keyword in keywords {
            if normalizedName.contains(keyword) {
                score += 24
            }

            if normalizedCategory.contains(keyword) {
                score += 10
            }
        }

        if major.contains("business"), normalizedCIP.hasPrefix("52") {
            score += 18
        }

        if major.contains("computer"), normalizedCIP.hasPrefix("11") {
            score += 18
        }

        if major.contains("nurs"), normalizedCIP.hasPrefix("51") {
            score += 18
        }

        if major.contains("engineer"), normalizedCIP.hasPrefix("14") {
            score += 18
        }

        return score
    }

    private static func recommendationRankingScore(
        for school: School,
        profile: StudentProfile,
        program: AcademicProgram?,
        estimatedNetCost: Double
    ) -> Double {
        let roi = ROIOutcomeCalculator.result(for: school, program: program, estimatedNetCost: estimatedNetCost)
        let outcomeScore = outcomeStrengthScore(for: school, program: program)
        let affordability = affordabilityScore(for: profile, estimatedNetCost: estimatedNetCost) / 19 * 100
        let residency = residencyRankingScore(for: school, profile: profile, estimatedNetCost: estimatedNetCost)
        let majorMatch = program == nil ? 0.0 : 100.0
        let preference = preferenceScore(for: school, profile: profile, program: program)

        if program != nil {
            return Double(roi.score) * 0.42
                + outcomeScore * 0.13
                + Double(school.lumaScore) * 0.10
                + affordability * 0.09
                + residency * 0.09
                + majorMatch * 0.07
                + preference * 0.10
        }

        return Double(roi.score) * 0.34
            + Double(school.lumaScore) * 0.18
            + outcomeScore * 0.11
            + affordability * 0.13
            + residency * 0.12
            + preference * 0.12
    }

    private static func preferenceScore(for school: School, profile: StudentProfile, program: AcademicProgram?) -> Double {
        let ownershipScore: Double
        switch profile.ownershipPreference {
        case .any:
            ownershipScore = 70
        case .publicOnly:
            ownershipScore = (school.type == .publicUniversity || school.type == .communityCollege) ? 100 : 18
        case .privateOnly:
            ownershipScore = (school.type == .privateNonprofit || school.type == .liberalArts) ? 100 : 18
        }

        let debt = program?.debt.flatMap { $0 > 0 ? $0 : nil } ?? school.averageDebt
        let debtScore: Double
        if debt <= 0 {
            debtScore = 55
        } else {
            let comfortableDebt = profile.debtTolerance.maximumComfortableDebt
            let low = comfortableDebt * 0.55
            let high = comfortableDebt * 1.45
            debtScore = normalizedInverseScore(value: debt, low: low, high: high)
        }

        return ownershipScore * 0.45 + debtScore * 0.55
    }

    private static func residencyRankingScore(
        for school: School,
        profile: StudentProfile,
        estimatedNetCost: Double
    ) -> Double {
        guard school.type == .publicUniversity || school.type == .communityCollege else {
            return 35
        }

        guard profile.normalizedStateResidency == school.state.uppercased() else {
            return 18
        }

        let burden = affordabilityBurden(for: profile, estimatedNetCost: estimatedNetCost)
        let affordabilityComponent = normalizedInverseScore(value: burden, low: 0.08, high: 0.32)
        let stickerCost = max(school.costEstimate.estimatedAnnualCost, school.costEstimate.averageNetPrice)
        let savingsComponent: Double

        if stickerCost > 0 {
            let savingsRatio = max(0, min(1, (stickerCost - estimatedNetCost) / stickerCost))
            savingsComponent = savingsRatio * 100
        } else {
            savingsComponent = 50
        }

        return min(100, 45 + affordabilityComponent * 0.35 + savingsComponent * 0.20)
    }

    private static func outcomeStrengthScore(for school: School, program: AcademicProgram?) -> Double {
        let earnings = program.flatMap { $0.medianEarnings > 0 ? $0.medianEarnings : nil }
            ?? school.medianEarnings
        let debt = program?.debt.flatMap { $0 > 0 ? $0 : nil }
            ?? school.averageDebt

        let earningsScore = normalizedScore(value: earnings, low: 35_000, high: 120_000)
        let debtScore = normalizedInverseScore(value: debt, low: 8_000, high: 45_000)
        let completionScore: Double

        if let completionCount = program?.completionCount, completionCount > 0 {
            completionScore = normalizedScore(
                value: log10(Double(completionCount)),
                low: log10(25),
                high: log10(800)
            )
        } else {
            completionScore = 45
        }

        return earningsScore * 0.45 + debtScore * 0.35 + completionScore * 0.20
    }

    private static func academicScore(for school: School, profile: StudentProfile) -> Double {
        guard let admissionRate = school.admissionRate, admissionRate > 0 else {
            return profile.gpa >= 3.4 ? 13 : 10
        }

        let targetGPA: Double
        if admissionRate < 0.2 {
            targetGPA = 3.85
        } else if admissionRate < 0.45 {
            targetGPA = 3.55
        } else if admissionRate < 0.75 {
            targetGPA = 3.2
        } else {
            targetGPA = 2.8
        }

        let difference = profile.gpa - targetGPA
        if difference >= 0.25 { return 17 }
        if difference >= -0.10 { return 14 }
        if difference >= -0.35 { return 10 }
        return 6
    }

    private static func affordabilityScore(for profile: StudentProfile, estimatedNetCost: Double) -> Double {
        let burden = affordabilityBurden(for: profile, estimatedNetCost: estimatedNetCost)

        if burden < 0.12 { return 19 }
        if burden < 0.20 { return 15 }
        if burden < 0.30 { return 10 }
        return 5
    }

    private static func affordabilityClassification(
        for profile: StudentProfile,
        estimatedNetCost: Double
    ) -> AffordabilityClassification {
        let burden = affordabilityBurden(for: profile, estimatedNetCost: estimatedNetCost)

        if burden < 0.20 { return .affordable }
        if burden < 0.30 { return .stretch }
        return .highRisk
    }

    private static func affordabilityBurden(for profile: StudentProfile, estimatedNetCost: Double) -> Double {
        estimatedNetCost / max(profile.familyIncomeRange.midpoint, 1)
    }

    private static func fitLabel(for score: Double) -> String {
        if score >= 82 { return "Excellent fit for your profile" }
        if score >= 68 { return "Good fit for your profile" }
        if score >= 54 { return "Possible fit for your profile" }
        return "Reach for your profile"
    }

    private static func summary(for school: School, profile: StudentProfile, matchedProgram: AcademicProgram?) -> String {
        if let matchedProgram {
            return "Uses \(matchedProgram.name) outcomes, your residency, and income range."
        }

        if profile.normalizedStateResidency == school.state.uppercased() {
            return "Uses your in-state residency, income range, and \(profile.intendedMajor) interest."
        }

        return "Uses your residency, income range, and \(profile.intendedMajor) interest."
    }

    private static func numericTestScore(from text: String) -> Int? {
        let digits = text.filter(\.isNumber)
        return Int(digits)
    }

    private static func normalizedScore(value: Double, low: Double, high: Double) -> Double {
        guard high > low else { return 0 }
        return min(1, max(0, (value - low) / (high - low))) * 100
    }

    private static func normalizedInverseScore(value: Double, low: Double, high: Double) -> Double {
        guard high > low else { return 0 }
        return min(1, max(0, (high - value) / (high - low))) * 100
    }
}

private extension Double {
    func roundedToNearestHundred() -> Double {
        (self / 100).rounded() * 100
    }
}

@MainActor
final class StudentProfileStore: ObservableObject {
    private enum StorageKey {
        static let profile = "tuitionLuma.studentProfile"
        static let legacyProfile = "tuitionluma.studentProfile"
    }

    private let userDefaults: UserDefaults

    @Published var profile: StudentProfile {
        didSet { persistProfile() }
    }

    init(profile: StudentProfile = .empty, userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        if let savedProfile = Self.loadProfile(from: userDefaults, key: StorageKey.profile) {
            self.profile = savedProfile
        } else if let legacyProfile = Self.loadProfile(from: userDefaults, key: StorageKey.legacyProfile) {
            self.profile = legacyProfile
            persistProfile()
        } else {
            self.profile = profile
        }
    }

    func clear() {
        profile = .empty
        userDefaults.removeObject(forKey: StorageKey.profile)
        userDefaults.removeObject(forKey: StorageKey.legacyProfile)
    }

    private func persistProfile() {
        if let data = try? JSONEncoder().encode(profile) {
            userDefaults.set(data, forKey: StorageKey.profile)
        }
    }

    private static func loadProfile(from userDefaults: UserDefaults, key: String) -> StudentProfile? {
        guard let data = userDefaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(StudentProfile.self, from: data)
    }
}
