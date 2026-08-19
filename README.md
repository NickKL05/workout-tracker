# SplitMax

A dark-themed, modern iOS workout tracking app. SwiftUI + SwiftData. iOS 17+.

> **Shipped** — SplitMax is live in beta on **TestFlight**. Every push to `main`
> is automatically built, signed, and uploaded to App Store Connect by the
> [TestFlight workflow](.github/workflows/testflight.yml), so testers get a new
> build without any manual archiving.

The repo is named `workout-tracker`; the app ships under the display name
**SplitMax** (`com.nickkl.workouttracker`).

## Features

- Create / edit / delete custom **exercises** (weight + reps, weight + time, or cardio time + intensity)
- Mark exercises as **unilateral** for per-side (L/R) set tracking
- Per-exercise **progressive overload** suggestions with customizable weight increments
- Build **workouts** as ordered collections of exercises with set/rep goals, reorderable by **drag and drop**
- Define **splits** — either a weekly schedule or an asynchronous rotation — with **muscle-coverage analysis**
- Add workouts to your active split **straight from the home screen**
- **Active workout** view with an elapsed-time timer and rest-since-last-set tracking
- **Swipe sideways** through exercises while logging; type weights and reps directly into each set
- **Add exercises mid-session** — saved to that session's record without changing the underlying workout
- See **last session's stats** for each exercise while logging
- Smart exercise **search** that understands gym shorthand (e.g. `rdl`, `db curl`, `ohp`) and a **body-part filter**
- Consistent **in-app pop-ups** for every confirmation (no system alert sheets)
- **Sign in with Apple** on first launch
- Optional **Apple Health** sync of finished sessions
- Full **history** of past sessions with per-exercise detail and progression charts

## Shipping to TestFlight

Distribution is fully automated via GitHub Actions
([`.github/workflows/testflight.yml`](.github/workflows/testflight.yml)):

- Triggers on every push to `main` that touches app sources, or manually via
  the Actions tab (`workflow_dispatch`).
- Runs on a macOS runner: generates the Xcode project with XcodeGen, renders the
  app icon, stamps a unique build number from the run number, imports the
  signing certificate + App Store provisioning profile, archives, exports the
  IPA, and uploads it to TestFlight.

Signing and upload rely on these repository secrets: `DIST_CERTIFICATE_P12`,
`DIST_CERTIFICATE_PASSWORD`, `APPLE_TEAM_ID`, `APPSTORE_ISSUER_ID`,
`APPSTORE_KEY_ID`, and `APPSTORE_PRIVATE_KEY`.

## Building locally

This project is iOS-only — you need macOS + Xcode 15+ to build it. The
`.xcodeproj` is not committed; generate it with
[XcodeGen](https://github.com/yonaskolb/XcodeGen):

```bash
brew install xcodegen
cd WorkoutTracker
xcodegen
open WorkoutTracker.xcodeproj
```

Then hit Run in Xcode (Cmd+R) targeting an iPhone simulator running iOS 17+.

### Alternative: no XcodeGen

1. Open Xcode → File → New → Project → iOS App
2. Product Name: `WorkoutTracker`, Interface: SwiftUI, Storage: SwiftData (or None — we register the schema manually)
3. Minimum deployment: iOS 17.0
4. Delete the auto-generated `ContentView.swift` and the `@Model Item` file
5. Drag the contents of `WorkoutTracker/` into the project (Copy items if needed)
6. In project settings → Info → set `UIUserInterfaceStyle = Dark`
7. Build & run

## Layout

```
WorkoutTracker/
├── WorkoutTrackerApp.swift        # @main, SwiftData container
├── Models/                        # SwiftData @Model types
├── Theme/                         # Colors, fonts, reusable styles
├── Components/                    # Reusable views (cards, buttons, pop-ups)
├── Views/
│   ├── Home/
│   ├── Auth/                      # Sign in with Apple gate
│   ├── Exercises/
│   ├── Workouts/
│   ├── Splits/
│   ├── ActiveWorkout/
│   ├── History/
│   ├── Settings/
│   └── Help/
├── Logic/                         # Progressive overload, search, Health sync, formatting
└── Info.plist
```
