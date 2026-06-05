import SwiftUI

struct SavedSchoolsView: View {
    @EnvironmentObject private var appViewModel: AppViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                LumaTheme.canvas
                    .ignoresSafeArea()

                if appViewModel.savedSchools.isEmpty {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Saved")
                            .font(.largeTitle.weight(.heavy))
                            .foregroundStyle(LumaTheme.ink)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        EmptyStateView(
                            title: "No saved schools yet",
                            message: "Tap the bookmark on any school to build a shortlist for your family conversation.",
                            systemImage: "bookmark"
                        )
                    }
                    .padding()
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 14) {
                            Text("Saved")
                                .font(.largeTitle.weight(.heavy))
                                .foregroundStyle(LumaTheme.ink)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            ForEach(appViewModel.savedSchools) { school in
                                NavigationLink {
                                    SchoolDetailView(school: school)
                                } label: {
                                    SchoolCard(
                                        school: school,
                                        isSaved: true,
                                        onSaveTapped: { appViewModel.toggleSaved(school) }
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                }
            }
        }
    }
}
