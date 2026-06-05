import Foundation

struct Program: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var credential: String
    var medianEarnings: Double
    var typicalDurationYears: Int

    init(
        id: UUID = UUID(),
        name: String,
        credential: String,
        medianEarnings: Double,
        typicalDurationYears: Int
    ) {
        self.id = id
        self.name = name
        self.credential = credential
        self.medianEarnings = medianEarnings
        self.typicalDurationYears = typicalDurationYears
    }
}
