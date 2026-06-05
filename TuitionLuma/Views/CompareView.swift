import SwiftUI

struct CompareView: View {
    @StateObject private var viewModel = CompareViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    selectors
                    comparisonTable
                }
                .padding()
            }
            .background(LumaTheme.canvas)
            .navigationTitle("Compare")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Line up the tradeoffs.")
                .font(.title2.weight(.heavy))
                .foregroundStyle(LumaTheme.ink)

            Text("Swap schools to compare cost, debt, earnings, and completion side by side.")
                .font(.subheadline)
                .foregroundStyle(LumaTheme.slate)
        }
    }

    private var selectors: some View {
        VStack(spacing: 10) {
            ForEach(viewModel.selectedSchools.indices, id: \.self) { index in
                Menu {
                    Picker(
                        "School \(index + 1)",
                        selection: Binding(
                            get: { viewModel.selectedSchools[index] },
                            set: { viewModel.replaceSchool(at: index, with: $0) }
                        )
                    ) {
                        ForEach(viewModel.allSchools) { school in
                            Text(school.name).tag(school)
                        }
                    }
                } label: {
                    HStack {
                        Text("\(index + 1)")
                            .font(.headline.weight(.heavy))
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(indexColor(index), in: Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            Text(viewModel.selectedSchools[index].name)
                                .font(.headline)
                                .foregroundStyle(LumaTheme.ink)
                                .lineLimit(1)

                            Text("\(viewModel.selectedSchools[index].city), \(viewModel.selectedSchools[index].state)")
                                .font(.caption)
                                .foregroundStyle(LumaTheme.slate)
                        }

                        Spacer()

                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(LumaTheme.slate)
                    }
                    .padding(14)
                    .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
                }
            }
        }
    }

    private var comparisonTable: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                ForEach(viewModel.selectedSchools) { school in
                    Text(school.name)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.72)
                        .frame(maxWidth: .infinity, minHeight: 46)
                        .padding(8)
                        .background(LumaTheme.heroGradient, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
                }
            }
            .padding(.bottom, 10)

            ForEach(viewModel.metrics) { metric in
                ComparisonRow(title: metric.title, values: metric.values)

                if metric.id != viewModel.metrics.last?.id {
                    Divider()
                }
            }
        }
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
    }

    private func indexColor(_ index: Int) -> Color {
        [LumaTheme.coral, LumaTheme.aqua, LumaTheme.sun][index % 3]
    }
}
