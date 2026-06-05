import Foundation

struct School: Identifiable, Hashable, Codable {
    enum SchoolType: String, CaseIterable, Codable {
        case publicUniversity = "Public"
        case privateNonprofit = "Private"
        case liberalArts = "Liberal Arts"
        case communityCollege = "Community"
    }

    let id: String
    var scorecardID: Int?
    var name: String
    var city: String
    var state: String
    var type: SchoolType
    var acceptanceRate: Double
    var graduationRate: Double
    var lumaScore: Int
    var valueLabel: String
    var primaryColor: String?
    var secondaryColor: String?
    var logoURL: URL?
    var campusImageURL: URL?
    var medianEarnings: Double
    var averageDebt: Double
    var studentCount: Int
    var campusVibe: String
    var programs: [Program]
    var costEstimate: CostEstimate
    var highlights: [String]
    var isSaved: Bool
    var isCompared: Bool
    var admissionRate: Double?
    var missingDataFields: [String]

    init(
        id: String = UUID().uuidString,
        scorecardID: Int? = nil,
        name: String,
        city: String,
        state: String,
        type: SchoolType,
        acceptanceRate: Double,
        graduationRate: Double,
        lumaScore: Int,
        valueLabel: String,
        primaryColor: String? = nil,
        secondaryColor: String? = nil,
        logoURL: URL? = nil,
        campusImageURL: URL? = nil,
        medianEarnings: Double,
        averageDebt: Double,
        studentCount: Int,
        campusVibe: String,
        programs: [Program],
        costEstimate: CostEstimate,
        highlights: [String],
        isSaved: Bool = false,
        isCompared: Bool = false,
        admissionRate: Double? = nil,
        missingDataFields: [String] = []
    ) {
        self.id = scorecardID.map(String.init) ?? id
        self.scorecardID = scorecardID
        self.name = name
        self.city = city
        self.state = state
        self.type = type
        self.acceptanceRate = acceptanceRate
        self.graduationRate = graduationRate
        self.lumaScore = lumaScore
        self.valueLabel = valueLabel
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
        self.logoURL = logoURL
        self.campusImageURL = campusImageURL
        self.medianEarnings = medianEarnings
        self.averageDebt = averageDebt
        self.studentCount = studentCount
        self.campusVibe = campusVibe
        self.programs = programs
        self.costEstimate = costEstimate
        self.highlights = highlights
        self.isSaved = isSaved
        self.isCompared = isCompared
        self.admissionRate = admissionRate
        self.missingDataFields = missingDataFields
    }
}
