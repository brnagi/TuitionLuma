import Foundation

struct AcademicProgram: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var credential: String
    var cipCode: String?
    var medianEarnings: Double
    var debt: Double?
    var completionCount: Int?
    var typicalDurationYears: Int
    var category: String?
    var pathLabels: [AcademicPathLabel]

    init(
        id: UUID = UUID(),
        name: String,
        credential: String,
        cipCode: String? = nil,
        medianEarnings: Double,
        debt: Double? = nil,
        completionCount: Int? = nil,
        typicalDurationYears: Int,
        category: String? = nil,
        pathLabels: [AcademicPathLabel] = []
    ) {
        self.id = id
        self.name = name
        self.credential = credential
        self.cipCode = cipCode
        self.medianEarnings = medianEarnings
        self.debt = debt
        self.completionCount = completionCount
        self.typicalDurationYears = typicalDurationYears
        self.category = category
        self.pathLabels = pathLabels.isEmpty
            ? AcademicProgramPathClassifier.labels(name: name, credential: credential, cipCode: cipCode)
            : pathLabels
    }
}

typealias Program = AcademicProgram

enum AcademicPathLabel: String, CaseIterable, Codable, Hashable {
    case standardUndergraduate = "Standard undergraduate"
    case graduateSchoolLikely = "Graduate school likely"
    case professionalLicensureLikely = "Professional licensure likely"
    case labClinicalIntensive = "Lab/clinical intensive"
    case equipmentIntensive = "Equipment intensive"
    case longerTimeToDegreeRisk = "Longer time-to-degree risk"
}

enum AcademicProgramPathClassifier {
    static func labels(name: String, credential: String, cipCode: String?) -> [AcademicPathLabel] {
        var labels: [AcademicPathLabel] = [.standardUndergraduate]
        let lowercasedName = name.lowercased()
        let lowercasedCredential = credential.lowercased()
        let cipPrefix = cipCode?.prefix(2).description

        if lowercasedCredential.contains("master")
            || lowercasedCredential.contains("doctor")
            || lowercasedCredential.contains("graduate") {
            labels.append(.graduateSchoolLikely)
        }

        if lowercasedName.contains("nursing")
            || lowercasedName.contains("teacher")
            || lowercasedName.contains("education")
            || lowercasedName.contains("accounting")
            || lowercasedName.contains("social work")
            || cipPrefix == "13"
            || cipPrefix == "14"
            || cipPrefix == "51" {
            labels.append(.professionalLicensureLikely)
        }

        if lowercasedName.contains("biology")
            || lowercasedName.contains("chemistry")
            || lowercasedName.contains("laboratory")
            || lowercasedName.contains("clinical")
            || lowercasedName.contains("medical")
            || lowercasedName.contains("health")
            || lowercasedName.contains("nursing")
            || cipPrefix == "26"
            || cipPrefix == "40"
            || cipPrefix == "51" {
            labels.append(.labClinicalIntensive)
        }

        if lowercasedName.contains("engineering")
            || lowercasedName.contains("film")
            || lowercasedName.contains("aviation")
            || lowercasedName.contains("architecture")
            || lowercasedName.contains("design")
            || lowercasedName.contains("production")
            || cipPrefix == "04"
            || cipPrefix == "10"
            || cipPrefix == "14"
            || cipPrefix == "15"
            || cipPrefix == "50" {
            labels.append(.equipmentIntensive)
        }

        if lowercasedName.contains("pre-")
            || lowercasedName.contains("architecture")
            || lowercasedName.contains("engineering")
            || lowercasedName.contains("clinical")
            || lowercasedCredential.contains("doctor")
            || cipPrefix == "04"
            || cipPrefix == "14"
            || cipPrefix == "51" {
            labels.append(.longerTimeToDegreeRisk)
        }

        return unique(labels)
    }

    private static func unique(_ labels: [AcademicPathLabel]) -> [AcademicPathLabel] {
        var seen: Set<AcademicPathLabel> = []
        return labels.filter { seen.insert($0).inserted }
    }
}
