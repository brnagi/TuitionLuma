import Foundation

struct ComparisonMetric: Identifiable {
    let id = UUID()
    var title: String
    var values: [String]
}

@MainActor
final class CompareViewModel: ObservableObject {
    @Published var selectedSchools: [School] = []

    var metrics: [ComparisonMetric] {
        [
            ComparisonMetric(title: "Annual sticker cost", values: selectedSchools.map { $0.costEstimate.annualStickerCost.formatted(LumaFormat.currency) }),
            ComparisonMetric(title: "Average net price", values: selectedSchools.map { $0.costEstimate.averageNetPrice.formatted(LumaFormat.currency) }),
            ComparisonMetric(title: "TuitionLuma Score", values: selectedSchools.map { "\($0.lumaScore)/100" }),
            ComparisonMetric(title: "Median earnings", values: selectedSchools.map { $0.medianEarnings > 0 ? $0.medianEarnings.formatted(LumaFormat.currency) : "N/A" }),
            ComparisonMetric(title: "Average debt", values: selectedSchools.map { $0.averageDebt > 0 ? $0.averageDebt.formatted(LumaFormat.currency) : "N/A" }),
            ComparisonMetric(title: "Graduation rate", values: selectedSchools.map { $0.graduationRate > 0 ? $0.graduationRate.formatted(LumaFormat.percent) : "N/A" }),
            ComparisonMetric(title: "Acceptance rate", values: selectedSchools.map { $0.admissionRate?.formatted(LumaFormat.percent) ?? "N/A" })
        ]
    }

    func replaceSchool(at index: Int, with school: School) {
        guard selectedSchools.indices.contains(index) else { return }
        selectedSchools[index] = school
    }

    func sync(with schools: [School]) {
        selectedSchools = schools
    }
}
