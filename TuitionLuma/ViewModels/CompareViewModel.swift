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
        self.selectedSchools = Array(allSchools.prefix(3))
    }

    var metrics: [ComparisonMetric] {
        [
            ComparisonMetric(title: "Annual sticker cost", values: selectedSchools.map { $0.costEstimate.annualStickerCost.formatted(LumaFormat.currency) }),
            ComparisonMetric(title: "Average net price", values: selectedSchools.map { $0.costEstimate.averageNetPrice.formatted(LumaFormat.currency) }),
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
}
