import SwiftUI

struct ExploreView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @EnvironmentObject private var proPurchaseManager: ProPurchaseManager
    @EnvironmentObject private var studentProfileStore: StudentProfileStore
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
                        StudentProfileCard {
                            isShowingPaywall = true
                        }
                        content
                    }
                    .padding()
                    .padding(.bottom, 72)
                }
            }
            .task {
                if viewModel.loadState == .idle {
                    await viewModel.refreshForCurrentQuery()
                    await refreshMajorRecommendationsIfNeeded()
                    appViewModel.remember(viewModel.schools)
                }
            }
            .task(id: viewModel.query) {
                guard viewModel.loadState != .idle else { return }
                await viewModel.searchDebounced()
                await refreshMajorRecommendationsIfNeeded()
                appViewModel.remember(viewModel.schools)
            }
            .task(id: majorRecommendationKey) {
                await refreshMajorRecommendationsIfNeeded()
                appViewModel.remember(viewModel.schools)
            }
            .onChange(of: viewModel.schools) { _, schools in
                appViewModel.remember(schools)
            }
            .sheet(isPresented: $isShowingPaywall) {
                PaywallView()
                    .environmentObject(proPurchaseManager)
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

            Text("Search by school name or state abbreviation.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.9))
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LumaTheme.coolGradient, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
        .foregroundStyle(.white)
    }

    private var searchAndFilters: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(LumaTheme.slate)

                TextField("Search schools or state", text: $viewModel.query)

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
        case .missingAPIKey:
            MissingAPIKeyStateView {
                viewModel.useSampleFallback()
                appViewModel.remember(viewModel.schools)
            }
        case .empty:
            EmptyStateView(
                title: "No colleges found",
                message: "Try a school name, state abbreviation, or another search.",
                systemImage: "building.columns"
            )
        case .failed(let message):
            ErrorStateView(message: message) {
                Task {
                    await viewModel.refreshForCurrentQuery()
                    appViewModel.remember(viewModel.schools)
                }
            }
        case .loaded:
            if viewModel.visibleSchools.isEmpty {
                EmptyStateView(
                    title: "No matches",
                    message: "Try another school type or search.",
                    systemImage: "magnifyingglass"
                )
            } else {
                LazyVStack(spacing: 14) {
                    ForEach(rankedVisibleSchools) { school in
                        NavigationLink {
                            SchoolDetailView(school: school)
                        } label: {
                            SchoolCard(
                                school: school,
                                recommendation: recommendation(for: school),
                                isSaved: appViewModel.isSaved(school),
                                isCompared: appViewModel.isCompared(school),
                                onSaveTapped: { saveTapped(school) },
                                onCompareTapped: { compareTapped(school) }
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    if viewModel.canLoadMore {
                        Button {
                            Task {
                                await viewModel.loadMore()
                                await refreshMajorRecommendationsIfNeeded()
                                appViewModel.remember(viewModel.schools)
                            }
                        } label: {
                            if viewModel.isLoadingMore {
                                ProgressView()
                                    .tint(LumaTheme.coral)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            } else {
                                Label("Load More Colleges", systemImage: "arrow.down.circle.fill")
                                    .font(.headline)
                                    .foregroundStyle(LumaTheme.coral)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var rankedVisibleSchools: [School] {
        guard proPurchaseManager.state.isPro,
              studentProfileStore.profile.isComplete else {
            return viewModel.visibleSchools
        }

        return StudentProfileRecommendationEngine.rankedSchools(
            viewModel.visibleSchools,
            profile: studentProfileStore.profile
        )
    }

    private var majorRecommendationKey: String {
        [
            proPurchaseManager.state.isPro ? "pro" : "free",
            studentProfileStore.profile.normalizedStateResidency,
            studentProfileStore.profile.normalizedMajor,
            String(viewModel.schools.count)
        ].joined(separator: "|")
    }

    private func refreshMajorRecommendationsIfNeeded() async {
        await viewModel.refreshProgramsForMajorRecommendations(
            profile: studentProfileStore.profile,
            isPro: proPurchaseManager.state.isPro
        )
    }

    private func filterChip(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(isSelected ? .white : LumaTheme.ink)
                .padding(.vertical, 9)
                .padding(.horizontal, 14)
                .background(isSelected ? AnyShapeStyle(LumaTheme.coolGradient) : AnyShapeStyle(.white), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private func saveTapped(_ school: School) {
        let limit = ProAccessPolicy.savedSchoolLimit(for: proPurchaseManager.state)
        let result = appViewModel.toggleSaved(school, savedLimit: limit)

        if result == .limitReached {
            isShowingPaywall = true
        }
    }

    private func compareTapped(_ school: School) {
        if appViewModel.isCompared(school) {
            _ = appViewModel.removeFromCompare(school)
            return
        }

        let limit = ProAccessPolicy.compareSchoolLimit(for: proPurchaseManager.state)
        let result = appViewModel.addToCompare(school, compareLimit: limit)

        if result == .limitReached {
            isShowingPaywall = true
        }

        // TODO: Consider switching to the Compare tab after add once tab selection is centralized.
    }

    private func recommendation(for school: School) -> ProfileRecommendation? {
        guard proPurchaseManager.state.isPro,
              studentProfileStore.profile.isComplete else {
            return nil
        }

        return StudentProfileRecommendationEngine.recommendation(
            for: school,
            profile: studentProfileStore.profile
        )
    }
}
