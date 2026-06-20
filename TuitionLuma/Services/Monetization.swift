import Foundation
import StoreKit
import SwiftUI

enum ProAccessTier: String, Codable {
    case free
    case pro
}

struct ProAccessState: Equatable, Codable {
    var tier: ProAccessTier
    var purchasedAt: Date?

    var isPro: Bool {
        tier == .pro
    }

    static let free = ProAccessState(tier: .free, purchasedAt: nil)
}

enum ProFeature: String, CaseIterable, Identifiable {
    case unlimitedSavedSchools = "Unlimited saved schools"
    case schoolCompare = "Compare schools"
    case aidBorrowing = "Aid and borrowing tools"
    case repaymentCalculator = "Repayment calculator"
    case scholarshipPlanning = "Scholarship and grant planning"
    case pdfExport = "Family Report"
    case planningMode = "Parent/student planning mode"
    case scenarioModeling = "Scenario modeling"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .unlimitedSavedSchools: "bookmark.fill"
        case .schoolCompare: "rectangle.split.3x1.fill"
        case .aidBorrowing: "dollarsign.circle.fill"
        case .repaymentCalculator: "creditcard.fill"
        case .scholarshipPlanning: "sparkles"
        case .pdfExport: "square.and.arrow.up.fill"
        case .planningMode: "person.2.fill"
        case .scenarioModeling: "slider.horizontal.3"
        }
    }
}

enum ProAccessPolicy {
    static func savedSchoolLimit(for state: ProAccessState) -> Int? {
        state.isPro ? nil : 3
    }

    static func compareSchoolLimit(for state: ProAccessState) -> Int {
        3
    }

    static func canUse(_ feature: ProFeature, state: ProAccessState) -> Bool {
        state.isPro
    }
}

@MainActor
final class ProPurchaseManager: ObservableObject {
    private enum StoreKitConfig {
        static let proLifetimeProductID = "tuitionluma.pro.lifetime"
        static let entitlementCacheKey = "tuitionLuma.proEntitlementCache"
    }

    @Published private(set) var state: ProAccessState
    @Published private(set) var isLoading = false
    @Published private(set) var proProduct: Product?
    @Published var errorMessage: String?
    @Published var restoreMessage: String?

    private var transactionUpdatesTask: Task<Void, Never>?

    init(state: ProAccessState? = nil) {
        self.state = state ?? Self.cachedState()

        transactionUpdatesTask = Task { [weak self] in
            for await result in StoreKit.Transaction.updates {
                await self?.handleTransactionUpdate(result)
            }
        }

        Task {
            await refreshEntitlements()
            await loadProducts()
        }
    }

    deinit {
        transactionUpdatesTask?.cancel()
    }

    var displayPrice: String {
        proProduct?.displayPrice ?? "$4.99"
    }

    func loadProducts() async {
        do {
            let products = try await Product.products(for: [StoreKitConfig.proLifetimeProductID])
            proProduct = products.first { $0.id == StoreKitConfig.proLifetimeProductID }

            if proProduct == nil {
                errorMessage = "TuitionLuma Pro is not available right now."
            }
        } catch {
            errorMessage = "Unable to load TuitionLuma Pro. Please try again."
        }
    }

    func purchasePro() async {
        isLoading = true
        errorMessage = nil
        restoreMessage = nil
        defer { isLoading = false }

        do {
            if proProduct == nil {
                await loadProducts()
            }

            guard let proProduct else {
                errorMessage = "TuitionLuma Pro is not available right now."
                return
            }

            let purchaseResult = try await proProduct.purchase()

            switch purchaseResult {
            case .success(let verificationResult):
                let transaction = try verified(verificationResult)
                guard transaction.productID == StoreKitConfig.proLifetimeProductID else {
                    errorMessage = "This purchase could not be matched to TuitionLuma Pro."
                    return
                }

                applyVerifiedProEntitlement(purchasedAt: transaction.purchaseDate)
                await transaction.finish()

            case .userCancelled:
                break

            case .pending:
                errorMessage = "Purchase pending. TuitionLuma Pro will unlock after approval."

            @unknown default:
                errorMessage = "Purchase could not be completed. Please try again."
            }
        } catch {
            errorMessage = "Purchase could not be verified. Please try again."
        }
    }

