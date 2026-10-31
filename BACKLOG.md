# Backlog

Work not started yet. Format: `~/Workspace/docs/conventions/backlog.md`.
Work in progress is in the orchestrator's state.md. Decisions are in
`docs/decisions.md`.

## Next

- **Adopt the workspace versioning and pull-request conventions.** Why: Danila asked every orchestrator to put these first (2026-10-31). (1) Versioning: `~/Workspace/docs/conventions/versioning.md` (Workspace 9918122): this repo is the "built artifact" kind, so stamp `YYYY.MM.DD.HHMMSS+g<hash>` from git at build time, print it for `--version`, and never set it by hand; copy the reference build step from family-mcp or security (ask workspace-orchestrator for the sha). (2) Landing: `~/Workspace/docs/conventions/ci.md` "Landing" (c6e0601): every change through a pull request into main, landed by `git merge --ff-only` of the sha CI checked plus a push of main, never `gh pr merge`. (3) CI triggers: `push: branches: [main]` plus `pull_request: branches: [main]`, no job-level event gate (ci.md "Triggers", 0dbf1ae). (4) workspace-orchestrator has a list of rule changes from 2026-10-23..31 to pass on (first names, dependencies, design docs, private-data LAN rule, decisions attribution, requests between sessions): ask it at start-up. Added 2026-10-31.
- **Close the gaps with the CI convention.** Why: against `~/Workspace/docs/conventions/ci.md` there's no single local check command, no linter, and pushes trigger CI only on main (`ios-ci.yml:7-9`). Added 2026-10-03.
- **Give the README setup, build and test steps and a docs/ map.** Why: `README.md` is 5 lines with none of them, which `~/Workspace/docs/conventions/docs-layout.md` asks for, including the one command that runs CI. Added 2026-10-03.
- **Move CLAUDE.md's reference content into docs/.** Why: the architecture, directory structure and naming sections (`CLAUDE.md:13-36`) are reference, which docs-layout.md puts in `docs/<topic>.md`; CLAUDE.md should keep only what every session needs, name the docs/ file to read for each kind of task, and state the command that runs CI, which doesn't exist yet (see the CI item above). Added 2026-10-03.

## Later

- **Measure whether parallel test workers cost more than they gain.** Why: `ios-ci.yml:62-63` states it as fact, but it was never measured; `scripts/ci-benchmark.sh` can measure it. Added 2026-10-03.
- **Add adaptive set progression and flexible rep logging.** Why: deferred in 2026-02 until tests and CI were in place, which they now are; flexible logging means logging fewer or more reps than the target. Added 2026-02.

## Ideas
