import SwiftUI

struct StudentProfileCard: View {
    @EnvironmentObject private var proPurchaseManager: ProPurchaseManager
    @EnvironmentObject private var studentProfileStore: StudentProfileStore
    @State private var isShowingEditor = false
    var onUpgradeTapped: () -> Void

    var body: some View {
        if proPurchaseManager.state.isPro {
            proProfileCard
                .sheet(isPresented: $isShowingEditor) {
                    StudentProfileEditorView(profile: $studentProfileStore.profile)
                }
        } else {
            FeatureLock(
                title: "Personalized student profile",
                message: "Add GPA, residency, intended major, and family income to see tailored fit, cost, and ROI guidance.",
                feature: .studentProfile,
                action: onUpgradeTapped
            )
        }
    }

    private var proProfileCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(LumaTheme.heroGradient)

                    Image(systemName: "person.crop.circle.badge.checkmark")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                }
                .frame(width: 44, height: 44)
                .shadow(color: LumaTheme.aqua.opacity(0.20), radius: 10, y: 5)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Student Profile")
                        .font(.headline.weight(.heavy))
                        .foregroundStyle(LumaTheme.ink)

                    Text(statusText)
                        .font(.caption)
                        .foregroundStyle(LumaTheme.slate)
                        .lineLimit(2)
                }

                Spacer()

                Button(studentProfileStore.profile.isComplete ? "Edit" : "Set Up") {
                    isShowingEditor = true
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
            }

            if studentProfileStore.profile.isComplete {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.caption2.weight(.heavy))

                    Text("Personalized")
                        .font(.caption.weight(.heavy))
                }
                .foregroundStyle(LumaTheme.outcomeTeal)
                .padding(.vertical, 6)
                .padding(.horizontal, 9)
                .background(LumaTheme.aqua.opacity(0.11), in: Capsule())

                profileSummary
            } else {
                Text("Create a profile to personalize Explore cards with fit, estimated net cost, and ROI grade.")
                    .font(.subheadline)
                    .foregroundStyle(LumaTheme.slate)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(profileCardBackground, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
        .overlay {
            RoundedRectangle(cornerRadius: LumaTheme.cardRadius)
                .stroke(LumaTheme.aqua.opacity(0.18))
        }
        .shadow(color: LumaTheme.aqua.opacity(0.08), radius: 16, y: 8)
    }

    private var profileSummary: some View {
        let profile = studentProfileStore.profile

        return HStack(spacing: 8) {
            profileChip(
                "\(profile.gpa.formatted(.number.precision(.fractionLength(1)))) GPA",
                systemImage: "graduationcap.fill",
                tint: LumaTheme.coral
            )
            profileChip(
                profile.normalizedStateResidency,
                systemImage: "map.fill",
                tint: LumaTheme.outcomeTeal
            )
            profileChip(
                profile.intendedMajor,
                systemImage: "book.closed.fill",
                tint: LumaTheme.scorePurple
            )
        }
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

    private var statusText: String {
        let profile = studentProfileStore.profile

        if profile.isComplete {
            return "Recommendations now reflect your profile."
        }

        return "Tailor fit, net cost, and ROI guidance."
    }

    private func profileChip(_ title: String, systemImage: String, tint: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: systemImage)
                .font(.caption2.weight(.heavy))
                .foregroundStyle(tint)

            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(LumaTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(.vertical, 7)
        .padding(.horizontal, 9)
        .background(.white.opacity(0.82), in: Capsule())
        .overlay {
            Capsule()
                .stroke(tint.opacity(0.12))
        }
    }
}

private struct StudentProfileEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var profile: StudentProfile
    @State private var draft: StudentProfile

    init(profile: Binding<StudentProfile>) {
        self._profile = profile
        self._draft = State(initialValue: profile.wrappedValue)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    gpaSection
                    optionalTestSection
                    residencySection
                    majorSection
                    incomeSection
                }
                .padding(.horizontal)
                .padding(.top, 34)
                .padding(.bottom)
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

                VStack(alignment: .leading, spacing: 3) {
                    Text("Build your profile")
                        .font(.title2.weight(.heavy))
                        .foregroundStyle(.white)

                    Text("Make each school card feel like it was written for you.")
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
        }
    }

    private var optionalTestSection: some View {
        formSection(
            title: "SAT/ACT",
            subtitle: "Optional, but useful for sharper fit and scholarship estimates.",
            systemImage: "pencil.and.list.clipboard",
            tint: LumaTheme.scorePurple
        ) {
            TextField("Optional, for example 1320 or 29", text: $draft.testScore)
                .keyboardType(.numbersAndPunctuation)
                .textInputAutocapitalization(.never)
                .padding(13)
                .background(LumaTheme.canvas, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
        }
    }

    private var residencySection: some View {
        formSection(
            title: "State residency",
            subtitle: "Used to estimate in-state versus out-of-state tuition.",
            systemImage: "map.fill",
            tint: LumaTheme.outcomeTeal
        ) {
            TextField("Two-letter state, for example TX", text: $draft.stateResidency)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .onChange(of: draft.stateResidency) { _, newValue in
                    draft.stateResidency = String(newValue.uppercased().prefix(2))
                }
                .padding(13)
                .background(LumaTheme.canvas, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
        }
    }

    private var majorSection: some View {
        formSection(
            title: "Intended major",
            subtitle: "Connects school outcomes and program data to your likely path.",
            systemImage: "book.closed.fill",
            tint: LumaTheme.scoreGold
        ) {
            TextField("For example Computer Science", text: $draft.intendedMajor)
                .textInputAutocapitalization(.words)
                .padding(13)
                .background(LumaTheme.canvas, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
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
        }
    }

    private func insightPill(_ title: String, systemImage: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: systemImage)
                .font(.caption2.weight(.heavy))

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
