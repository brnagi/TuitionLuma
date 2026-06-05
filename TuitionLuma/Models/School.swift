import Foundation

struct School: Identifiable, Hashable, Codable {
    enum SchoolType: String, CaseIterable, Codable {
        case publicUniversity = "Public"
        case privateNonprofit = "Private"
        case liberalArts = "Liberal Arts"
        case communityCollege = "Community"
    }

    let id: UUID
    var name: String
    var city: String
    var state: String
    var type: SchoolType
    var acceptanceRate: Double
    var graduationRate: Double
    var lumaScore: Int
    var valueLabel: String
    var medianEarnings: Double
    var averageDebt: Double
    var studentCount: Int
    var campusVibe: String
    var programs: [Program]
    var costEstimate: CostEstimate
    var highlights: [String]
    var isSaved: Bool
    var isCompared: Bool

    init(
        id: UUID = UUID(),
        name: String,
        city: String,
        state: String,
        type: SchoolType,
        acceptanceRate: Double,
        graduationRate: Double,
        lumaScore: Int,
        valueLabel: String,
        medianEarnings: Double,
        averageDebt: Double,
        studentCount: Int,
        campusVibe: String,
        programs: [Program],
        costEstimate: CostEstimate,
        highlights: [String],
        isSaved: Bool = false,
        isCompared: Bool = false
    ) {
        self.id = id
        self.name = name
        self.city = city
        self.state = state
        self.type = type
        self.acceptanceRate = acceptanceRate
        self.graduationRate = graduationRate
        self.lumaScore = lumaScore
        self.valueLabel = valueLabel
        self.medianEarnings = medianEarnings
        self.averageDebt = averageDebt
        self.studentCount = studentCount
        self.campusVibe = campusVibe
        self.programs = programs
        self.costEstimate = costEstimate
        self.highlights = highlights
        self.isSaved = isSaved
        self.isCompared = isCompared
    }
}