    func restorePurchases() async {
        isLoading = true
        errorMessage = nil
        restoreMessage = nil
        defer { isLoading = false }

        do {
            try await AppStore.sync()
            await refreshEntitlements()

            if !state.isPro {
                errorMessage = "No TuitionLuma Pro purchase was found for this Apple ID."
            } else {
                errorMessage = nil
                restoreMessage = "TuitionLuma Pro is active."
            }
        } catch {
            await refreshEntitlements()
            if state.isPro {
                errorMessage = nil
                restoreMessage = "TuitionLuma Pro is already active."
            } else {
                errorMessage = "Unable to restore purchases. Please try again."
            }
        }
    }

    private func refreshEntitlements() async {
        isLoading = true
        defer { isLoading = false }

        var verifiedState = ProAccessState.free

        for await result in StoreKit.Transaction.currentEntitlements {
            guard let transaction = try? verified(result),
                  transaction.productID == StoreKitConfig.proLifetimeProductID,
                  transaction.revocationDate == nil else {
                continue
            }

            verifiedState = ProAccessState(
                tier: .pro,
                purchasedAt: transaction.purchaseDate
            )
            break
        }

        state = verifiedState
        persistState()

        if state.isPro {
            errorMessage = nil
        }
    }

    private func handleTransactionUpdate(_ result: VerificationResult<StoreKit.Transaction>) async {
        do {
            let transaction = try verified(result)

            if transaction.productID == StoreKitConfig.proLifetimeProductID {
                if transaction.revocationDate == nil {
                    applyVerifiedProEntitlement(purchasedAt: transaction.purchaseDate)
                } else {
                    state = .free
                    persistState()
                }
            }

            await transaction.finish()
        } catch {
            errorMessage = "A StoreKit transaction could not be verified."
        }
    }

    private func applyVerifiedProEntitlement(purchasedAt: Date) {
        state = ProAccessState(tier: .pro, purchasedAt: purchasedAt)
        errorMessage = nil
        restoreMessage = "TuitionLuma Pro is active."
        persistState()
    }

    private func verified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let signedType):
            return signedType
        case .unverified:
            throw StoreKitVerificationError.failedVerification
        }
    }

    private func persistState() {
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: StoreKitConfig.entitlementCacheKey)
        }
    }

    private static func cachedState() -> ProAccessState {
        guard let data = UserDefaults.standard.data(forKey: StoreKitConfig.entitlementCacheKey),
              let state = try? JSONDecoder().decode(ProAccessState.self, from: data) else {
            return .free
        }

        return state
    }
}

private enum StoreKitVerificationError: Error {
    case failedVerification
}

struct ProBadge: View {
    var compact = false

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "sparkles")
                .font(compact ? .caption2 : .caption.weight(.bold))

            Text("Pro")
                .font(compact ? .caption2.weight(.heavy) : .caption.weight(.heavy))
        }
        .foregroundStyle(.white)
        .padding(.vertical, compact ? 4 : 6)
        .padding(.horizontal, compact ? 7 : 9)
        .background(LumaTheme.heroGradient, in: Capsule())
        .accessibilityLabel("Pro feature")
    }
}

struct FeatureLock: View {
    var title: String
    var message: String
    var feature: ProFeature
    var action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "lock.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(LumaTheme.coral, in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title)
                            .font(.headline)
                            .foregroundStyle(LumaTheme.ink)

                        ProBadge(compact: true)
                    }

                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(LumaTheme.slate)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Button(action: action) {
                Label("Unlock \(feature.rawValue)", systemImage: "arrow.up.forward")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(LumaTheme.coral)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
        .overlay {
            RoundedRectangle(cornerRadius: LumaTheme.cardRadius)
                .stroke(LumaTheme.coral.opacity(0.16))
        }
    }
}

