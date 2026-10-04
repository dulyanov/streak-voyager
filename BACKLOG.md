# Backlog

Format: `~/Workspace/docs/conventions/backlog.md`.

## Next

- Inject the reminder store and scheduler in HomeDashboardViewModelTests. Why: several tests build the view model with the defaults, which touch the real UserDefaults.standard and UNUserNotificationCenter (HomeDashboardViewModel.swift:31-32). Added 2026-10-03.
- Fix the docs that describe the old CI and test setup. Why: docs/PROGRESS.md:46 says CI builds once with build-for-testing, but ios-ci.yml runs `xcodebuild test` in each shard; the unit tests use Swift Testing, not XCTest. Added 2026-10-03.

## Later

- Close the gaps with ~/Workspace/docs/conventions/ci.md. Why: there's no single local command for every check, no linter, and no codecov.yml or coverage gate (`fail_ci_if_error: false`), and pushes trigger CI only on main. Added 2026-10-03.
- Measure the claim that parallel test workers cost more than they gain (ios-ci.yml:62-63) with scripts/ci-benchmark.sh. Why: it is stated as fact but was never measured. Added 2026-10-03.

## Ideas
