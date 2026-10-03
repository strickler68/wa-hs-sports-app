# Project Handoff — WA High School Sports Tracker

Written so this project can be picked up by a different AI assistant, or
a fresh chat, with no memory of how it got here. If you're an AI reading
this to continue the work: the human you're helping is a GIS data
scientist (Python/JS) at a WA state agency, comfortable with technical
detail, prefers direct answers over hedging, and has been building this
incrementally over one long session — don't re-litigate settled
decisions below without a reason.

## What this is

A real-time high school sports tracker for Washington State, covering
four WIAA leagues: **KingCo, NPSL, SPSL, and Metro** (72 schools total).
The core problem it solves: MaxPreps is poorly used by WA coaches, and
there's no good source of real-time scores, schedules, or local content
for these schools. The product combines a map, a schedule, live
period-by-period score tracking, and links to news/content per school.

Two target audiences for the frontend: mobile (assumed ~85%+ of users)
and desktop, built as **two separate apps** sharing one backend — not
one responsive design trying to serve both well.

## Current state (be honest about this with whoever picks this up)

**Done:**
- Data model designed and reasonably mature (see `schema.sql`)
- 72 schools verified against official WIAA league sources — not
  guessed, not scraped from stale articles. See "How the school data
  was verified" below; this took real effort, don't casually redo it.
- Two working frontend prototypes (mobile + desktop), currently running
  entirely on browser `localStorage` — **not yet connected to a real
  backend**. They demonstrate the UX; they don't share data with each
  other yet.
- Backend config files written (PostgREST + Martin) but **not yet run
  anywhere** — no real database is live yet.

**Not done / explicitly deferred:**
- No real database running. This is the actual next step.
- No real auth. There's a placeholder passcode gate in the prototypes
  (`PASSCODE` constant in the JS), explicitly documented as not real
  security — just enough to deter casual messing-around.
- No ingestion pipeline from real people (coaches/fans) yet — that's a
  people problem as much as a technical one, still open.
- WIAA administrative district polygon (for a basemap) — discussed,
  not built. Deferred pending a decision on WIAA districts vs. actual
  school district boundaries (see below).
- Scrollytelling/story-map feature — deliberately deprioritized in
  favor of the simpler drill-down school panels, which are done.

## Files in this project, and what each is for

| File | Purpose |
|---|---|
| `schema.sql` | PostGIS schema — leagues, schools, teams, games, scoring events, sources, content links |
| `schools_seed.csv` | The 72 verified schools with league/classification/district/city/county/NCES ID |
| `seed_data.sql` | Ready-to-run INSERT statements generated from the CSV + approximate coordinates |
| `db_roles_and_grants.sql` | Postgres roles for PostgREST (web_anon read-only, web_editor for writes) |
| `postgrest.conf` | PostgREST server config — turns the schema into a REST API, no backend code needed |
| `postgrest_examples.md` | Concrete curl examples for every write action both frontends need |
| `enrich_and_load.py` | One-time script to load precise school coordinates from WA OSPI's public-schools GIS layer |
| `README.md` | Setup instructions for the database layer |
| `TECH_STACK.md` | Full architecture explanation, install checklist, documentation reading list |
| `ROADMAP.md` | Living task checklist — the actual project management tool being used (deliberately not Trello — see below) |
| `wa_hs_sports.html` | Mobile prototype — bottom nav, map/schedule/live-scoring/content-links tabs |
| `wa_hs_sports_desktop.html` | Desktop prototype — same data model, sidebar nav, split-pane layout |
| `maplibre_demo.html` | Standalone demo proving a real tiled basemap works outside a sandboxed environment |

## Key decisions already made (don't re-litigate without a reason)

- **Open-source stack, zero licensing cost, explicitly not ArcGIS.**
  PostGIS (database) → PostgREST (REST API, the direct equivalent of an
  ArcGIS Feature Service) → Martin or pg_tileserv (vector tiles, the
  equivalent of an ArcGIS Map Service) → MapLibre GL JS (rendering) →
  Protomaps (basemap tiles). QGIS for desktop GIS work. Full reasoning
  and install steps in `TECH_STACK.md`.
- **School coordinates come from WA OSPI's official public-schools GIS
  layer**, not NCES — OSPI's data is building-centroid-corrected and
  state-specific. NCES was the first choice; superseded once the OSPI
  layer was found. `enrich_and_load.py` reflects this.
- **Schools are static** — coordinate/directory loading is a one-time
  task, not a recurring sync.
- **Auth**: no real auth yet. Recommended path when it's time: Supabase
  (Postgres-native, bundles auth + row-level security on top of the
  same PostgREST pattern already in use) over hand-rolling JWTs.
- **Project management**: a markdown file (`ROADMAP.md`) checked in
  alongside the code, not Trello — chosen deliberately for a solo
  technical builder where the tasks are tightly coupled to specific
  files.
- **Color palette for the map**: four distinct hues, one per league,
  each stepped by lightness for classification within that league —
  KingCo (evergreen), NPSL (violet), SPSL (navy), Metro (crimson).
  Picked deliberately after an earlier bronze/amber attempt read as
  muddy next to the others.

## How the school data was verified (so it isn't accidentally redone badly)

Started from general web knowledge and old news articles — this
produced real errors (wrong classifications, schools placed in the
wrong league, at least one school missed entirely). Corrected via:
1. WIAA's own school directory (via `wiaa.finalforms.com`, which
   `wiaa.com` itself links to as its official directory)
2. Official per-league administration sites (`kingcoathletics.com`,
   `metroleaguewa.org`, `npslathletics.org`, `spsl.org`) — the single
   most reliable source found, since these are the leagues' own rosters
3. The user's own direct local knowledge (a family member plays for a
   school in NPSL), used to resolve at least one genuine conflict
   between two otherwise-authoritative sources (Hazen's league)

Takeaway for whoever continues this: **prefer a league's own
administration site over news articles or general knowledge**, and
don't assume a single source is authoritative without cross-checking —
multiple real conflicts turned up between sources that each looked
credible on their own.

## WIAA districts — open question, not resolved

WIAA has 6 (not 9 — an earlier Wikipedia-sourced claim of 9 was wrong,
corrected via a screenshot of WIAA's own district map) administrative
districts. KingCo and Metro are District 2; NPSL and SPSL are District
3. District 3 is **non-contiguous** — it covers both the Olympic
Peninsula and the South Puget Sound area as one number. No official
GIS polygon exists for these districts; building one would mean
approximating from county boundaries, with a genuinely fuzzy line
needed to split King County itself (KingCo/Metro schools vs.
NPSL/SPSL schools both sit in King County but are different WIAA
districts). This was flagged as a real open decision, not solved.
Separately, WA OSPI *does* publish authoritative individual school
district boundaries (different concept — Federal Way SD, Auburn SD,
etc.) via the same ArcGIS service used for school-district data
(`Schools_Explorer_Data_2024`, layer `/2`).

## If you're an AI assistant without Claude's specific tools

Some things done in this project used Claude-specific capabilities
that may not exist in your environment:
- A persistent sandboxed filesystem for building/testing files
- A published "artifact" system for hosting the HTML prototypes at a
  shareable link (the mobile/desktop apps were published this way —
  if you can't do this, just deliver the HTML files directly)
- Web search — the school-verification work above depended heavily on
  live search against WIAA/league sites; don't guess league
  membership from training data alone, it's been shown to be wrong

Adapt as needed; the project's substance (the schema, the data, the
architecture decisions) doesn't depend on any of that tooling.
