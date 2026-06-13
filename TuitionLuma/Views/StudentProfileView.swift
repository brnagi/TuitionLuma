import SwiftUI

struct StudentProfileCard: View {
    @EnvironmentObject private var proPurchaseManager: ProPurchaseManager
    @EnvironmentObject private var studentProfileStore: StudentProfileStore
    @State private var isShowingEditor = false
    var onUpgradeTapped: () -> Void

    @ViewBuilder
    var body: some View {
        if !studentProfileStore.profile.isComplete {
            incompleteProfilePrompt
                .sheet(isPresented: $isShowingEditor) {
                    StudentProfileEditorView(profile: $studentProfileStore.profile)
                }
        }
    }

    private var incompleteProfilePrompt: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(LumaTheme.heroGradient)

                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                }
                .frame(width: 38, height: 38)
                .shadow(color: LumaTheme.aqua.opacity(0.20), radius: 10, y: 5)
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    Text(promptTitle)
                        .font(.headline.weight(.heavy))
                        .foregroundStyle(LumaTheme.ink)

                    Text(promptSubtitle)
                        .font(.caption)
                        .foregroundStyle(LumaTheme.slate)
                        .lineLimit(2)
                }

                Spacer()

                Button(promptCTA) {
                    if proPurchaseManager.state.isPro {
                        isShowingEditor = true
                    } else {
                        onUpgradeTapped()
                    }
                }
                .font(.caption.weight(.heavy))
                .foregroundStyle(LumaTheme.coral)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(.white, in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(LumaTheme.coral.opacity(0.18))
                }
                .buttonStyle(.plain)
                .frame(minHeight: 44)
                .accessibilityHint(proPurchaseManager.state.isPro ? "Opens the student profile form." : "Opens TuitionLuma Pro options.")
            }
        }
        .padding(14)
        .background(profileCardBackground, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
        .overlay {
            RoundedRectangle(cornerRadius: LumaTheme.cardRadius)
                .stroke(LumaTheme.aqua.opacity(0.18))
        }
        .shadow(color: LumaTheme.aqua.opacity(0.08), radius: 16, y: 8)
    }

    private var profileCardBackground: some ShapeStyle {
        LinearGradient(
            colors: [
                .white,
                LumaTheme.aqua.opacity(0.07),
                LumaTheme.sun.opacity(0.05)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var promptTitle: String {
        let nickname = studentProfileStore.profile.displayNickname
        if proPurchaseManager.state.isPro, !nickname.isEmpty {
            return "Hi \(nickname) 👋"
        }

        return proPurchaseManager.state.isPro ? "Complete your profile" : "Get personalized recommendations"
    }

    private var promptSubtitle: String {
        if proPurchaseManager.state.isPro {
            return "Add GPA, major, residency, and income to receive personalized recommendations."
        }

        return "See affordability, major-specific outcomes, and schools that fit your goals."
    }

    private var promptCTA: String {
        proPurchaseManager.state.isPro ? "Complete Profile" : "Get Pro"
    }
}

private struct StudentProfileEditorView: View {
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
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        draft.stateResidency = draft.normalizedStateResidency
                        profile = draft
                        dismiss()
                    }
                    .fontWeight(.bold)
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
        .shadow(color: LumaTheme.coral.opacity(0.13), radius: 16, y: 8)
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
                    focusedField = .stateResidency
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
            TextField(
                text: $draft.stateResidency,
                prompt: Text("Two-letter state, for example TX")
                    .foregroundStyle(LumaTheme.slate)
            ) {
                Text("State residency")
            }
                .focused($focusedField, equals: .stateResidency)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .submitLabel(.next)
                .onChange(of: draft.stateResidency) { _, newValue in
                    draft.stateResidency = String(newValue.uppercased().prefix(2))
                }
                .onSubmit {
                    focusedField = .intendedMajor
                }
                .lumaTextField(isFocused: focusedField == .stateResidency)
                .accessibilityLabel("State residency")
                .accessibilityHint("Enter a two-letter state abbreviation.")
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
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(13)
            .background(LumaTheme.canvas, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
            .accessibilityLabel("Family income range")
            .accessibilityValue(draft.familyIncomeRange.rawValue)
        }
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
                    .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 8))
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
                .stroke(tint.opacity(0.08))
        }
    }
}
