# StreakVoyage

This file holds only this repo's facts. The shared rules are in `~/Workspace/CLAUDE.md`.

## Stack
- **Platform**: iOS 26.2+, native SwiftUI
- **Language**: Swift 5
- **Persistence**: UserDefaults
- **Notifications**: UserNotifications
- **Testing**: Swift Testing for unit tests, XCTest for UI tests
- **No external dependencies** (no SPM, CocoaPods, etc.)

## Architecture
- **MVVM-inspired**: `View` → `ViewModel` (`@MainActor ObservableObject`) → `Store` (protocol)
- **Protocol-based design** for all stores and schedulers, so they can be injected in tests
- **Design tokens** centralized in `AppTheme` (colors, spacing, radius)

## Directory Structure
```
StreakVoyage/
├── DesignSystem/       # AppTheme, DashboardCard
├── Features/
│   ├── Home/           # HomeDashboardView/ViewModel, HomeProgressStore, HomeModels, HomeComponents, HomeReminderNotifications
│   └── Workout/        # WorkoutSessionView/ViewModel
StreakVoyageTests/       # Unit tests (Swift Testing)
StreakVoyageUITests/     # UI tests (XCTest)
.github/workflows/       # ios-ci.yml, codeql.yml
scripts/                 # ci-benchmark.sh
docs/                    # decisions.md
```

## Naming Conventions
- Feature files: `{Feature}{Role}.swift`, e.g. `HomeDashboardViewModel.swift`, `HomeProgressStore.swift`
- Test files mirror source: `{Component}Tests.swift`
- Protocols named with an `-ing` or `-Storing` suffix: `DashboardProgressStoring`, `DailyReminderScheduling`

## Testing
- All ViewModels and Stores take their stores and schedulers as injected protocols; tests pass in-memory or
  isolated ones
- UI tests find elements by accessibility identifier, so every interactive element gets one

## CI
- **ios-ci.yml**: unit tests run in two parallel shards, each a plain `xcodebuild test` filtered with
  `-only-testing`; a new unit test suite must be added to one shard's list. UI tests run only on pushes to `main`.
  Coverage goes to Codecov.
- **codeql.yml**: Swift and Actions analysis; path-filtered on PRs, plus a weekly scheduled scan.
