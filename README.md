# Workout Tracker

A dark-themed, modern iOS workout tracking app. SwiftUI + SwiftData. iOS 17+.

## Features

- Create / edit / delete custom **exercises** (weight + reps, weight + time, or cardio time + intensity)
- Mark exercises as **unilateral** for per-side (L/R) set tracking
- Per-exercise **progressive overload** suggestions with customizable weight increments
- Build **workouts** as ordered collections of exercises with set/rep goals
- Define **splits** as ordered workouts and track your position across the rotation
- **Active workout** view with elapsed-time timer and live set logging
- See **last session's stats** for each exercise while logging
- Full **history** of past sessions with per-exercise detail

## TestFlight from Windows (recommended)

See **[SETUP.md](SETUP.md)** for a step-by-step guide. The short version:

1. One-time: register your bundle ID + app in App Store Connect, generate a distribution cert with OpenSSL (Windows), and add six secrets to your GitHub repo.
2. `git push` → GitHub Actions builds on a macOS runner, signs, and uploads to TestFlight.
3. Install via TestFlight on your iPhone. Re-installs whenever you push.

No Mac needed — the entire workflow runs from Windows + browser.

## Local building (only if you have a Mac)

This project is iOS-only — you need macOS + Xcode 15+ to build it. Source was authored on Windows, so the `.xcodeproj` is not committed. Generate it with [XcodeGen](https://github.com/yonaskolb/XcodeGen):

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
├── Components/                    # Reusable views
├── Views/
│   ├── Home/
│   ├── Exercises/
│   ├── Workouts/
│   ├── Splits/
│   ├── ActiveWorkout/
│   └── History/
├── Logic/                         # Progressive overload, formatting
└── Info.plist
```
