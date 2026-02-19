# Repo Working Preferences

## Git Workflow
- Create feature branches with this format: `codex/YYYYMMDD-short-description`.
- Use descriptive commit messages and commit in small logical steps.
- Prefer rebase over merge commits when syncing branches.
- Keep `main` linear and clean.
- Never push automatically; only push when the user explicitly asks.

## Progress Tracking
- Maintain active milestone status in `docs/PROGRESS.md`.
- Update progress entries when milestones or scope change.

## Collaboration Mode
- Use Xcode Chat for local context analysis and quick IDE questions.
- Perform all code edits, command execution, git operations, and commits in Codex (across all current and future sessions).

## Current Focus
- Milestone 5: implement daily reminders on top of persisted workout dashboard progress.

## Roadmap Constraint
- Defer adaptive set progression and flexible rep logging (fewer/more than target) until after testing and CI milestones are in place.

## Session Handoff
- Last completed milestones: Milestone 3 (streak/XP logic), Milestone 4 (persistence), and Milestone 7 (GitHub CI workflow).
- Workout UX includes both tap-to-count reps and a quick `Complete Set` button for set-based logging.
- Start next work from a new branch following convention, for example:
  - `codex/20260219-milestone5-daily-reminders`
