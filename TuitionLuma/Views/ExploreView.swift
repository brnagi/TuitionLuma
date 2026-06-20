import SwiftUI

struct ExploreView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @EnvironmentObject private var proPurchaseManager: ProPurchaseManager
    @EnvironmentObject private var studentProfileStore: StudentProfileStore
    @AppStorage("hasCompletedExploreCoachMarks") private var hasCompletedExploreCoachMarks = false
    @StateObject private var viewModel = ExploreViewModel()
    @State private var isShowingPaywall = false
    @State private var compareLimitMessage: String?
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
                        content
                    }
                    .padding()
                    .padding(.bottom, 72)
                }
                .scrollDismissesKeyboard(.interactively)
                .onTapGesture {
                    isSearchFocused = false
                }

                if let compareLimitMessage {
                    limitBanner(compareLimitMessage)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .frame(maxHeight: .infinity, alignment: .top)
                }
            }
            .overlay {
                if let coachMarkStep, !hasCompletedExploreCoachMarks {
                    ExploreCoachMarkOverlay(
                        step: coachMarkStep,
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
                    await viewModel.refreshForCurrentQuery(homeState: homeStateKey)
                    await refreshMajorRecommendationsIfNeeded()
                    appViewModel.remember(viewModel.schools)
                }
            }
            .task(id: viewModel.query) {
                guard viewModel.loadState != .idle else { return }
                await viewModel.searchDebounced(homeState: homeStateKey)
                await refreshMajorRecommendationsIfNeeded()
                appViewModel.remember(viewModel.schools)
            }
            .task(id: homeStateKey) {
                guard viewModel.loadState != .idle,
                      viewModel.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                await viewModel.refreshForCurrentQuery(homeState: homeStateKey)
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
                .shadow(color: LumaTheme.gradientTextShadow, radius: 4, y: 2)

            Text("Find a college that fits your future and your wallet.")
                .font(.title2.weight(.heavy))
                .foregroundStyle(.white)
                .shadow(color: LumaTheme.gradientTextShadow, radius: 4, y: 2)

            Text("Search by school name or state abbreviation.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.94))
                .shadow(color: LumaTheme.gradientTextShadow, radius: 3, y: 1)

            StudentProfileCard()
                .padding(.top, 8)
                .profileCoachMarkPulse(isActive: coachMarkStep == .profile && !hasCompletedExploreCoachMarks)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            ZStack {
                LumaTheme.coolGradient
                LumaTheme.readableGradientOverlay.opacity(0.58)
            }
            .clipShape(RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
        }
        .foregroundStyle(.white)
        .shadow(color: LumaTheme.cardShadow.opacity(0.36), radius: 16, y: 8)
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
            .shadow(color: LumaTheme.cardShadow.opacity(0.34), radius: 12, y: 6)
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
                    ForEach(Array(rankedVisibleSchools.enumerated()), id: \.element.id) { index, school in
                        NavigationLink {
                            SchoolDetailView(school: school)
                        } label: {
                            SchoolCard(
                                school: school,
                                recommendation: recommendation(for: school),
                                isSaved: appViewModel.isSaved(school),
                                isCompared: appViewModel.isCompared(school),
                                coachMarkHighlight: coachMarkHighlight(forFirstCard: index == 0),
                                onSaveTapped: { saveTapped(school) },
                                onCompareTapped: { compareTapped(school) }
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    if viewModel.canLoadMore {
                        Button {
                            Task {
                                await viewModel.loadMore(homeState: homeStateKey)
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
        let schools: [School]
        if studentProfileStore.profile.isComplete {
            schools = StudentProfileRecommendationEngine.rankedSchools(
                viewModel.visibleSchools,
                profile: studentProfileStore.profile
            )
        } else {
            schools = viewModel.visibleSchools
        }

        return homeStatePrioritized(schools)
    }

    private var homeStateKey: String {
        studentProfileStore.profile.normalizedStateResidency
    }

    private var majorRecommendationKey: String {
        [
            studentProfileStore.profile.normalizedStateResidency,
            studentProfileStore.profile.normalizedMajor,
            studentProfileStore.profile.debtTolerance.rawValue,
            studentProfileStore.profile.ownershipPreference.rawValue,
            String(viewModel.schools.count)
        ].joined(separator: "|")
    }

    private func homeStatePrioritized(_ schools: [School]) -> [School] {
        let homeState = homeStateKey
        guard !homeState.isEmpty else { return schools }

        return schools.enumerated().sorted { lhs, rhs in
            let leftIsHomeState = lhs.element.state.uppercased() == homeState
            let rightIsHomeState = rhs.element.state.uppercased() == homeState

            if leftIsHomeState != rightIsHomeState {
                return leftIsHomeState
            }

            return lhs.offset < rhs.offset
        }.map(\.element)
    }

    private func refreshMajorRecommendationsIfNeeded() async {
        await viewModel.refreshProgramsForMajorRecommendations(
            profile: studentProfileStore.profile
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
        guard ProAccessPolicy.canUse(.schoolCompare, state: proPurchaseManager.state) else {
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
            showCompareLimitMessage()
        }

        // TODO: Consider switching to the Compare tab after add once tab selection is centralized.
    }

    private func recommendation(for school: School) -> ProfileRecommendation? {
        guard studentProfileStore.profile.isComplete else {
            return nil
        }

        return StudentProfileRecommendationEngine.recommendation(
            for: school,
            profile: studentProfileStore.profile
        )
    }

    private func showCompareLimitMessage() {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.9)) {
            compareLimitMessage = "Compare limit reached. You can compare up to 3 schools at a time."
        }

        Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.2)) {
                    compareLimitMessage = nil
                }
            }
        }
    }

    private func limitBanner(_ message: String) -> some View {
        Label(message, systemImage: "info.circle.fill")
            .font(.subheadline.weight(.heavy))
            .foregroundStyle(LumaTheme.ink)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
            .overlay {
                RoundedRectangle(cornerRadius: LumaTheme.cardRadius)
                    .stroke(LumaTheme.coral.opacity(0.22))
            }
            .shadow(color: LumaTheme.cardShadow, radius: 14, y: 8)
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

    private func coachMarkHighlight(forFirstCard isFirstCard: Bool) -> ExploreCoachMarkStep? {
        guard isFirstCard, !hasCompletedExploreCoachMarks else { return nil }

        switch coachMarkStep {
        case .save:
            return .save
        case .compare:
            return .compare
        case .profile, nil:
            return nil
        }
    }
}

enum ExploreCoachMarkStep: Int, CaseIterable {
    case save
    case compare
    case profile

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
    var onSkip: () -> Void
    var onNext: () -> Void

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black.opacity(0.46)
                    .ignoresSafeArea()

                if step == .profile {
                    VStack {
                        Spacer()

                        bubble
                            .frame(maxWidth: min(proxy.size.width - 40, 360))
                            .padding(.horizontal, 20)
                            .padding(.bottom, 28)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    bubble
                        .frame(maxWidth: min(proxy.size.width - 40, 340))
                        .position(x: proxy.size.width / 2, y: bubbleY(in: proxy.size))
                }
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
                    .foregroundStyle(LumaTheme.ink)
                    .frame(minHeight: 44)
                    .padding(.horizontal, 14)
                    .background(.white, in: Capsule())
                    .overlay {
                        Capsule()
                            .stroke(LumaTheme.ink.opacity(0.22), lineWidth: 1)
                    }

                Spacer()

                Button(step.primaryButtonTitle, action: onNext)
                    .font(.subheadline.weight(.heavy))
                    .foregroundStyle(.white)
                    .frame(minHeight: 44)
                    .padding(.horizontal, 16)
                    .background {
                        ZStack {
                            LumaTheme.heroGradient
                            LumaTheme.readableGradientOverlay.opacity(0.34)
                        }
                        .clipShape(Capsule())
                    }
                    .overlay {
                        Capsule()
                            .stroke(.white.opacity(0.28), lineWidth: 1)
                    }
                    .shadow(color: LumaTheme.coral.opacity(0.22), radius: 10, y: 5)
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

    private func bubbleY(in size: CGSize) -> CGFloat {
        let targetY = estimatedTargetY(in: size)
        let shouldShowBelow = targetY < size.height * 0.48
        let bubbleOffset: CGFloat = 220
        let edgePadding: CGFloat = 150
        let proposedY = shouldShowBelow ? targetY + bubbleOffset : targetY - bubbleOffset

        return min(max(proposedY, edgePadding), size.height - edgePadding)
    }

    private func estimatedTargetY(in size: CGSize) -> CGFloat {
        switch step {
        case .save, .compare:
            return size.height * 0.72
        case .profile:
            return size.height * 0.28
        }
    }

}

private struct ProfileCoachMarkPulse: ViewModifier {
    var isActive: Bool
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .overlay {
                if isActive {
                    RoundedRectangle(cornerRadius: LumaTheme.cardRadius + 4)
                        .stroke(LumaTheme.coral, lineWidth: 3)
                        .shadow(color: LumaTheme.coral.opacity(0.52), radius: isPulsing ? 18 : 8)
                        .scaleEffect(isPulsing ? 1.025 : 0.995)
                        .allowsHitTesting(false)
                }
            }
            .animation(.easeInOut(duration: 0.82).repeatForever(autoreverses: true), value: isPulsing)
            .onAppear {
                if isActive {
                    isPulsing = true
                }
            }
            .onChange(of: isActive) { _, newValue in
                isPulsing = newValue
            }
    }
}

private extension View {
    func profileCoachMarkPulse(isActive: Bool) -> some View {
        modifier(ProfileCoachMarkPulse(isActive: isActive))
    }
}
