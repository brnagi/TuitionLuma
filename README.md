# TuitionLuma

TuitionLuma is a SwiftUI MVP that helps students and families compare the true cost of college, including tuition, fees, housing, aid, debt, and expected outcomes.

## What is included

- Swift + SwiftUI iOS app
- MVVM-style view models
- Local mock data for 10 realistic colleges
- Explore, Compare, Calculator, and Saved tabs
- Onboarding, search, detail, calculator, compare, and saved screens
- Reusable components: `SchoolCard`, `CostBreakdownCard`, `StatPill`, `ComparisonRow`, and `LumaButton`
- Calculator logic for annual cost, total degree cost, net cost after aid, monthly loan payment, and 10-year repayment
- Freemium model with mock TuitionLuma Pro subscription state
- Paywall, Pro badge, feature lock, and upgrade prompt components
- Empty, loading, and error states
- TODO placeholder for future College Scorecard API integration
- TODO placeholder for future StoreKit 2 subscription integration

## Free vs Pro

Free users can:

- Search colleges
- View basic school cost data
- Save up to 3 schools
- Compare up to 2 schools
- Use the basic cost calculator
- Estimate total degree cost

TuitionLuma Pro unlocks:

- Unlimited saved schools
- Compare up to 5 schools
- Advanced debt repayment calculator
- Scholarship and grant planning
- ROI score by school
- Monthly loan payment projections
- Export/share cost report as PDF
- Personalized affordability score
- Parent/student planning mode
- Scenario modeling for on-campus, off-campus, in-state, out-of-state, 2-year, and 4-year paths

MVP pricing copy is `$4.99 / month`.

## Requirements

- Xcode 15 or newer
- iOS 17 or newer simulator/device

## Run the app

1. Open `TuitionLuma.xcodeproj` in Xcode.
2. Select the `TuitionLuma` scheme.
3. Choose an iPhone simulator.
4. Press Run.

## Command-line build check

From this folder:

```sh
xcodebuild -project TuitionLuma.xcodeproj -scheme TuitionLuma -destination 'generic/platform=iOS Simulator' build
```

## Future College Scorecard integration

`Services/CollegeScorecardService.swift` contains the integration boundary. The intended path is:

1. Add an API key and endpoint configuration.
2. Fetch College Scorecard school records.
3. Map API fields into `School`, `Program`, and `CostEstimate`.
4. Swap `MockSchoolService` for `CollegeScorecardService` inside `ExploreViewModel`.

The mock-first structure is designed so the UI and calculator can keep working while live data is added later.

## Future StoreKit 2 integration

`Services/Monetization.swift` contains the mock subscription boundary. To replace it with StoreKit 2 later:

1. Create a subscription product in App Store Connect, for example `tuitionluma.pro.monthly`.
2. Replace `MockSubscriptionManager` purchase and restore methods with StoreKit 2 `Product.products(for:)`, `purchase()`, and `Transaction.currentEntitlements`.
3. Verify transactions before setting `SubscriptionState(tier: .pro)`.
4. Observe `Transaction.updates` at app launch so Pro access changes immediately after renewal, cancellation, or refund events.
5. Keep `SubscriptionPolicy` as the single place for Free vs Pro limits, so the UI rules stay separate from StoreKit code.
