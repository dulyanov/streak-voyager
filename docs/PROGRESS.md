# StreakVoyager MVP Progress

Last Updated: 2026-02-19

## Milestone Status
- [x] Project bootstrap and repository setup
- [x] Milestone 1: app shell and static home dashboard
- [x] Milestone 2: workout flow (sets, reps, rest timer)
- [x] Milestone 3: streak and XP logic
- [x] Milestone 4: persistence
- [ ] Milestone 5: daily reminders
- [ ] Milestone 6: tests and polish
- [x] Milestone 7: GitHub CI for build and tests on PRs
- [ ] Milestone 8: adaptive set progression and actual rep logging

## Active Branch
- `codex/20260219-ci-parallel-pr-tests`

## Handoff
- Milestones 3 and 4 are implemented on this branch.
- Workout flow now supports two completion paths during active sets:
  - large tap-to-count rep area
  - quick `Complete Set` button beside the set track
- Dashboard progress now persists in UserDefaults:
  - total workouts, total XP, current/longest streak
  - per-day completed workout IDs
  - day rollover reset and missed-day streak reset rules
- Recommended next branch for Xcode session:
  - `codex/20260219-milestone5-daily-reminders`
- Milestone 5 implementation target:
  - Notification permission prompt flow
  - Configurable daily reminder time (simple MVP default is acceptable)
  - Local notification scheduling/cancel behavior
- Milestone 8 is intentionally deferred until after Milestones 6 and 7:
  - Allow logging fewer or more reps per set
  - Add progression rules to adjust future set targets

## Notes
- MVP exercise set: Squats and Push-ups.
- Initial target features: streaks, XP, daily progress, and reminders.
- Home dashboard styling uses dynamic light and dark color tokens.
- CI workflow added at `.github/workflows/ios-ci.yml`.
- Unit-test CI is sharded by functional test area and runs with parallel-testing workers.
- CI sharding uses `-skip-testing` filters for reliability on the current Xcode toolchain.
- CodeQL workflow added at `.github/workflows/codeql.yml` with manual Swift build extraction.
- Deferred CI optimization for later-stage discussion: switch to `build-for-testing` once and shard via `test-without-building` to reduce duplicate build overhead on GitHub runners.
