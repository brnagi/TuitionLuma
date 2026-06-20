import SwiftUI

struct StudentProfileCard: View {
    @EnvironmentObject private var proPurchaseManager: ProPurchaseManager
    @EnvironmentObject private var studentProfileStore: StudentProfileStore
    @State private var isShowingEditor = false

    @ViewBuilder
    var body: some View {
        if studentProfileStore.profile.isComplete {
            completeProfileSummary
                .sheet(isPresented: $isShowingEditor) {
                    StudentProfileEditorView(profile: $studentProfileStore.profile)
                }
        } else {
            incompleteProfilePrompt
                .sheet(isPresented: $isShowingEditor) {
                    StudentProfileEditorView(profile: $studentProfileStore.profile)
                }
        }
    }

    private var incompleteProfilePrompt: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(promptTitle)
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(LumaTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)

                Text(promptSubtitle)
                    .font(.caption)
                    .foregroundStyle(LumaTheme.slate)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(promptCTA) {
                isShowingEditor = true
            }
            .font(.headline.weight(.heavy))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(LumaTheme.outcomeTeal, in: Capsule())
            .shadow(color: LumaTheme.outcomeTeal.opacity(0.18), radius: 12, y: 6)
            .buttonStyle(.plain)
            .accessibilityHint("Opens the student profile form.")
        }
        .padding(16)
        .background(profileCardBackground, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
        .overlay {
            RoundedRectangle(cornerRadius: LumaTheme.cardRadius)
                .stroke(LumaTheme.cardStroke.opacity(0.42))
        }
        .shadow(color: LumaTheme.cardShadow.opacity(0.24), radius: 16, y: 8)
    }

    private var completeProfileSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(profileGreeting)
                        .font(.title3.weight(.heavy))
                        .foregroundStyle(LumaTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("\(studentProfileStore.profile.intendedMajor) • \(studentProfileStore.profile.stateResidencyDisplayName)")
                        .font(.subheadline.weight(.heavy))
                        .foregroundStyle(LumaTheme.ink.opacity(0.84))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                Button("Edit Profile") {
                    isShowingEditor = true
                }
                .font(.subheadline.weight(.heavy))
                .foregroundStyle(.white)
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
                .background(LumaTheme.coral, in: Capsule())
                .shadow(color: LumaTheme.coral.opacity(0.18), radius: 10, y: 5)
                .buttonStyle(.plain)
                .frame(minHeight: 44)
                .accessibilityHint("Opens the student profile form.")
            }

            Divider()
                .overlay(LumaTheme.cardStroke.opacity(0.80))

            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("Income:")
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(LumaTheme.slate)

                    Text(studentProfileStore.profile.familyIncomeRange.rawValue)
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(LumaTheme.ink)
                        .lineLimit(1)
                }

                Text("Recommendations are personalized.")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(LumaTheme.slate)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(LumaTheme.canvas.opacity(0.82), in: RoundedRectangle(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(LumaTheme.cardStroke.opacity(0.72))
            }
        }
        .padding(14)
        .background(.white.opacity(0.94), in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
        .overlay {
            RoundedRectangle(cornerRadius: LumaTheme.cardRadius)
                .stroke(LumaTheme.cardStroke.opacity(0.42))
        }
        .shadow(color: LumaTheme.cardShadow.opacity(0.22), radius: 14, y: 7)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(profileGreeting). \(studentProfileStore.profile.intendedMajor). \(studentProfileStore.profile.stateResidencyDisplayName) resident. Income \(studentProfileStore.profile.familyIncomeRange.rawValue). Debt tolerance \(studentProfileStore.profile.debtTolerance.rawValue). School type preference \(studentProfileStore.profile.ownershipPreference.rawValue). Distance preference \(studentProfileStore.profile.distanceFromHomePreference.rawValue). Campus size \(studentProfileStore.profile.campusSizePreference.rawValue). Learning format \(studentProfileStore.profile.learningFormatPreference.rawValue). Recommendations are personalized using your profile.")
    }

    private var profileGreeting: String {
        let nickname = studentProfileStore.profile.displayNickname
        guard !nickname.isEmpty else {
            return "Your profile"
        }

        return "Hi \(nickname) 👋"
    }

    private var profileCardBackground: some ShapeStyle {
        LinearGradient(
            colors: [
                .white,
                .white.opacity(0.96)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var promptTitle: String {
        let nickname = studentProfileStore.profile.displayNickname
        if !nickname.isEmpty {
            return "Complete your profile"
        }

        return "Complete your profile"
    }

    private var promptSubtitle: String {
        "Improve recommendations with your major, residency, income, and preferences."
    }

    private var promptCTA: String {
        "Complete Profile"
    }
}

struct StudentProfileEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var profile: StudentProfile
    @State private var draft: StudentProfile
    @FocusState private var focusedField: ProfileField?

    private enum ProfileField: Hashable {
        case nickname
        case testScore
        case stateResidency
        case intendedMajor
    }

    init(profile: Binding<StudentProfile>) {
        self._profile = profile
        self._draft = State(initialValue: profile.wrappedValue)
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        header
                        nicknameSection
                            .id(ProfileField.nickname)
                        gpaSection
                        optionalTestSection
                            .id(ProfileField.testScore)
                        residencySection
                            .id(ProfileField.stateResidency)
                        majorSection
                            .id(ProfileField.intendedMajor)
                        incomeSection
                        preferenceSection
                    }
                    .padding(.horizontal)
                    .padding(.top, 34)
                    .padding(.bottom, 120)
                }
                .scrollDismissesKeyboard(.interactively)
                .onTapGesture {
                    focusedField = nil
                }
                .onChange(of: focusedField) { _, field in
                    guard let field else { return }
                    withAnimation(.easeInOut(duration: 0.2)) {
                        proxy.scrollTo(field, anchor: .center)
                    }
                }
            }
            .background(LumaTheme.canvas)
            .navigationTitle("Student Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.subheadline.weight(.heavy))
                    .foregroundStyle(LumaTheme.ink)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        draft.stateResidency = draft.normalizedStateResidency
                        profile = draft
                        dismiss()
                    }
                    .font(.subheadline.weight(.heavy))
                    .foregroundStyle(LumaTheme.coral)
                }

                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()

                    Button("Done") {
                        focusedField = nil
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "sparkles.rectangle.stack.fill")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.white.opacity(0.22), in: RoundedRectangle(cornerRadius: 8))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Build your profile")
                        .font(.title2.weight(.heavy))
                        .foregroundStyle(.white)

                    Text(greetingSubtitle)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.88))
                }
            }

            HStack(spacing: 8) {
                insightPill("Fit", systemImage: "checkmark.seal.fill")
                insightPill("Net cost", systemImage: "dollarsign.circle.fill")
                insightPill("ROI", systemImage: "chart.line.uptrend.xyaxis")
            }

            Text("Your answers stay on this device and help tailor estimated net cost, affordability, and ROI signals.")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.88))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LumaTheme.heroGradient, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
        .shadow(color: LumaTheme.coral.opacity(0.18), radius: 18, y: 9)
    }

    private var greetingSubtitle: String {
        let nickname = draft.displayNickname
        guard !nickname.isEmpty else {
            return "Make each school card feel like it was written for you."
        }

        return "Hi \(nickname) 👋 Let's make each school card feel like it was written for you."
    }

    private var nicknameSection: some View {
        formSection(
            title: "Nickname",
            subtitle: "Optional. Used for friendlier recommendations and profile prompts.",
            systemImage: "person.crop.circle.fill",
            tint: LumaTheme.aqua
        ) {
            TextField(
                text: $draft.nickname,
                prompt: Text("Alex, Sam, or Taylor")
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
            .accessibilityLabel("Optional nickname")
        }
    }

    private var gpaSection: some View {
        formSection(
            title: "GPA",
            subtitle: "Helps estimate academic fit and potential merit-aid upside.",
            systemImage: "graduationcap.fill",
            tint: LumaTheme.coral
        ) {
            HStack {
                Text("Current GPA")
                    .foregroundStyle(LumaTheme.ink)

                Spacer()

                Text(draft.gpa.formatted(.number.precision(.fractionLength(1))))
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(LumaTheme.coral)
            }

            Slider(value: $draft.gpa, in: 0...4, step: 0.1)
                .tint(LumaTheme.coral)
                .accessibilityLabel("Current GPA")
                .accessibilityValue(draft.gpa.formatted(.number.precision(.fractionLength(1))))
        }
    }

    private var optionalTestSection: some View {
        formSection(
            title: "SAT/ACT",
            subtitle: "Optional, but useful for sharper fit and scholarship estimates.",
            systemImage: "pencil.and.list.clipboard",
            tint: LumaTheme.scorePurple
        ) {
            TextField(
                text: $draft.testScore,
                prompt: Text("Optional, for example 1320 or 29")
                    .foregroundStyle(LumaTheme.slate)
            ) {
                Text("SAT or ACT score")
            }
                .focused($focusedField, equals: .testScore)
                .keyboardType(.numbersAndPunctuation)
                .textInputAutocapitalization(.never)
                .submitLabel(.next)
                .onSubmit {
                    focusedField = .intendedMajor
                }
                .lumaTextField(isFocused: focusedField == .testScore)
                .accessibilityLabel("SAT or ACT score")
                .accessibilityHint("Optional.")
        }
    }

    private var residencySection: some View {
        formSection(
            title: "State residency",
            subtitle: "Used to estimate in-state versus out-of-state tuition.",
            systemImage: "map.fill",
            tint: LumaTheme.outcomeTeal
        ) {
            Picker("State residency", selection: $draft.stateResidency) {
                Text("Select a state").tag("")

                ForEach(USState.all) { state in
                    Text(state.name).tag(state.abbreviation)
                }
            }
            .pickerStyle(.menu)
            .tint(LumaTheme.coral)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(13)
            .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
            .overlay {
                RoundedRectangle(cornerRadius: LumaTheme.cardRadius)
                    .stroke(draft.stateResidency.isEmpty ? LumaTheme.warningOrange.opacity(0.55) : LumaTheme.cardStroke)
            }
            .onAppear {
                draft.stateResidency = draft.normalizedStateResidency
            }
            .accessibilityLabel("State residency")
            .accessibilityValue(draft.stateResidency.isEmpty ? "No state selected" : draft.stateResidencyDisplayName)
            .accessibilityHint("Choose your state of residency.")
        }
    }

    private var majorSection: some View {
        formSection(
            title: "Intended major",
            subtitle: "Connects school outcomes and program data to your likely path.",
            systemImage: "book.closed.fill",
            tint: LumaTheme.scoreGold
        ) {
            TextField(
                text: $draft.intendedMajor,
                prompt: Text("For example Computer Science")
                    .foregroundStyle(LumaTheme.slate)
            ) {
                Text("Intended major")
            }
                .focused($focusedField, equals: .intendedMajor)
                .textInputAutocapitalization(.words)
                .submitLabel(.done)
                .onSubmit {
                    focusedField = nil
                }
                .lumaTextField(isFocused: focusedField == .intendedMajor)
                .accessibilityLabel("Intended major")
        }
    }

    private var incomeSection: some View {
        formSection(
            title: "Family income range",
            subtitle: "Improves aid assumptions and personalized net-cost estimates.",
            systemImage: "house.fill",
            tint: LumaTheme.mint
        ) {
            Picker("Family income range", selection: $draft.familyIncomeRange) {
                ForEach(FamilyIncomeRange.allCases) { range in
                    Text(range.rawValue).tag(range)
                }
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
            .accessibilityLabel("Family income range")
            .accessibilityValue(draft.familyIncomeRange.rawValue)
        }
    }

    private var preferenceSection: some View {
        formSection(
            title: "Decision preferences",
            subtitle: "Fine-tunes rankings for debt comfort and public/private fit.",
            systemImage: "slider.horizontal.3",
            tint: LumaTheme.coral
        ) {
                VStack(alignment: .leading, spacing: 14) {
                preferenceGroup(title: "Debt tolerance", summary: draft.debtTolerance.summary) {
                    ForEach(DebtTolerance.allCases) { tolerance in
                        preferenceButton(
                            title: tolerance.rawValue,
                            isSelected: draft.debtTolerance == tolerance
                        ) {
                            draft.debtTolerance = tolerance
                        }
                    }
                }

                preferenceGroup(title: "Public/private", summary: draft.ownershipPreference.summary) {
                    ForEach(SchoolOwnershipPreference.allCases) { preference in
                        preferenceButton(
                            title: preference.rawValue,
                            isSelected: draft.ownershipPreference == preference
                        ) {
                            draft.ownershipPreference = preference
                        }
                    }
                }

                preferenceGroup(title: "Distance from home") {
                    ForEach(DistanceFromHomePreference.allCases) { preference in
                        preferenceButton(
                            title: preference.rawValue,
                            isSelected: draft.distanceFromHomePreference == preference
                        ) {
                            draft.distanceFromHomePreference = preference
                        }
                    }
                }

                preferenceGroup(title: "Campus size") {
                    ForEach(CampusSizePreference.allCases) { preference in
                        preferenceButton(
                            title: preference.rawValue,
                            isSelected: draft.campusSizePreference == preference
                        ) {
                            draft.campusSizePreference = preference
                        }
                    }
                }

                preferenceGroup(title: "Learning format") {
                    ForEach(LearningFormatPreference.allCases) { preference in
                        preferenceButton(
                            title: preference.rawValue,
                            isSelected: draft.learningFormatPreference == preference
                        ) {
                            draft.learningFormatPreference = preference
                        }
                    }
                }
            }
        }
    }

    private func preferenceGroup<Content: View>(
        title: String,
        summary: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.heavy))
                .foregroundStyle(LumaTheme.ink)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 118), spacing: 8)], alignment: .leading, spacing: 8) {
                content()
            }

            if let summary {
                Text(summary)
                    .font(.caption)
                    .foregroundStyle(LumaTheme.slate)
                    .fixedSize(horizontal: false, vertical: true)
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

    private func insightPill(_ title: String, systemImage: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: systemImage)
                .font(.caption2.weight(.heavy))
                .accessibilityHidden(true)

            Text(title)
                .font(.caption.weight(.heavy))
        }
        .foregroundStyle(.white)
        .padding(.vertical, 7)
        .padding(.horizontal, 9)
        .background(.white.opacity(0.18), in: Capsule())
    }

    private func formSection<Content: View>(
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
                        .font(.headline)
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
        .shadow(color: LumaTheme.cardShadow.opacity(0.24), radius: 10, y: 5)
    }
}
