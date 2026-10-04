# How we track work on this project

Replaces the flat checklist in `ROADMAP.md` for anything beyond "what's
done so far" — `ROADMAP.md` stays as the high-level status/history log
(deploy milestones, architecture decisions); **GitHub Issues + a GitHub
Project board is where day-to-day backlog, grooming, and sprints live.**
One system, not two, and it's tied directly to the code (a commit can
close an issue automatically, e.g. `git commit -m "fixes #3"`).

This is a lightweight hybrid-scrum setup, scaled down for a solo,
part-time project — not textbook scrum, and not meant to be.

## The pieces

- **Issues** = user stories (or bugs, or chores). Format: *"As a
  `<role>`, I want `<thing>`, so that `<why>`"* plus an acceptance
  criteria checklist. An issue that's too big gets marked `epic` and
  broken into smaller linked issues (see issue #1 for the pattern).
- **Labels**:
  - `epic` — a parent issue tracking several linked stories
  - `needs-data` — blocked or partly blocked on finding/building a real
    data source, not just code
  - `design` — UI/UX work, judged against the quality bar in `CLAUDE.md`
  - `area: map` / `area: scoreboard` / `area: landing` — which part of
    the app (add more `area:` labels as new parts of the app exist)
  - `bug` — GitHub's built-in default label, used normally
- **Milestones** = sprints. One milestone per sprint (e.g. "Sprint 1"),
  with a due date. An issue with no milestone is just in the backlog —
  not committed to any sprint yet.
- **The Project board** (set up once, in the GitHub UI — Projects need
  GraphQL, which isn't reachable from this Claude Code session, so this
  one piece has to be clicked through manually, not scripted):
  columns **Backlog → Ready → This Sprint → In Progress → Done**. Issues
  move left-to-right as they're groomed and worked.

## Sprint length

**Not fixed yet** — open question, to decide together. A fixed calendar
length (1 or 2 weeks) gives a predictable cadence but assumes regular
time on the project; a looser "a sprint is however much we get done
together in one sitting" better matches how this project actually gets
worked on. Sprint 1's milestone was created with a 2-week due date as a
placeholder — easy to change or delete once this is settled.

## Definition of Ready (before an issue can enter a sprint)

- Acceptance criteria are filled in and make sense (not just a title)
- Any `needs-data` blocker has at least a decided *path forward*, even
  if the data itself isn't gathered yet
- It's small enough to plausibly finish in one sprint — if not, split it
  (see the league-scoreboard epic for the pattern)

## Definition of Done (what "shippable" means here)

**Merged to `main` and live on the Cloudflare Pages URL.** This is
already automatic — every push to `main` redeploys. Nothing is "done"
sitting only in a local commit or a feature branch.

## Backlog grooming

No fixed cadence yet either — do it whenever new ideas come in (like
this session) or before starting a new sprint. Grooming means: new
issues get written up properly (not just a one-line title), stale ones
get closed or edited, and the ones closest to being worked move toward
`Ready`. Half-baked issues are fine to leave in `Backlog` — that's what
it's for.

## Current backlog (as of 2026-10-03)

| # | Title | Labels | Status |
|---|---|---|---|
| 1 | Epic: League scoreboard view | epic, area: scoreboard | Backlog |
| 2 | Split by division, highlight selected school | area: scoreboard | Backlog |
| 3 | Mouseover shows school name | area: scoreboard, design | Backlog |
| 4 | School/stadium photo on hover/selection | area: scoreboard, design, needs-data | Backlog — needs grooming, open questions unresolved |
| 5 | WA state backdrop: WIAA district polygon | area: map, needs-data | Backlog — blocked on a real decision, see issue body |
| 6 | App landing page with outside links | area: landing, design | Backlog |

See github.com/strickler68/wa-hs-sports-app/issues for the live, current
list — this table is a snapshot, not the source of truth.

## One-time setup still needed (you — Projects need the GUI)

1. Go to the repo on github.com → **Projects** tab → **New project** →
   **Board** template
2. Add columns: `Backlog`, `Ready`, `This Sprint`, `In Progress`, `Done`
3. Add all 6 existing issues to the board (bulk-add from the repo's
   issue list)
4. Everything from here on (new issues, label changes, moving cards) can
   happen either in the UI or by asking me to do it via the GitHub API
