import Foundation

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

struct StudentProfile: Codable, Equatable {
    var gpa: Double
    var testScore: String
    var stateResidency: String
    var intendedMajor: String
    var familyIncomeRange: FamilyIncomeRange

    static let empty = StudentProfile(
        gpa: 3.3,
        testScore: "",
        stateResidency: "",
        intendedMajor: "",
        familyIncomeRange: .range75to110k
    )

    var normalizedStateResidency: String {
        stateResidency.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
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
    var roiGrade: String
    var summary: String
}

enum StudentProfileRecommendationEngine {
    static func rankedSchools(_ schools: [School], profile: StudentProfile) -> [School] {
        guard profile.isComplete else { return schools }

        return schools.sorted { lhs, rhs in
            let lhsProgram = bestMatchingProgram(for: lhs, profile: profile)
            let rhsProgram = bestMatchingProgram(for: rhs, profile: profile)
            let lhsHasProgramMatch = lhsProgram != nil
            let rhsHasProgramMatch = rhsProgram != nil

            if lhsHasProgramMatch != rhsHasProgramMatch {
                return lhsHasProgramMatch
            }

            let lhsNetCost = estimateNetCost(for: lhs, profile: profile)
            let rhsNetCost = estimateNetCost(for: rhs, profile: profile)
            let lhsROI = ROIOutcomeCalculator.result(for: lhs, program: lhsProgram, estimatedNetCost: lhsNetCost).score
            let rhsROI = ROIOutcomeCalculator.result(for: rhs, program: rhsProgram, estimatedNetCost: rhsNetCost).score

            if lhsROI != rhsROI {
                return lhsROI > rhsROI
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
        let roiGrade = ROIOutcomeCalculator.result(
            for: school,
            program: matchedProgram,
            estimatedNetCost: estimatedNetCost
        ).grade

        return ProfileRecommendation(
            fitLabel: fitLabel(for: fitScore),
            estimatedNetCost: estimatedNetCost,
            roiGrade: roiGrade,
            summary: summary(for: school, profile: profile, matchedProgram: matchedProgram)
        )
    }

    static func matchingProgram(for school: School, profile: StudentProfile) -> AcademicProgram? {
        bestMatchingProgram(for: school, profile: profile)
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
            keywords.append(contentsOf: ["business", "management", "finance"])
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
        let major = profile.normalizedMajor
        guard !major.isEmpty else { return nil }

        let keywords = majorKeywords(from: major)
        return school.programs
            .filter { program in
                let normalizedName = program.name.lowercased()
                let normalizedCategory = program.category?.lowercased() ?? ""
                return keywords.contains { normalizedName.contains($0) || normalizedCategory.contains($0) }
            }
            .sorted { lhs, rhs in
                let lhsROI = ROIOutcomeCalculator.result(for: school, program: lhs).score
                let rhsROI = ROIOutcomeCalculator.result(for: school, program: rhs).score

                if lhsROI != rhsROI {
                    return lhsROI > rhsROI
                }

                return (lhs.completionCount ?? 0) > (rhs.completionCount ?? 0)
            }
            .first
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
        let burden = estimatedNetCost / max(profile.familyIncomeRange.midpoint, 1)

        if burden < 0.12 { return 19 }
        if burden < 0.20 { return 15 }
        if burden < 0.30 { return 10 }
        return 5
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
}

private extension Double {
    func roundedToNearestHundred() -> Double {
        (self / 100).rounded() * 100
    }
}

@MainActor
final class StudentProfileStore: ObservableObject {
    private let storageKey = "tuitionluma.studentProfile"

    @Published var profile: StudentProfile {
        didSet { persistProfile() }
    }

    init(profile: StudentProfile = .empty) {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let savedProfile = try? JSONDecoder().decode(StudentProfile.self, from: data) {
            self.profile = savedProfile
        } else {
            self.profile = profile
        }
    }

    func clear() {
        profile = .empty
        UserDefaults.standard.removeObject(forKey: storageKey)
    }

    private func persistProfile() {
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}
