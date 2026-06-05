import Foundation

struct ComparisonMetric: Identifiable {
    let id = UUID()
    var title: String
    var values: [String]
}

@MainActor
final class CompareViewModel: ObservableObject {
    @Published var selectedSchools: [School]
    let allSchools: [School]

    init(allSchools: [School] = MockSchools.all) {
        self.allSchools = allSchools
        self.selectedSchools = Array(allSchools.prefix(2))
    }

    var metrics: [ComparisonMetric] {
        [
            ComparisonMetric(title: "Annual sticker cost", values: selectedSchools.map { $0.costEstimate.annualStickerCost.formatted(LumaFormat.currency) }),
            ComparisonMetric(title: "Average net price", values: selectedSchools.map { $0.costEstimate.averageNetPrice.formatted(LumaFormat.currency) }),
            ComparisonMetric(title: "TuitionLuma Score", values: selectedSchools.map { "\($0.lumaScore)/100" }),
            ComparisonMetric(title: "Median earnings", values: selectedSchools.map { $0.medianEarnings.formatted(LumaFormat.currency) }),
            ComparisonMetric(title: "Average debt", values: selectedSchools.map { $0.averageDebt.formatted(LumaFormat.currency) }),
            ComparisonMetric(title: "Graduation rate", values: selectedSchools.map { $0.graduationRate.formatted(LumaFormat.percent) }),
            ComparisonMetric(title: "Acceptance rate", values: selectedSchools.map { $0.acceptanceRate.formatted(LumaFormat.percent) })
        ]
    }

    func replaceSchool(at index: Int, with school: School) {
        guard selectedSchools.indices.contains(index) else { return }
        selectedSchools[index] = school
    }

    func addSchool(limit: Int) {
        guard selectedSchools.count < limit else { return }
        let nextSchool = allSchools.first { !selectedSchools.contains($0) } ?? allSchools[0]
        selectedSchools.append(nextSchool)
    }

    func trimSelection(to limit: Int) {
        guard selectedSchools.count > limit else { return }
        selectedSchools = Array(selectedSchools.prefix(limit))
    }

    func sync(with schools: [School]) {
        selectedSchools = schools.isEmpty ? Array(allSchools.prefix(2)) : schools
    }
}
