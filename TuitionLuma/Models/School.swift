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

struct StateFlagStyle: Hashable {
    var code: String
    var name: String
    var primaryHex: String
    var secondaryHex: String
    var accentHex: String
    var emblemSystemImage: String
}

enum StateFlagStyles {
    static func style(for state: String) -> StateFlagStyle {
        styles[state.uppercased()] ?? StateFlagStyle(
            code: state.uppercased(),
            name: state.uppercased(),
            primaryHex: "#2563EB",
            secondaryHex: "#14B8A6",
            accentHex: "#F8FAFC",
            emblemSystemImage: "star.fill"
        )
    }

    private static let styles: [String: StateFlagStyle] = [
        "AL": StateFlagStyle(code: "AL", name: "Alabama", primaryHex: "#B10021", secondaryHex: "#FFFFFF", accentHex: "#B10021", emblemSystemImage: "xmark"),
        "AK": StateFlagStyle(code: "AK", name: "Alaska", primaryHex: "#0B214A", secondaryHex: "#F6C344", accentHex: "#F6C344", emblemSystemImage: "star.fill"),
        "AZ": StateFlagStyle(code: "AZ", name: "Arizona", primaryHex: "#BF0D3E", secondaryHex: "#00205B", accentHex: "#FED141", emblemSystemImage: "sun.max.fill"),
        "AR": StateFlagStyle(code: "AR", name: "Arkansas", primaryHex: "#BF0A30", secondaryHex: "#002868", accentHex: "#FFFFFF", emblemSystemImage: "diamond.fill"),
        "CA": StateFlagStyle(code: "CA", name: "California", primaryHex: "#B71234", secondaryHex: "#FFFFFF", accentHex: "#2E7D32", emblemSystemImage: "star.fill"),
        "CO": StateFlagStyle(code: "CO", name: "Colorado", primaryHex: "#002868", secondaryHex: "#BF0A30", accentHex: "#FFD100", emblemSystemImage: "sun.max.fill"),
        "CT": StateFlagStyle(code: "CT", name: "Connecticut", primaryHex: "#003DA5", secondaryHex: "#FFFFFF", accentHex: "#B7BF10", emblemSystemImage: "shield.fill"),
        "DE": StateFlagStyle(code: "DE", name: "Delaware", primaryHex: "#76AADB", secondaryHex: "#F4C430", accentHex: "#8A1538", emblemSystemImage: "diamond.fill"),
        "DC": StateFlagStyle(code: "DC", name: "District of Columbia", primaryHex: "#FFFFFF", secondaryHex: "#E31B23", accentHex: "#E31B23", emblemSystemImage: "star.fill"),
        "FL": StateFlagStyle(code: "FL", name: "Florida", primaryHex: "#C8102E", secondaryHex: "#FFFFFF", accentHex: "#FDB515", emblemSystemImage: "xmark"),
        "GA": StateFlagStyle(code: "GA", name: "Georgia", primaryHex: "#BA0C2F", secondaryHex: "#002D72", accentHex: "#FFFFFF", emblemSystemImage: "star.fill"),
        "HI": StateFlagStyle(code: "HI", name: "Hawaii", primaryHex: "#00247D", secondaryHex: "#CF142B", accentHex: "#FFFFFF", emblemSystemImage: "rectangle.split.3x1.fill"),
        "ID": StateFlagStyle(code: "ID", name: "Idaho", primaryHex: "#003DA5", secondaryHex: "#FDB515", accentHex: "#FFFFFF", emblemSystemImage: "seal.fill"),
        "IL": StateFlagStyle(code: "IL", name: "Illinois", primaryHex: "#FFFFFF", secondaryHex: "#0C2340", accentHex: "#E31B23", emblemSystemImage: "star.fill"),
        "IN": StateFlagStyle(code: "IN", name: "Indiana", primaryHex: "#002D72", secondaryHex: "#FDB515", accentHex: "#FDB515", emblemSystemImage: "torch.fill"),
        "IA": StateFlagStyle(code: "IA", name: "Iowa", primaryHex: "#005EB8", secondaryHex: "#D50032", accentHex: "#FFFFFF", emblemSystemImage: "star.fill"),
        "KS": StateFlagStyle(code: "KS", name: "Kansas", primaryHex: "#002D72", secondaryHex: "#FDB515", accentHex: "#FFFFFF", emblemSystemImage: "sun.max.fill"),
        "KY": StateFlagStyle(code: "KY", name: "Kentucky", primaryHex: "#0033A0", secondaryHex: "#FFFFFF", accentHex: "#78BE20", emblemSystemImage: "seal.fill"),
        "LA": StateFlagStyle(code: "LA", name: "Louisiana", primaryHex: "#0050A4", secondaryHex: "#FFFFFF", accentHex: "#FFD100", emblemSystemImage: "drop.fill"),
        "ME": StateFlagStyle(code: "ME", name: "Maine", primaryHex: "#003478", secondaryHex: "#F2C94C", accentHex: "#2E7D32", emblemSystemImage: "tree.fill"),
        "MD": StateFlagStyle(code: "MD", name: "Maryland", primaryHex: "#E03C31", secondaryHex: "#000000", accentHex: "#FFD100", emblemSystemImage: "square.grid.2x2.fill"),
        "MA": StateFlagStyle(code: "MA", name: "Massachusetts", primaryHex: "#FFFFFF", secondaryHex: "#1D4F91", accentHex: "#FDB515", emblemSystemImage: "star.fill"),
        "MI": StateFlagStyle(code: "MI", name: "Michigan", primaryHex: "#00274C", secondaryHex: "#6BA539", accentHex: "#FFCB05", emblemSystemImage: "shield.fill"),
        "MN": StateFlagStyle(code: "MN", name: "Minnesota", primaryHex: "#002D72", secondaryHex: "#65A1D7", accentHex: "#78BE20", emblemSystemImage: "star.fill"),
        "MS": StateFlagStyle(code: "MS", name: "Mississippi", primaryHex: "#C8102E", secondaryHex: "#00205B", accentHex: "#FFD100", emblemSystemImage: "leaf.fill"),
        "MO": StateFlagStyle(code: "MO", name: "Missouri", primaryHex: "#BA0C2F", secondaryHex: "#002D72", accentHex: "#FFFFFF", emblemSystemImage: "star.fill"),
        "MT": StateFlagStyle(code: "MT", name: "Montana", primaryHex: "#002D72", secondaryHex: "#FDB515", accentHex: "#78BE20", emblemSystemImage: "mountain.2.fill"),
        "NE": StateFlagStyle(code: "NE", name: "Nebraska", primaryHex: "#002D72", secondaryHex: "#FDB515", accentHex: "#FFFFFF", emblemSystemImage: "seal.fill"),
        "NV": StateFlagStyle(code: "NV", name: "Nevada", primaryHex: "#003DA5", secondaryHex: "#C0C0C0", accentHex: "#FDB515", emblemSystemImage: "star.fill"),
        "NH": StateFlagStyle(code: "NH", name: "New Hampshire", primaryHex: "#002D72", secondaryHex: "#F5D04C", accentHex: "#FFFFFF", emblemSystemImage: "sun.max.fill"),
        "NJ": StateFlagStyle(code: "NJ", name: "New Jersey", primaryHex: "#F2C75C", secondaryHex: "#003DA5", accentHex: "#8A1538", emblemSystemImage: "shield.fill"),
        "NM": StateFlagStyle(code: "NM", name: "New Mexico", primaryHex: "#FFD100", secondaryHex: "#BF0D3E", accentHex: "#BF0D3E", emblemSystemImage: "sun.max.fill"),
        "NY": StateFlagStyle(code: "NY", name: "New York", primaryHex: "#003DA5", secondaryHex: "#FDB515", accentHex: "#FFFFFF", emblemSystemImage: "shield.fill"),
        "NC": StateFlagStyle(code: "NC", name: "North Carolina", primaryHex: "#002868", secondaryHex: "#BF0A30", accentHex: "#FFFFFF", emblemSystemImage: "star.fill"),
        "ND": StateFlagStyle(code: "ND", name: "North Dakota", primaryHex: "#002D72", secondaryHex: "#FDB515", accentHex: "#FFFFFF", emblemSystemImage: "star.fill"),
        "OH": StateFlagStyle(code: "OH", name: "Ohio", primaryHex: "#BB0000", secondaryHex: "#002855", accentHex: "#FFFFFF", emblemSystemImage: "circle.fill"),
        "OK": StateFlagStyle(code: "OK", name: "Oklahoma", primaryHex: "#0072CE", secondaryHex: "#F2C94C", accentHex: "#C8102E", emblemSystemImage: "shield.fill"),
        "OR": StateFlagStyle(code: "OR", name: "Oregon", primaryHex: "#002A5C", secondaryHex: "#FEE123", accentHex: "#FFFFFF", emblemSystemImage: "star.fill"),
        "PA": StateFlagStyle(code: "PA", name: "Pennsylvania", primaryHex: "#001F5B", secondaryHex: "#FDB515", accentHex: "#78BE20", emblemSystemImage: "shield.fill"),
        "RI": StateFlagStyle(code: "RI", name: "Rhode Island", primaryHex: "#FFFFFF", secondaryHex: "#F6C344", accentHex: "#003DA5", emblemSystemImage: "anchor.fill"),
        "SC": StateFlagStyle(code: "SC", name: "South Carolina", primaryHex: "#003366", secondaryHex: "#FFFFFF", accentHex: "#FFFFFF", emblemSystemImage: "moon.fill"),
        "SD": StateFlagStyle(code: "SD", name: "South Dakota", primaryHex: "#0033A0", secondaryHex: "#FDB515", accentHex: "#FFFFFF", emblemSystemImage: "sun.max.fill"),
        "TN": StateFlagStyle(code: "TN", name: "Tennessee", primaryHex: "#D50032", secondaryHex: "#002D72", accentHex: "#FFFFFF", emblemSystemImage: "star.fill"),
        "TX": StateFlagStyle(code: "TX", name: "Texas", primaryHex: "#002868", secondaryHex: "#BF0A30", accentHex: "#FFFFFF", emblemSystemImage: "star.fill"),
        "UT": StateFlagStyle(code: "UT", name: "Utah", primaryHex: "#002855", secondaryHex: "#D45D00", accentHex: "#F6C344", emblemSystemImage: "hexagon.fill"),
        "VT": StateFlagStyle(code: "VT", name: "Vermont", primaryHex: "#003DA5", secondaryHex: "#78BE20", accentHex: "#FDB515", emblemSystemImage: "tree.fill"),
        "VA": StateFlagStyle(code: "VA", name: "Virginia", primaryHex: "#002D72", secondaryHex: "#FFFFFF", accentHex: "#C8102E", emblemSystemImage: "shield.fill"),
        "WA": StateFlagStyle(code: "WA", name: "Washington", primaryHex: "#2E7D32", secondaryHex: "#FFFFFF", accentHex: "#FDB515", emblemSystemImage: "seal.fill"),
        "WV": StateFlagStyle(code: "WV", name: "West Virginia", primaryHex: "#FFFFFF", secondaryHex: "#003DA5", accentHex: "#FDB515", emblemSystemImage: "mountain.2.fill"),
        "WI": StateFlagStyle(code: "WI", name: "Wisconsin", primaryHex: "#003DA5", secondaryHex: "#FDB515", accentHex: "#FFFFFF", emblemSystemImage: "shield.fill"),
        "WY": StateFlagStyle(code: "WY", name: "Wyoming", primaryHex: "#00205B", secondaryHex: "#C8102E", accentHex: "#FFFFFF", emblemSystemImage: "star.fill")
    ]
}