struct UpgradePrompt: View {
    var title: String
    var message: String
    var action: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            ProBadge()

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.heavy))
                    .foregroundStyle(LumaTheme.ink)

                Text(message)
                    .font(.caption)
                    .foregroundStyle(LumaTheme.slate)
                    .lineLimit(2)
            }

            Spacer()

            Button("Upgrade", action: action)
                .font(.caption.weight(.heavy))
                .foregroundStyle(.white)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(LumaTheme.coral, in: Capsule())
                .buttonStyle(.plain)
        }
        .padding(14)
        .background(LumaTheme.sun.opacity(0.14), in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
    }
}

struct PaywallView: View {
    @EnvironmentObject private var proPurchaseManager: ProPurchaseManager
    @Environment(\.dismiss) private var dismiss

    private let featureHighlights: [(title: String, message: String, systemImage: String, color: Color)] = [
        (
            "Aid + scholarships",
            "Plan grants, scholarships, family help, work-study, and borrowing.",
            "dollarsign.circle.fill",
            LumaTheme.mint
        ),
        (
            "Repayment calculator",
            "Choose loan terms, forecast payments, and save plans.",
            "creditcard.fill",
            LumaTheme.coral
        ),
        (
            "Scenario modeling",
            "Try campus, residency, path, and planning choices.",
            "slider.horizontal.3",
            LumaTheme.scoreGold
        ),
        (
            "Planning mode",
            "Switch between student and parent decision views.",
            "person.2.fill",
            LumaTheme.aqua
        ),
        (
            "Family report",
            "Share a polished Family Report with cost, debt, and outcomes.",
            "doc.richtext.fill",
            LumaTheme.outcomeTeal
        ),
        (
            "Unlimited saves",
            "Build a fuller shortlist without the free save limit.",
            "bookmark.fill",
            LumaTheme.valueGreen
        )
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    hero
                    pricingCard
                    decisionPreview
                    proFeatureGrid
                    restoreButton
                }
                .padding()
            }
            .background(LumaTheme.canvas)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var hero: some View {
        ZStack(alignment: .topTrailing) {
            LumaTheme.heroGradient

            Circle()
                .fill(.white.opacity(0.16))
                .frame(width: 180, height: 180)
                .offset(x: 70, y: -82)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    ProBadge()

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(proPurchaseManager.displayPrice)
                            .font(.title2.weight(.heavy))
                            .foregroundStyle(.white)

                        Text("one-time")
                            .font(.caption.weight(.heavy))
                            .foregroundStyle(.white.opacity(0.84))
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(.white.opacity(0.18), in: RoundedRectangle(cornerRadius: 14))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Make the college decision with confidence.")
                        .font(.system(size: 34, weight: .heavy))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Unlock aid planning, repayment forecasts, scenarios, saved plans, family reports, and unlimited school saves.")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.90))
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(spacing: 10) {
                    heroMetric("Aid", "Plan")
                    heroMetric("Debt", "Forecast")
                    heroMetric("ROI", "Explain")
                }
            }
            .padding(22)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .clipShape(RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
        .overlay(alignment: .bottomTrailing) {
            Image(systemName: "graduationcap.fill")
                .font(.system(size: 76, weight: .heavy))
                .foregroundStyle(.white.opacity(0.12))
                .padding(20)
                .accessibilityHidden(true)
        }
    }

    private func heroMetric(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption2.weight(.bold))
                .textCase(.uppercase)
                .foregroundStyle(.white.opacity(0.70))

            Text(value)
                .font(.caption.weight(.heavy))
                .foregroundStyle(.white)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.white.opacity(0.16), in: RoundedRectangle(cornerRadius: 14))
    }

    private var decisionPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pro helps answer")
                .font(.headline.weight(.heavy))
                .foregroundStyle(LumaTheme.ink)

            VStack(spacing: 10) {
                previewRow("Can we afford this school?", detail: "See aid, scholarships, cash gap, and likely borrowing.")
                previewRow("What will debt feel like?", detail: "Forecast repayment terms and monthly payments before you commit.")
                previewRow("How do we explain the choice?", detail: "Save repayment plans and share a clear Family Report.")
            }
        }
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
        .overlay {
            RoundedRectangle(cornerRadius: LumaTheme.cardRadius)
                .stroke(LumaTheme.aqua.opacity(0.16))
        }
        .shadow(color: LumaTheme.aqua.opacity(0.06), radius: 14, y: 7)
    }

    private func previewRow(_ title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.subheadline.weight(.heavy))
                .foregroundStyle(LumaTheme.mint)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.heavy))
                    .foregroundStyle(LumaTheme.ink)

                Text(detail)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(LumaTheme.slate)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var proFeatureGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            ForEach(featureHighlights, id: \.title) { feature in
                VStack(alignment: .leading, spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(feature.color.opacity(0.16))

                        Image(systemName: feature.systemImage)
                            .font(.headline.weight(.heavy))
                            .foregroundStyle(feature.color)
                            .accessibilityHidden(true)
                    }
                    .frame(width: 38, height: 38)

                    Text(feature.title)
                        .font(.subheadline.weight(.heavy))
                        .foregroundStyle(LumaTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(feature.message)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(LumaTheme.slate)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, minHeight: 148, alignment: .topLeading)
                .padding(12)
                .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
                .overlay {
                    RoundedRectangle(cornerRadius: LumaTheme.cardRadius)
                        .stroke(feature.color.opacity(0.12))
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(feature.title). \(feature.message)")
            }
        }
    }

    private var pricingCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(proPurchaseManager.displayPrice)
                        .font(.system(size: 42, weight: .heavy))
                        .foregroundStyle(LumaTheme.ink)

                    Text("one-time purchase")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(LumaTheme.slate)
                }

                Spacer()

                Image(systemName: "lock.open.fill")
                    .font(.title2.weight(.heavy))
                    .foregroundStyle(.white)
                    .frame(width: 50, height: 50)
                    .background(LumaTheme.heroGradient, in: RoundedRectangle(cornerRadius: 16))
                    .accessibilityHidden(true)
            }

            Text("Buy once and keep TuitionLuma Pro. No subscriptions, renewals, or surprise bills.")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(LumaTheme.slate)
                .fixedSize(horizontal: false, vertical: true)

            if let errorMessage = proPurchaseManager.errorMessage {
                Text(errorMessage)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(LumaTheme.coral)
            }

            if let restoreMessage = proPurchaseManager.restoreMessage {
                Text(restoreMessage)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(LumaTheme.mint)
            }

            LumaButton(
                title: proPurchaseManager.state.isPro ? "Pro Unlocked" : "Unlock Pro for $4.99",
                systemImage: proPurchaseManager.state.isPro ? "checkmark" : "sparkles"
            ) {
                Task {
                    await proPurchaseManager.purchasePro()
                    dismiss()
                }
            }
            .disabled(proPurchaseManager.isLoading || proPurchaseManager.state.isPro)
            .accessibilityHint(proPurchaseManager.state.isPro ? "TuitionLuma Pro is already active." : "Starts the one-time TuitionLuma Pro purchase.")
        }
        .padding(18)
        .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
        .overlay {
            RoundedRectangle(cornerRadius: LumaTheme.cardRadius)
                .stroke(LumaTheme.coral.opacity(0.14))
        }
        .shadow(color: LumaTheme.coral.opacity(0.08), radius: 16, y: 8)
        .accessibilityElement(children: .contain)
    }

    private var restoreButton: some View {
        Button {
            Task {
                await proPurchaseManager.restorePurchases()
            }
        } label: {
            Text(proPurchaseManager.isLoading ? "Checking..." : (proPurchaseManager.state.isPro ? "Refresh Pro Access" : "Restore Purchase"))
                .font(.subheadline.weight(.bold))
                .foregroundStyle(LumaTheme.slate)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
                .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .disabled(proPurchaseManager.isLoading)
        .accessibilityHint("Checks the App Store for an existing TuitionLuma Pro purchase.")
    }
}
