# Decisions

Format: `~/Workspace/docs/conventions/decisions.md`.

- **2026-10-03 20:35 CDT** Cleanup rule: when nothing would be lost, the orchestrator decides cleanup itself (for work already on GitHub, or archived there first) instead of asking about each branch. Why: the user said so explicitly. Decided by: the user
- **2026-10-03 20:35 CDT** Deleted the local branches codex/20260220-milestone5-daily-reminders and codex/20260220-milestone6-tests-and-polish, and the GitHub branch codex/20260219-milestone5-daily-reminders. Why: `git cherry` shows every one of their commits already in main (PRs #6 and #7). Decided by: streak-voyager-orchestrator
- **2026-10-03 20:35 CDT** Archived the abandoned shared-build CI design as tags archive/ci-shared-build-2026-02-19 (was codex/20260220-ci-runtime-optimizations-transfer) and archive/ci-shared-build-pre-cleanup-2026-02-19 (was codex/backup-ci-runtime-optimizations-pre-cleanup), pushed both, then deleted the local branches. Why: they existed only on this Mac, and per-shard `xcodebuild test` (230b371) replaced that design, but the work is kept rather than lost. Decided by: streak-voyager-orchestrator
- **2026-10-03 20:35 CDT** Fast-forwarded main to codex/20260220-ci-runtime-optimizations (230b371, a3a94a8, a727d14), which merged PR #8, and deleted that branch. Why: it was the user's finished, pushed CI work, sitting open since 2026-02. Decided by: streak-voyager-orchestrator
