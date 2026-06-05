import SwiftUI

struct SavedSchoolsView: View {
    @EnvironmentObject private var appViewModel: AppViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                LumaTheme.canvas
                    .ignoresSafeArea()

                if appViewModel.savedSchools.isEmpty {
                    EmptyStateView(
                        title: "No saved schools yet",
                        message: "Tap the bookmark on any school to build a shortlist for your family conversation.",
                        systemImage: "bookmark"
                    )
                    .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 14) {
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
            .navigationTitle("Saved")
        }
    }
}
