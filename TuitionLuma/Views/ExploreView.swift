import SwiftUI

struct ExploreView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @EnvironmentObject private var proPurchaseManager: ProPurchaseManager
    @EnvironmentObject private var studentProfileStore: StudentProfileStore
    @AppStorage("hasCompletedExploreCoachMarks") private var hasCompletedExploreCoachMarks = false
    @StateObject private var viewModel = ExploreViewModel()
    @State private var isShowingPaywall = false
    @State private var coachMarkStep: ExploreCoachMarkStep?
    @FocusState private var isSearchFocused: Bool

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
                        .background {
                            GeometryReader { proxy in
                                Color.clear.preference(
                                    key: ExploreCoachMarkTargetKey.self,
                                    value: [.profile: proxy.frame(in: .named(ExploreCoachMarkTargetKey.coordinateSpaceName))]
                                )
                            }
                        }
                        content
                    }
                    .padding()
                    .padding(.bottom, 72)
                }
                .scrollDismissesKeyboard(.interactively)
                .onTapGesture {
                    isSearchFocused = false
                }
            }
            .coordinateSpace(name: ExploreCoachMarkTargetKey.coordinateSpaceName)
            .overlayPreferenceValue(ExploreCoachMarkTargetKey.self) { targets in
                if let coachMarkStep, !hasCompletedExploreCoachMarks {
                    ExploreCoachMarkOverlay(
                        step: coachMarkStep,
                        targetRect: targets[coachMarkStep.target],
                        onSkip: completeCoachMarks,
                        onNext: advanceCoachMark
                    )
                }
            }
            .onAppear {
                if !hasCompletedExploreCoachMarks, coachMarkStep == nil {
                    coachMarkStep = .save
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
                    .accessibilityHidden(true)

                TextField(
                    text: $viewModel.query,
                    prompt: Text("Search schools or state")
                        .foregroundStyle(LumaTheme.slate)
                ) {
                    Text("Search schools or state")
                }
                    .focused($isSearchFocused)
                    .foregroundStyle(LumaTheme.ink)
                    .tint(LumaTheme.coral)
                    .submitLabel(.search)
                    .onSubmit {
                        isSearchFocused = false
                    }
                    .accessibilityLabel("Search schools or state")

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
            .overlay {
                RoundedRectangle(cornerRadius: LumaTheme.cardRadius)
                    .stroke(isSearchFocused ? LumaTheme.coral.opacity(0.45) : LumaTheme.cardStroke)
            }
            .shadow(color: LumaTheme.cardShadow.opacity(0.25), radius: 10, y: 4)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()

                    Button("Done") {
                        isSearchFocused = false
                    }
                    .fontWeight(.bold)
                }
            }

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
            .accessibilityLabel("School type filters")
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
                            .background {
                                GeometryReader { proxy in
                                    Color.clear.preference(
                                        key: ExploreCoachMarkTargetKey.self,
                                        value: schoolCardCoachMarkTargets(
                                            in: proxy.frame(in: .named(ExploreCoachMarkTargetKey.coordinateSpaceName))
                                        )
                                    )
                                }
                            }
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
                                    .accessibilityLabel("Loading more colleges")
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
                        .accessibilityLabel(viewModel.isLoadingMore ? "Loading more colleges" : "Load more colleges")
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
                .frame(minHeight: 44)
                .padding(.vertical, 9)
                .padding(.horizontal, 14)
                .background(isSelected ? AnyShapeStyle(LumaTheme.coolGradient) : AnyShapeStyle(.white), in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityHint("Filters the school list.")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private func saveTapped(_ school: School) {
        let limit = ProAccessPolicy.savedSchoolLimit(for: proPurchaseManager.state)
        let result = appViewModel.toggleSaved(school, savedLimit: limit)

        if result == .limitReached {
            isShowingPaywall = true
        }
    }

    private func compareTapped(_ school: School) {
        guard proPurchaseManager.state.isPro else {
            isShowingPaywall = true
            return
        }

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

    private func advanceCoachMark() {
        guard let coachMarkStep else {
            completeCoachMarks()
            return
        }

        if let nextStep = coachMarkStep.next {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.88)) {
                self.coachMarkStep = nextStep
            }
        } else {
            completeCoachMarks()
        }
    }

    private func completeCoachMarks() {
        withAnimation(.easeOut(duration: 0.18)) {
            hasCompletedExploreCoachMarks = true
            coachMarkStep = nil
        }
    }

    private func schoolCardCoachMarkTargets(in frame: CGRect) -> [ExploreCoachMarkTarget: CGRect] {
        let contentPadding: CGFloat = 18
        let heroHeight: CGFloat = 124
        let buttonHeight: CGFloat = 44
        let saveWidth: CGFloat = 86
        let compareWidth: CGFloat = 118
        let spacing: CGFloat = 8
        let buttonTop = frame.minY + heroHeight + contentPadding
        let saveFrame = CGRect(
            x: frame.maxX - contentPadding - saveWidth,
            y: buttonTop,
            width: saveWidth,
            height: buttonHeight
        )
        let compareFrame = CGRect(
            x: saveFrame.minX - spacing - compareWidth,
            y: buttonTop,
            width: compareWidth,
            height: buttonHeight
        )

        return [
            .save: saveFrame,
            .compare: compareFrame
        ]
    }
}

