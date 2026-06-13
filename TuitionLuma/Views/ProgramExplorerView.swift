import SwiftUI

struct ProgramExplorerView: View {
    var school: School
    var programs: [AcademicProgram]
    @State private var searchText = ""
    @State private var selectedCategory = "All"
    @State private var selectedCredential = "All"
    @FocusState private var isSearchFocused: Bool

    private var categories: [String] {
        ["All"] + Array(Set(programs.compactMap(\.category))).sorted()
    }

    private var credentials: [String] {
        ["All"] + Array(Set(programs.map(\.credential))).sorted()
    }

    private var filteredPrograms: [AcademicProgram] {
        programs
            .filter { program in
                searchText.isEmpty || program.name.localizedCaseInsensitiveContains(searchText)
            }
            .filter { program in
                selectedCategory == "All" || program.category == selectedCategory
            }
            .filter { program in
                selectedCredential == "All" || program.credential == selectedCredential
            }
            .sorted { lhs, rhs in
                let leftHasEarnings = lhs.medianEarnings > 0
                let rightHasEarnings = rhs.medianEarnings > 0
                if leftHasEarnings != rightHasEarnings {
                    return leftHasEarnings
                }

                if lhs.medianEarnings != rhs.medianEarnings {
                    return lhs.medianEarnings > rhs.medianEarnings
                }

                return (lhs.completionCount ?? 0) > (rhs.completionCount ?? 0)
            }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                searchField
                filters

                if filteredPrograms.isEmpty {
                    EmptyStateView(
                        title: "No matching programs",
                        message: "Try a different search or filter.",
                        systemImage: "magnifyingglass"
                    )
                    .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
                } else {
                    ForEach(filteredPrograms) { program in
                        NavigationLink {
                            ProgramDetailView(school: school, program: program)
                        } label: {
                            ProgramListRow(program: program, school: school)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
        .background(LumaTheme.canvas)
        .scrollDismissesKeyboard(.interactively)
        .onTapGesture {
            isSearchFocused = false
        }
        .navigationTitle("All Programs")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()

                Button("Done") {
                    isSearchFocused = false
                }
                .fontWeight(.bold)
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(LumaTheme.slate)
                .accessibilityHidden(true)

            TextField(
                text: $searchText,
                prompt: Text("Search programs")
                    .foregroundStyle(LumaTheme.slate)
            ) {
                Text("Search programs")
            }
                .focused($isSearchFocused)
                .textInputAutocapitalization(.words)
                .foregroundStyle(LumaTheme.ink)
                .tint(LumaTheme.coral)
                .submitLabel(.search)
                .onSubmit {
                    isSearchFocused = false
                }
                .accessibilityLabel("Search programs")
        }
        .padding(14)
        .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
        .overlay {
            RoundedRectangle(cornerRadius: LumaTheme.cardRadius)
                .stroke(isSearchFocused ? LumaTheme.coral.opacity(0.45) : LumaTheme.cardStroke)
        }
    }

    private var filters: some View {
        VStack(spacing: 10) {
            Menu {
                Picker("Category", selection: $selectedCategory) {
                    ForEach(categories, id: \.self) { category in
                        Text(category).tag(category)
                    }
                }
            } label: {
                filterLabel(title: "Category", value: selectedCategory)
            }

            Menu {
                Picker("Credential", selection: $selectedCredential) {
                    ForEach(credentials, id: \.self) { credential in
                        Text(credential).tag(credential)
                    }
                }
            } label: {
                filterLabel(title: "Credential", value: selectedCredential)
            }
        }
    }

    private func filterLabel(title: String, value: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(LumaTheme.slate)

                Text(value)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(LumaTheme.ink)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.up.chevron.down")
                .font(.caption.weight(.bold))
                .foregroundStyle(LumaTheme.slate)
                .accessibilityHidden(true)
        }
        .padding(14)
        .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(value)
    }
}

struct ProgramListRow: View {
    var program: AcademicProgram
    var school: School

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(program.name)
                    .font(.headline)
                    .foregroundStyle(LumaTheme.ink)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(LumaTheme.slate)
                    .lineLimit(2)

                if program.medianEarnings <= 0 {
                    Text("No program-specific salary data is available for this program.")
                        .font(.caption)
                        .foregroundStyle(LumaTheme.slate)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: 4) {
                Text(program.medianEarnings > 0 ? program.medianEarnings.formatted(LumaFormat.currency) : "N/A")
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(program.medianEarnings > 0 ? LumaTheme.ink : LumaTheme.slate)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Text("median salary")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(LumaTheme.slate)
                    .lineLimit(1)
            }
            .frame(width: 96, alignment: .trailing)
        }
        .padding(14)
        .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
        .overlay {
            RoundedRectangle(cornerRadius: LumaTheme.cardRadius)
                .stroke(Color.black.opacity(0.04), lineWidth: 1)
        }
    }

    private var subtitle: String {
        [
            program.credential,
            program.debt.map { "Debt \($0.formatted(LumaFormat.currency))" },
            program.category
        ]
        .compactMap { $0 }
        .joined(separator: " • ")
    }
}
