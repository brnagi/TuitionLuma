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
    case fiveSchoolCompare = "Compare up to 3 schools"
    case advancedDebtCalculator = "Advanced debt repayment calculator"
    case scholarshipPlanning = "Scholarship and grant planning"
    case roiScore = "ROI score by school"
    case monthlyLoanPayments = "Monthly loan payment projections"
    case pdfExport = "Export/share cost report as PDF"
    case affordabilityScore = "Personalized affordability score"
    case studentProfile = "Personalized student profile"
    case planningMode = "Parent/student planning mode"
    case scenarioModeling = "Scenario modeling"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .unlimitedSavedSchools: "bookmark.fill"
        case .fiveSchoolCompare: "rectangle.split.3x1.fill"
        case .advancedDebtCalculator: "creditcard.fill"
        case .scholarshipPlanning: "sparkles"
        case .roiScore: "chart.line.uptrend.xyaxis"
        case .monthlyLoanPayments: "calendar.badge.clock"
        case .pdfExport: "square.and.arrow.up.fill"
        case .affordabilityScore: "gauge.with.dots.needle.67percent"
        case .studentProfile: "person.text.rectangle.fill"
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

    init(state: ProAccessState = .free) {
        if let data = UserDefaults.standard.data(forKey: StoreKitConfig.entitlementCacheKey),
           let savedState = try? JSONDecoder().decode(ProAccessState.self, from: data) {
            self.state = savedState
        } else {
            self.state = state
        }

        transactionUpdatesTask = Task { [weak self] in
            for await result in StoreKit.Transaction.updates {
                await self?.handleTransactionUpdate(result)
            }
        }

        Task {
            await loadProducts()
            await refreshEntitlements()
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

    func resetToFreeForTesting() {
        state = .free
        UserDefaults.standard.removeObject(forKey: StoreKitConfig.entitlementCacheKey)
    }

    private func refreshEntitlements() async {
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

    private let benefits = [
        "Compare more schools",
        "Forecast student loan payments",
        "Estimate your real net cost",
        "Personalize fit and ROI recommendations",
        "Model scholarships and grants",
        "Share reports with family"
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    hero
                    benefitsList
                    proFeatureGrid
                    pricingCard
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
        VStack(alignment: .leading, spacing: 14) {
            ProBadge()

            Text("Unlock TuitionLuma Pro")
                .font(.system(size: 36, weight: .heavy))
                .foregroundStyle(.white)
                .lineLimit(3)
                .minimumScaleFactor(0.72)

            Text("Plan college costs with more confidence.")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white.opacity(0.9))

            Text("For students and parents who want a fuller picture before making a major college decision.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.86))
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LumaTheme.heroGradient, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
    }

    private var benefitsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Included with Pro")
                .font(.title3.weight(.heavy))
                .foregroundStyle(LumaTheme.ink)

            ForEach(benefits, id: \.self) { benefit in
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(LumaTheme.mint)
                        .accessibilityHidden(true)

                    Text(benefit)
                        .font(.headline)
                        .foregroundStyle(LumaTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
                .accessibilityElement(children: .combine)
            }
        }
    }

    private var proFeatureGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            ForEach(ProFeature.allCases) { feature in
                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: feature.systemImage)
                        .foregroundStyle(LumaTheme.coral)
                        .accessibilityHidden(true)

                    Text(feature.rawValue)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(LumaTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, minHeight: 84, alignment: .topLeading)
                .padding(12)
                .background(.white, in: RoundedRectangle(cornerRadius: LumaTheme.cardRadius))
                .accessibilityElement(children: .combine)
                .accessibilityLabel(feature.rawValue)
            }
        }
    }

    private var pricingCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text(proPurchaseManager.displayPrice)
                    .font(.system(size: 42, weight: .heavy))
                    .foregroundStyle(LumaTheme.ink)

                Text("one-time")
                    .font(.headline)
                    .foregroundStyle(LumaTheme.slate)
            }

            Text("Buy once and keep TuitionLuma Pro. No subscription, renewals, or surprise bills.")
                .font(.footnote)
                .foregroundStyle(LumaTheme.slate)

            Text("One-time Pro access for students and families who want deeper planning tools.")
                .font(.caption)
                .foregroundStyle(LumaTheme.slate.opacity(0.78))

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
