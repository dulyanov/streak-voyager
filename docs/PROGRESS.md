# StreakVoyager MVP Progress

Last Updated: 2026-02-19

## Milestone Status
- [x] Project bootstrap and repository setup
- [x] Milestone 1: app shell and static home dashboard
- [x] Milestone 2: workout flow (sets, reps, rest timer)
- [ ] Milestone 3: streak and XP logic
- [ ] Milestone 4: persistence
- [ ] Milestone 5: daily reminders
- [ ] Milestone 6: tests and polish
- [x] Milestone 7: GitHub CI for build and tests on PRs
- [ ] Milestone 8: adaptive set progression and actual rep logging

## Active Branch
- `codex/20260219-milestone2-workout-flow`

## Handoff
- Milestone 2 is implemented on this branch.
- Recommended next branch for Xcode session:
  - `codex/20260219-milestone3-streaks-xp`
- Milestone 3 implementation target:
  - Day-based streak calculation and reset rules
  - XP and level persistence across launches
  - Daily progress reset by calendar day
- Milestone 8 is intentionally deferred until after Milestones 6 and 7:
  - Allow logging fewer or more reps per set
  - Add progression rules to adjust future set targets

## Notes
- MVP exercise set: Squats and Push-ups.
- Initial target features: streaks, XP, daily progress, and reminders.
- Home dashboard styling uses dynamic light and dark color tokens.
- CI workflow added at `.github/workflows/ios-ci.yml`.
