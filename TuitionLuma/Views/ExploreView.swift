import SwiftUI

struct ExploreView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @EnvironmentObject private var subscriptionManager: MockSubscriptionManager
    @StateObject private var viewModel = ExploreViewModel()
    @State private var isShowingPaywall = false

    var body: some View {
        NavigationStack {
            ZStack {
                LumaTheme.canvas
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        header
                        searchAndFilters
                        content
                    }
                    .padding()
                }
            }
            .task {
                if viewModel.loadState == .idle {
                    await viewModel.load()
                }
            }
            .sheet(isPresented: $isShowingPaywall) {
                PaywallView()
                    .environmentObject(subscriptionManager)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Explore")
                .font(.largeTitle.weight(.heavy))
                .foregroundStyle(.white)

            Text("Find a college that fits your future and your wallet.")
                .font(.title2.weight(.heavy))
                .foregroundStyle(.white)

            Text("Search by school, city, state, or program.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.9))
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LumaTheme.warmGradient, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
        .foregroundStyle(.white)
        .overlay(alignment: .topTrailing) {
            if subscriptionManager.state.isPro {
                ProBadge()
                    .padding(14)
            }
        }
    }

    private var searchAndFilters: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(LumaTheme.slate)

                TextField("Search schools or programs", text: $viewModel.query)

                if !viewModel.query.isEmpty {
                    Button {
                        viewModel.query = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(LumaTheme.slate)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(14)
            .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    filterChip("All", isSelected: viewModel.selectedType == nil) {
                        viewModel.selectedType = nil
                    }

                    ForEach(School.SchoolType.allCases, id: \.self) { type in
                        filterChip(type.rawValue, isSelected: viewModel.selectedType == type) {
                            viewModel.selectedType = type
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.loadState {
        case .idle, .loading:
            LoadingStateView()
        case .empty:
            EmptyStateView(
                title: "No schools yet",
                message: "When live College Scorecard search is connected, schools will appear here.",
                systemImage: "building.columns"
            )
        case .failed(let message):
            ErrorStateView(message: message) {
                Task { await viewModel.load() }
            }
        case .loaded:
            if viewModel.filteredSchools.isEmpty {
                EmptyStateView(
                    title: "No matches",
                    message: "Try a different school, state, or program.",
                    systemImage: "magnifyingglass"
                )
            } else {
                LazyVStack(spacing: 14) {
                    ForEach(viewModel.filteredSchools) { school in
                        NavigationLink {
                            SchoolDetailView(school: school)
                        } label: {
                            SchoolCard(
                                school: school,
                                isSaved: appViewModel.isSaved(school),
                                onSaveTapped: { saveTapped(school) }
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func filterChip(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(isSelected ? .white : LumaTheme.ink)
                .padding(.vertical, 9)
                .padding(.horizontal, 14)
                .background(isSelected ? AnyShapeStyle(LumaTheme.heroGradient) : AnyShapeStyle(.white), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private func saveTapped(_ school: School) {
        let limit = SubscriptionPolicy.savedSchoolLimit(for: subscriptionManager.state)
        let result = appViewModel.toggleSaved(school, savedLimit: limit)

        if result == .limitReached {
            isShowingPaywall = true
        }
    }
}
