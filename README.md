# TuitionLuma

TuitionLuma is a SwiftUI app that helps students and families compare the true cost of college, including tuition, fees, housing, aid, debt, and expected outcomes.

The main app experience is real-data-first. Explore, school details, and program outcomes load from the U.S. Department of Education College Scorecard API by default. Sample data is kept only for SwiftUI previews, local development fallback, and missing-key demo states.

## What is included

- Swift + SwiftUI iOS app
- MVVM-style view models
- Live College Scorecard API-backed Explore, Detail, Compare, Calculator, and Saved flows
- Institution-level mapping for tuition, net price, attendance cost, graduation rate, admissions, earnings, debt, ownership, and student size
- Field-of-study/program mapping where College Scorecard program data is available
- Paginated search, featured colleges, state browsing, loading states, empty states, missing-key state, and API error handling
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

TuitionLuma Pro is presented as a one-time `$4.99` purchase.

## Requirements

- Xcode 15 or newer
- iOS 17 or newer simulator/device
- College Scorecard API key from `api.data.gov`

## College Scorecard API setup

TuitionLuma reads the API key from `COLLEGE_SCORECARD_API_KEY`. Do not hardcode API keys in source files or commit them to git.

Recommended local setup:

1. Copy `Config/LocalSecrets.xcconfig.example` to `Config/LocalSecrets.xcconfig`.
2. Replace the placeholder value with your College Scorecard API key.
3. Build and run the app from Xcode.

`Config/LocalSecrets.xcconfig` is ignored by git. Xcode injects the value into the generated app Info.plist through `Config/TuitionLuma.xcconfig`, so the simulator can still use live data if you relaunch the installed app directly.

Alternative Run scheme setup in Xcode:

1. Open `TuitionLuma.xcodeproj`.
2. Select Product > Scheme > Edit Scheme.
3. Choose Run > Arguments.
4. Add an environment variable named `COLLEGE_SCORECARD_API_KEY`.
5. Paste your local key as the value.
6. Keep the key out of git.

Command-line build/run tools can also pass the key as an environment variable:

```sh
COLLEGE_SCORECARD_API_KEY=your_key_here \
xcodebuild -project TuitionLuma.xcodeproj \
  -scheme TuitionLuma \
  -destination 'generic/platform=iOS Simulator' \
  build
```

The Xcode project exposes `COLLEGE_SCORECARD_API_KEY` as a build setting and maps it to the generated Info.plist key `CollegeScorecardAPIKey`. The checked-in `Config/TuitionLuma.xcconfig` keeps the default empty and optionally includes the ignored local secrets file.

When the key is missing, Explore shows a polished missing-key state with an explicit “Use Sample Data” fallback. That sample fallback is not the default production flow.

## Run the app

1. Open `TuitionLuma.xcodeproj` in Xcode.
2. Add `COLLEGE_SCORECARD_API_KEY` to the Run scheme environment.
3. Select the `TuitionLuma` scheme.
4. Choose an iPhone simulator.
5. Press Run.

## Command-line checks

From this folder:

```sh
swiftc -typecheck $(find TuitionLuma -name '*.swift' | sort)
```

```sh
COLLEGE_SCORECARD_API_KEY=your_key_here \
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
