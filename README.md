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
- Empty, loading, and error states
- TODO placeholder for future College Scorecard API integration

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
