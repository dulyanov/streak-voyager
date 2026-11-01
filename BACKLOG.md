# Backlog

Work not started yet. Format: `~/Workspace/docs/conventions/backlog.md`.
Work in progress is in the orchestrator's state.md. Decisions are in
`docs/decisions.md`.

## Next

- **Adopt the workspace versioning and pull-request conventions.** Why: the workspace conventions `~/Workspace/docs/conventions/versioning.md` and `ci.md` now apply to every repo, and this repo doesn't follow them yet. (1) Versioning: `~/Workspace/docs/conventions/versioning.md` (Workspace 9918122): this repo is the "built artifact" kind, so stamp `YYYY.MM.DD.HHMMSS+g<hash>` from git at build time, put it in the app's bundle version (CFBundleVersion, the `CURRENT_PROJECT_VERSION` build setting, hand-set to 1 today), and never set it by hand; copy the reference build step from family-mcp or security (ask workspace-orchestrator for the sha). (2) Landing: `~/Workspace/docs/conventions/ci.md` "Landing" (c6e0601): every change through a pull request into main; Danila merges it, never the session (no `gh pr merge`, no push of main). (3) CI triggers: `push: branches: [main]` plus `pull_request: {branches: [main], types: [opened, synchronize, reopened, edited]}`; every job without `needs:` gets `if: github.event.action != 'edited' || github.event.changes.base`, so a title or description edit starts no job but retargeting a stacked PR at main does; the concurrency group gives each main run and each description-edit run a group of its own, and cancels superseded PR runs (ci.md "Triggers", 026e8c9); in `.github/workflows/ios-ci.yml` the jobs without `needs:`, `test-shards` and `ui-tests-main`, each need the `if:` guard (combined with `ui-tests-main`'s existing push-only `if:`), and its `workflow_dispatch` trigger stays. (4) workspace-orchestrator has a list of rule changes from 2026-10-23..31 to pass on (first names, dependencies, design docs, private-data LAN rule, decisions attribution, requests between sessions): ask it at start-up. Added 2026-10-31.
- **Close the gaps with the CI convention.** Why: against `~/Workspace/docs/conventions/ci.md` there's no single local check command, no linter, and pushes trigger CI only on main (`ios-ci.yml:7-9`). Added 2026-10-03.
- **Give the README setup, build and test steps and a docs/ map.** Why: `README.md` is 5 lines with none of them, which `~/Workspace/docs/conventions/docs-layout.md` asks for, including the one command that runs CI. Added 2026-10-03.
- **Move CLAUDE.md's reference content into docs/.** Why: the architecture, directory structure and naming sections (`CLAUDE.md:13-36`) are reference, which docs-layout.md puts in `docs/<topic>.md`; CLAUDE.md should keep only what every session needs, name the docs/ file to read for each kind of task, and state the command that runs CI, which doesn't exist yet (see the CI item above). Added 2026-10-03.

## Later

- **Measure whether parallel test workers cost more than they gain.** Why: `ios-ci.yml:62-63` states it as fact, but it was never measured; `scripts/ci-benchmark.sh` can measure it. Added 2026-10-03.
- **Add adaptive set progression and flexible rep logging.** Why: deferred in 2026-02 until tests and CI were in place, which they now are; flexible logging means logging fewer or more reps than the target. Added 2026-02.

## Ideas
