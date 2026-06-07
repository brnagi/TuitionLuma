import SwiftUI

struct ProgramDetailView: View {
    var school: School
    var program: AcademicProgram

    private var roiOutcome: ROIOutcomeResult {
        ROIOutcomeCalculator.result(for: school, program: program)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                metrics
                careerPathNotes
                programData
            }
            .padding()
        }
        .background(LumaTheme.canvas)
        .navigationTitle("Program Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(program.name)
                .font(.title2.weight(.heavy))
                .foregroundStyle(LumaTheme.ink)
                .fixedSize(horizontal: false, vertical: true)

            Text(program.credential)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(LumaTheme.slate)

            if let category = program.category {
                Text(category)
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(LumaTheme.outcomeTeal)
                    .padding(.vertical, 7)
                    .padding(.horizontal, 10)
                    .background(LumaTheme.aqua.opacity(0.12), in: Capsule())
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
    }

    private var metrics: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            detailMetric(
                title: "Median Earnings",
                value: program.medianEarnings > 0 ? program.medianEarnings.formatted(LumaFormat.currency) : "Not available",
                tint: LumaTheme.outcomeTeal
            )

            detailMetric(
                title: "Median Debt",
                value: program.debt.map { $0.formatted(LumaFormat.currency) } ?? "Not available",
                tint: LumaTheme.sun
            )

            detailMetric(
                title: "ROI Score",
                value: "\(roiOutcome.grade) • \(roiOutcome.score)/100",
                tint: LumaTheme.mint
            )

            detailMetric(
                title: "Reported Completions",
                value: program.completionCount.map(String.init) ?? "Not available",
                tint: LumaTheme.coral
            )
        }
    }

    private var careerPathNotes: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Career Path Notes")
                .font(.headline)
                .foregroundStyle(LumaTheme.ink)

            if program.pathLabels.isEmpty {
                Text("No program-specific path notes are available yet.")
                    .font(.subheadline)
                    .foregroundStyle(LumaTheme.slate)
            } else {
                ForEach(program.pathLabels, id: \.self) { label in
                    Label(pathCopy(for: label), systemImage: "checkmark.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(LumaTheme.slate)
                }
            }

            if program.medianEarnings <= 0 {
                Text("No program-specific salary data is available for this program. Using school-wide outcomes instead.")
                    .font(.caption)
                    .foregroundStyle(LumaTheme.slate)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(18)
        .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
    }

    private var programData: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Program Data")
                .font(.headline)
                .foregroundStyle(LumaTheme.ink)

            ComparisonRow(title: "Credential", values: [program.credential])
            ComparisonRow(title: "Category", values: [program.category ?? "Not available"])
            ComparisonRow(title: "CIP code", values: [program.cipCode ?? "Not available"])
        }
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
    }

    private func detailMetric(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(value)
                .font(.headline.weight(.heavy))
                .foregroundStyle(value == "Not available" ? LumaTheme.slate : LumaTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.68)

            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(LumaTheme.slate)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
    }

    private func pathCopy(for label: AcademicPathLabel) -> String {
        switch label {
        case .standardUndergraduate:
            return "Standard undergraduate path"
        case .graduateSchoolLikely:
            return "Graduate study commonly pursued"
        case .professionalLicensureLikely:
            return "Professional licensure likely"
        case .labClinicalIntensive:
            return "Clinical or lab intensive"
        case .equipmentIntensive:
            return "Equipment intensive"
        case .longerTimeToDegreeRisk:
            return "Longer time-to-degree risk"
        }
    }
}
