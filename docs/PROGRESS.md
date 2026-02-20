# StreakVoyager MVP Progress

Last Updated: 2026-02-20

## Milestone Status
- [x] Project bootstrap and repository setup
- [x] Milestone 1: app shell and static home dashboard
- [x] Milestone 2: workout flow (sets, reps, rest timer)
- [x] Milestone 3: streak and XP logic
- [x] Milestone 4: persistence
- [x] Milestone 5: daily reminders
- [ ] Milestone 6: tests and polish
- [x] Milestone 7: GitHub CI for build and tests on PRs
- [ ] Milestone 8: adaptive set progression and actual rep logging

## Active Branch
- `codex/20260220-milestone6-tests-and-polish`

## Handoff
- Milestones 3, 4, and 5 are implemented.
- Milestone 6 is in progress on this branch:
  - expanded unit-test coverage for workout and reminder edge cases
  - deterministic UI smoke tests with app reset launch argument
  - accessibility identifiers added for stable UI automation targets
- Workout flow now supports two completion paths during active sets:
  - large tap-to-count rep area
  - quick `Complete Set` button beside the set track
- Dashboard progress now persists in UserDefaults:
  - total workouts, total XP, current/longest streak
  - per-day completed workout IDs
  - day rollover reset and missed-day streak reset rules
- Milestone 5 reminders are implemented:
  - Notification permission prompt flow (not determined, denied, authorized handling)
  - Configurable daily reminder time persisted in UserDefaults
  - Local notification schedule/cancel with a stable request ID
  - Reminder status refresh and resync when app returns to foreground
- Milestone 8 is intentionally deferred until after Milestones 6 and 7:
  - Allow logging fewer or more reps per set
  - Add progression rules to adjust future set targets

## Notes
- MVP exercise set: Squats and Push-ups.
- Initial target features: streaks, XP, daily progress, and reminders.
- Home dashboard styling uses dynamic light and dark color tokens.
- CI workflow added at `.github/workflows/ios-ci.yml`.
- Unit-test CI builds once with `build-for-testing` and executes shard-specific `test-without-building` runs.
- CI sharding now uses explicit `-only-testing` filters and a pinned simulator destination (`iPhone 17 Pro`, `OS=latest`).
- CodeQL workflow added at `.github/workflows/codeql.yml` with manual Swift build extraction.
- CodeQL PR runs are path-filtered to code and workflow changes, and Swift extraction uses `ONLY_ACTIVE_ARCH=YES`.
