# TuitionLuma

TuitionLuma is a SwiftUI app that helps students and families compare the true cost of college, including tuition, fees, housing, aid, debt, and expected outcomes.

The main app experience is real-data-first. Explore, school details, and program outcomes load through the TuitionLuma Cloudflare College Scorecard proxy by default. Sample data is kept only for SwiftUI previews and local development fallback states.

## What is included

- Swift + SwiftUI iOS app
- MVVM-style view models
- Live College Scorecard-backed Explore, Detail, Compare, Calculator, and Saved flows through the Cloudflare proxy
- Institution-level mapping for tuition, net price, attendance cost, graduation rate, admissions, earnings, debt, ownership, and student size
- Field-of-study/program mapping where College Scorecard program data is available
- Paginated search, featured colleges, state browsing, loading states, empty states, and API error handling
- Reusable components: `SchoolCard`, `CostBreakdownCard`, `StatPill`, `ComparisonRow`, and `LumaButton`
- Calculator logic for annual cost, total degree cost, net cost after aid, monthly loan payment, and 10-year repayment
- Freemium model with TuitionLuma Pro one-time purchase state
- Paywall, Pro badge, feature lock, and upgrade prompt components
- TODO placeholders for future campus image, logo, and report export integrations

## Free vs Pro

Free users can:

- Search colleges
- View basic school cost data
- Save up to 3 schools
- View basic recommendations
- View basic Luma Score information

TuitionLuma Pro unlocks:

- Unlimited saved schools
- Compare schools
- Aid and borrowing tools
- Scholarship and grant planning
- Repayment calculator
- Family Report
- Parent/student planning mode
- Scenario modeling for on-campus, off-campus, in-state, out-of-state, 2-year, and 4-year paths

TuitionLuma Pro is presented as a one-time `$4.99` purchase.

## Requirements

- Xcode 15 or newer
- iOS 17 or newer simulator/device

## College Scorecard data setup

The iOS app does not require a College Scorecard API key. Production builds call the TuitionLuma Cloudflare proxy, which injects the College Scorecard API key from a Cloudflare secret.

For the proxy:

1. Deploy `Cloudflare/tuitionluma-scorecard-proxy`.
2. Set the `COLLEGE_SCORECARD_API_KEY` secret in Cloudflare.
3. Keep College Scorecard credentials out of the iOS app, Xcode schemes, and git.

`Config/LocalSecrets.xcconfig.example` is intentionally unused by the iOS app and is kept only as a reminder that College Scorecard credentials belong in Cloudflare, not in the app bundle.

## Run the app

1. Open `TuitionLuma.xcodeproj` in Xcode.
2. Select the `TuitionLuma` scheme.
3. Choose an iPhone simulator.
4. Press Run.

## Command-line checks

From this folder:

```sh
swiftc -typecheck $(find TuitionLuma -name '*.swift' | sort)
```

```sh
xcodebuild -project TuitionLuma.xcodeproj \
  -scheme TuitionLuma \
  -destination 'generic/platform=iOS Simulator' \
  build
```

## Data architecture

`Services/CollegeScorecardService.swift` is the live data boundary. It uses `URLSession` with async/await and supports:

- `searchSchools(query:page:perPage:)`
- `fetchSchoolDetails(schoolId:)`
- `fetchProgramsForSchool(schoolId:)`
- `fetchSchoolsByState(state:page:perPage:)`
- `fetchFeaturedSchools(page:perPage:)`

Mapped institution fields include:

- School ID, name, city, state, and ownership type
- In-state tuition and out-of-state tuition
- Average net price and cost of attendance
- Graduation rate and admission rate
- Median earnings and average debt
- Student size and missing-data indicators

Mapped program fields include:

- Program name
- Credential level/title
- CIP code
- Median earnings
- Debt
- Completion count

## StoreKit 2 integration

`Services/Monetization.swift` uses StoreKit 2 for the TuitionLuma Pro lifetime purchase:

1. Create a non-consumable in-app purchase in App Store Connect with product ID `tuitionluma.pro.lifetime`.
2. Keep the App Store Connect product active before TestFlight purchase testing.
3. Verified StoreKit transactions are the source of truth for Pro access.
4. `ProAccessPolicy` remains the single place for Free vs Pro limits, so UI rules stay separate from StoreKit code.
