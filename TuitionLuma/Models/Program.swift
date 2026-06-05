import Foundation

struct Program: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var credential: String
    var cipCode: String?
    var medianEarnings: Double
    var debt: Double?
    var completionCount: Int?
    var typicalDurationYears: Int

    init(
        id: UUID = UUID(),
        name: String,
        credential: String,
        cipCode: String? = nil,
        medianEarnings: Double,
        debt: Double? = nil,
        completionCount: Int? = nil,
        typicalDurationYears: Int
    ) {
        self.id = id
        self.name = name
        self.credential = credential
        self.cipCode = cipCode
        self.medianEarnings = medianEarnings
        self.debt = debt
        self.completionCount = completionCount
        self.typicalDurationYears = typicalDurationYears
    }
}
