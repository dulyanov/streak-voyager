# Backlog

Work not started yet. Format: `~/Workspace/docs/conventions/backlog.md`.
Work in progress is in the orchestrator's state.md. Decisions are in
`docs/decisions.md`.

## Next

- **Stop the dashboard tests touching the real UserDefaults.** Why: `HomeDashboardViewModelTests.swift` builds the view model without an injected reminder store or scheduler, so it uses `.standard` and `UNUserNotificationCenter` (`HomeDashboardViewModel.swift:31-32`). Added 2026-10-03.
- **Fix the docs that describe the old CI and test setup.** Why: `docs/PROGRESS.md:46` says CI builds once with build-for-testing, but `ios-ci.yml:64` runs `xcodebuild test` in each shard; the unit tests use Swift Testing, not XCTest. Added 2026-10-03.

## Later

- **Close the gaps with the CI convention.** Why: against `~/Workspace/docs/conventions/ci.md` there's no single local check command, no linter, no codecov.yml or coverage gate (`ios-ci.yml:111`), and pushes trigger CI only on main (`ios-ci.yml:7-9`). Added 2026-10-03.
- **Measure whether parallel test workers cost more than they gain.** Why: `ios-ci.yml:62-63` states it as fact, but it was never measured; `scripts/ci-benchmark.sh` can measure it. Added 2026-10-03.

## Ideas
