import SwiftUI

struct OnboardingView: View {
    @Binding var profile: StudentProfile
    @State private var draft: StudentProfile
    @FocusState private var focusedField: OnboardingField?
    var onContinue: () -> Void

    private enum OnboardingField: Hashable {
        case nickname
        case testScore
    }

    init(profile: Binding<StudentProfile>, onContinue: @escaping () -> Void) {
        self._profile = profile
        var onboardingDraft = profile.wrappedValue
        onboardingDraft.intendedMajor = ""
        self._draft = State(initialValue: onboardingDraft)
        self.onContinue = onContinue
    }

    var body: some View {
        ZStack {
            LumaTheme.canvas
                .ignoresSafeArea()

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        hero
                        basicsSection
                        academicSection
                        residencyAndIncomeSection
                        preferencesSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 18)
                    .padding(.bottom, focusedField == nil ? 24 : 32)
                }
                .scrollDismissesKeyboard(.interactively)
                .onTapGesture {
                    focusedField = nil
                }
                .onChange(of: focusedField) { _, field in
                    guard let field else { return }
                    withAnimation(.easeOut(duration: 0.22)) {
                        proxy.scrollTo(field, anchor: .center)
                    }
                }
            }

            skipButton
                .padding(.top, 14)
                .padding(.trailing, 16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        }
        .safeAreaInset(edge: .bottom) {
            if focusedField == nil {
                actionBar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.18), value: focusedField)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()

                Button {
                    focusedField = nil
                } label: {
                    Text("Done")
                        .font(.subheadline.weight(.heavy))
                        .foregroundStyle(.white)
                        .padding(.vertical, 7)
                        .padding(.horizontal, 14)
                        .background(LumaTheme.coral, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Dismiss keyboard")
            }
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "sun.max.fill")
                    .font(.title3)
                Text("TuitionLuma")
                    .font(.title3.weight(.heavy))
            }
            .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 8) {
                Text("See what college will really cost.")
                    .font(.system(size: 32, weight: .heavy))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Add a few details now, or skip and explore. Your profile helps personalize affordability, debt, earnings, and value signals.")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.92))
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 8) {
                onboardingPill("Affordability", systemImage: "dollarsign.circle.fill")
                onboardingPill("Debt", systemImage: "creditcard.fill")
                onboardingPill("Outcomes", systemImage: "chart.line.uptrend.xyaxis")
            }
        }
        .padding(20)
        .background {
            ZStack {
                LumaTheme.heroGradient
                LumaTheme.readableGradientOverlay.opacity(0.32)
            }
            .clipShape(RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
        }
        .shadow(color: LumaTheme.coral.opacity(0.18), radius: 18, y: 9)
    }

    private var skipButton: some View {
        Button("Skip") {
            finishOnboarding()
        }
        .font(.subheadline.weight(.heavy))
        .foregroundStyle(LumaTheme.coral)
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(.white, in: Capsule())
        .overlay {
            Capsule()
                .stroke(LumaTheme.coral.opacity(0.24))
        }
        .shadow(color: LumaTheme.cardShadow.opacity(0.18), radius: 12, y: 6)
        .accessibilityHint("Skips profile setup and opens Explore.")
    }

    private var basicsSection: some View {
        onboardingSection(
            title: "About you",
            subtitle: "Optional, but it makes recommendations feel more personal.",
            systemImage: "person.crop.circle.fill",
            tint: LumaTheme.aqua
        ) {
            TextField(
                text: $draft.nickname,
                prompt: Text("Nickname, for example Alex")
                    .foregroundStyle(LumaTheme.slate)
            ) {
                Text("Nickname")
            }
            .focused($focusedField, equals: .nickname)
            .textInputAutocapitalization(.words)
            .submitLabel(.next)
            .onSubmit {
                focusedField = .testScore
            }
            .lumaTextField(isFocused: focusedField == .nickname)
            .id(OnboardingField.nickname)
            .accessibilityLabel("Optional nickname")
        }
    }

    private var academicSection: some View {
        onboardingSection(
            title: "Academic profile",
            subtitle: "GPA and test scores help tune fit and outcome estimates.",
            systemImage: "graduationcap.fill",
            tint: LumaTheme.coral
        ) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("GPA")
                        .font(.subheadline.weight(.heavy))
                        .foregroundStyle(LumaTheme.ink)

                    Spacer()

                    Text(draft.gpa.formatted(.number.precision(.fractionLength(1))))
                        .font(.title3.weight(.heavy))
                        .foregroundStyle(LumaTheme.coral)
                }

                Slider(value: $draft.gpa, in: 0...4, step: 0.1)
                    .tint(LumaTheme.coral)
                    .accessibilityLabel("GPA")
                    .accessibilityValue(draft.gpa.formatted(.number.precision(.fractionLength(1))))

                TextField(
                    text: $draft.testScore,
                    prompt: Text("SAT/ACT optional, for example 1320 or 29")
                        .foregroundStyle(LumaTheme.slate)
                ) {
                    Text("SAT or ACT score")
                }
                .focused($focusedField, equals: .testScore)
                .keyboardType(.numbersAndPunctuation)
                .textInputAutocapitalization(.never)
                .submitLabel(.done)
                .onSubmit {
                    focusedField = nil
                }
                .lumaTextField(isFocused: focusedField == .testScore)
                .id(OnboardingField.testScore)
                .accessibilityLabel("SAT or ACT score")
                .accessibilityHint("Optional.")
            }
        }
    }

    private var residencyAndIncomeSection: some View {
        onboardingSection(
            title: "Cost profile",
            subtitle: "Residency and income improve net-price and aid estimates.",
            systemImage: "map.fill",
            tint: LumaTheme.outcomeTeal
        ) {
            VStack(alignment: .leading, spacing: 12) {
                menuPicker("State Residency", selection: $draft.stateResidency) {
                    Text("Select a state").tag("")

                    ForEach(USState.all) { state in
                        Text(state.name).tag(state.abbreviation)
                    }
                }
                .onAppear {
                    draft.stateResidency = draft.normalizedStateResidency
                }
                .accessibilityValue(draft.stateResidency.isEmpty ? "No state selected" : draft.stateResidencyDisplayName)

                menuPicker("Family Income Range", selection: $draft.familyIncomeRange) {
                    ForEach(FamilyIncomeRange.allCases) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .accessibilityValue(draft.familyIncomeRange.rawValue)
            }
        }
    }

    private var preferencesSection: some View {
        onboardingSection(
            title: "Optional preferences",
            subtitle: "Fine-tune results for school type, location, format, size, and debt comfort.",
            systemImage: "slider.horizontal.3",
            tint: LumaTheme.scoreGold
        ) {
            VStack(alignment: .leading, spacing: 14) {
                preferenceGroup(title: "Public / Private Preference") {
                    ForEach(SchoolOwnershipPreference.allCases) { preference in
                        preferenceButton(
                            title: preference.rawValue,
                            isSelected: draft.ownershipPreference == preference
                        ) {
                            draft.ownershipPreference = preference
                        }
                    }
                }

                preferenceGroup(title: "Distance From Home") {
                    ForEach(DistanceFromHomePreference.allCases) { preference in
                        preferenceButton(
                            title: preference.rawValue,
                            isSelected: draft.distanceFromHomePreference == preference
                        ) {
                            draft.distanceFromHomePreference = preference
                        }
                    }
                }

                preferenceGroup(title: "Campus Size") {
                    ForEach(CampusSizePreference.allCases) { preference in
                        preferenceButton(
                            title: preference.rawValue,
                            isSelected: draft.campusSizePreference == preference
                        ) {
                            draft.campusSizePreference = preference
                        }
                    }
                }

                preferenceGroup(title: "Learning Format") {
                    ForEach(LearningFormatPreference.allCases) { preference in
                        preferenceButton(
                            title: preference.rawValue,
                            isSelected: draft.learningFormatPreference == preference
                        ) {
                            draft.learningFormatPreference = preference
                        }
                    }
                }

                preferenceGroup(title: "Debt Tolerance") {
                    ForEach(DebtTolerance.allCases) { tolerance in
                        preferenceButton(
                            title: tolerance.rawValue,
                            isSelected: draft.debtTolerance == tolerance
                        ) {
                            draft.debtTolerance = tolerance
                        }
                    }
                }
            }
        }
    }

    private var actionBar: some View {
        VStack(spacing: 0) {
            Divider()
                .overlay(LumaTheme.cardStroke)

            LumaButton(title: "Continue", systemImage: "arrow.right", action: finishOnboarding)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 12)
        }
        .background(.ultraThinMaterial)
    }

    private func finishOnboarding() {
        focusedField = nil
        draft.nickname = draft.nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        draft.testScore = draft.testScore.trimmingCharacters(in: .whitespacesAndNewlines)
        draft.stateResidency = draft.normalizedStateResidency
        draft.intendedMajor = ""
        profile = draft
        onContinue()
    }

    private func onboardingPill(_ title: String, systemImage: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: systemImage)
                .font(.caption2.weight(.heavy))
                .accessibilityHidden(true)

            Text(title)
                .font(.caption.weight(.heavy))
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .foregroundStyle(.white)
        .padding(.vertical, 7)
        .padding(.horizontal, 9)
        .background(.white.opacity(0.18), in: Capsule())
    }

    private func onboardingSection<Content: View>(
        title: String,
        subtitle: String,
        systemImage: String,
        tint: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.heavy))
                    .foregroundStyle(tint)
                    .frame(width: 28, height: 28)
                    .background(tint.opacity(0.16), in: RoundedRectangle(cornerRadius: 8))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.headline.weight(.heavy))
                        .foregroundStyle(LumaTheme.ink)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(LumaTheme.slate)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            content()
        }
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
        .overlay {
            RoundedRectangle(cornerRadius: LumaTheme.cardRadius)
                .stroke(tint.opacity(0.18))
        }
        .shadow(color: LumaTheme.cardShadow.opacity(0.22), radius: 10, y: 5)
    }

    private func menuPicker<SelectionValue: Hashable, Content: View>(
        _ title: String,
        selection: Binding<SelectionValue>,
        @ViewBuilder content: () -> Content
    ) -> some View {
        Picker(title, selection: selection) {
            content()
        }
        .pickerStyle(.menu)
        .tint(LumaTheme.coral)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(13)
        .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
        .overlay {
            RoundedRectangle(cornerRadius: LumaTheme.cardRadius)
                .stroke(LumaTheme.cardStroke)
        }
        .accessibilityLabel(title)
    }

    private func preferenceGroup<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.heavy))
                .foregroundStyle(LumaTheme.ink)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 118), spacing: 8)], alignment: .leading, spacing: 8) {
                content()
            }
        }
    }

    private func preferenceButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.heavy))
                .foregroundStyle(isSelected ? .white : LumaTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 42)
                .background(isSelected ? AnyShapeStyle(LumaTheme.heroGradient) : AnyShapeStyle(.white), in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(isSelected ? LumaTheme.coral : LumaTheme.ink.opacity(0.22), lineWidth: isSelected ? 2 : 1)
                }
                .shadow(color: isSelected ? LumaTheme.coral.opacity(0.20) : .black.opacity(0.04), radius: isSelected ? 10 : 4, y: isSelected ? 5 : 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}