enum ExploreCoachMarkTarget: Hashable {
    case save
    case compare
    case profile
}

struct ExploreCoachMarkTargetKey: PreferenceKey {
    static let coordinateSpaceName = "exploreCoachMarks"
    static var defaultValue: [ExploreCoachMarkTarget: CGRect] = [:]

    static func reduce(
        value: inout [ExploreCoachMarkTarget: CGRect],
        nextValue: () -> [ExploreCoachMarkTarget: CGRect]
    ) {
        value.merge(nextValue(), uniquingKeysWith: { current, _ in current })
    }
}

enum ExploreCoachMarkStep: Int, CaseIterable {
    case save
    case compare
    case profile

    var target: ExploreCoachMarkTarget {
        switch self {
        case .save:
            return .save
        case .compare:
            return .compare
        case .profile:
            return .profile
        }
    }

    var title: String {
        switch self {
        case .save:
            return "Save schools"
        case .compare:
            return "Compare your options"
        case .profile:
            return "Personalize your results"
        }
    }

    var body: String {
        switch self {
        case .save:
            return "Build a shortlist of schools you're considering so you can compare cost, debt, and outcomes later."
        case .compare:
            return "Compare up to 3 schools side-by-side and see which one looks strongest for your profile."
        case .profile:
            return "Add your major, residency, and income to improve recommendations, affordability, and ROI estimates."
        }
    }

    var next: ExploreCoachMarkStep? {
        ExploreCoachMarkStep(rawValue: rawValue + 1)
    }

    var primaryButtonTitle: String {
        next == nil ? "Get Started" : "Next"
    }
}

private struct ExploreCoachMarkOverlay: View {
    var step: ExploreCoachMarkStep
    var targetRect: CGRect?
    var onSkip: () -> Void
    var onNext: () -> Void

    var body: some View {
        GeometryReader { proxy in
            let targetRect = resolvedTargetRect(in: proxy)
            let bubbleIsBelow = targetRect.midY < proxy.size.height * 0.58

            ZStack {
                spotlightMask(targetRect: targetRect)

                RoundedRectangle(cornerRadius: 18)
                    .stroke(.white.opacity(0.95), lineWidth: 2)
                    .shadow(color: .black.opacity(0.22), radius: 14, y: 8)
                    .frame(
                        width: max(96, targetRect.width + 20),
                        height: max(54, targetRect.height + 18)
                    )
                    .position(x: targetRect.midX, y: targetRect.midY)

                bubble
                    .frame(maxWidth: min(proxy.size.width - 40, 340))
                    .position(
                        x: min(max(targetRect.midX, 190), proxy.size.width - 190),
                        y: bubbleY(targetRect: targetRect, in: proxy.size, isBelow: bubbleIsBelow)
                    )
            }
            .ignoresSafeArea()
        }
        .transition(.opacity.combined(with: .scale(scale: 0.98)))
        .zIndex(20)
    }

    private var bubble: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(step.title)
                        .font(.headline.weight(.heavy))
                        .foregroundStyle(LumaTheme.ink)

                    Text(step.body)
                        .font(.subheadline)
                        .foregroundStyle(LumaTheme.slate)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                Text("\(step.rawValue + 1)/\(ExploreCoachMarkStep.allCases.count)")
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(LumaTheme.coral)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                    .background(LumaTheme.coral.opacity(0.10), in: Capsule())
            }

            HStack(spacing: 10) {
                Button("Skip", action: onSkip)
                    .font(.subheadline.weight(.heavy))
                    .foregroundStyle(LumaTheme.slate)
                    .frame(minHeight: 44)
                    .padding(.horizontal, 8)

                Spacer()

                Button(step.primaryButtonTitle, action: onNext)
                    .font(.subheadline.weight(.heavy))
                    .foregroundStyle(.white)
                    .frame(minHeight: 44)
                    .padding(.horizontal, 16)
                    .background(LumaTheme.heroGradient, in: Capsule())
            }
        }
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
        .overlay {
            RoundedRectangle(cornerRadius: LumaTheme.cardRadius)
                .stroke(LumaTheme.cardStroke)
        }
        .shadow(color: .black.opacity(0.22), radius: 24, y: 14)
        .accessibilityElement(children: .contain)
    }

    private func spotlightMask(targetRect: CGRect) -> some View {
        Color.black.opacity(0.54)
            .mask {
                Rectangle()
                    .overlay {
                        RoundedRectangle(cornerRadius: 18)
                            .frame(
                                width: max(96, targetRect.width + 20),
                                height: max(54, targetRect.height + 18)
                            )
                            .position(x: targetRect.midX, y: targetRect.midY)
                            .blendMode(.destinationOut)
                    }
                    .compositingGroup()
            }
    }

    private func resolvedTargetRect(in proxy: GeometryProxy) -> CGRect {
        guard let targetRect, !targetRect.isEmpty else {
            return CGRect(x: 24, y: proxy.size.height * 0.36, width: proxy.size.width - 48, height: 70)
        }

        return targetRect
    }

    private func bubbleY(targetRect: CGRect, in size: CGSize, isBelow: Bool) -> CGFloat {
        let spacing: CGFloat = 112
        if isBelow {
            return min(targetRect.maxY + spacing, size.height - 158)
        }

        return max(targetRect.minY - spacing, 156)
    }
}
