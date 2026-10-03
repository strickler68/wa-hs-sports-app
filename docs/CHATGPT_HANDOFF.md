# WA High School Sports Tracker — Project Brief (portable, AI-agnostic)

Written so **any AI assistant** (ChatGPT included) can pick this project up
with no prior context. If you're an AI reading this to help continue the
work: the human you're helping is Tim, a GIS data scientist (Python/JS,
comfortable with SQL and REST APIs) at WA DNR. He prefers direct answers
over hedging and has been building this incrementally over a long session
with Claude. Don't re-litigate the decisions logged below without a reason
— they were each made deliberately, often after correcting an earlier
mistake (see "Mistakes already made" at the end, so you don't repeat them).

He is using this file alongside a companion `HANDOFF.md` and a set of
project files (listed below) that live outside whatever chat tool he
pastes this into — if you can't see those files directly, ask him to
paste or upload the specific one you need rather than guessing its
contents.

---

## 1. What this is

A real-time high school sports tracker for Washington State. The problem
it solves: **MaxPreps is poorly used by WA coaches**, so there's no good
source of real-time scores, schedules, or local sports content for WA high
schools. The product combines:

- A map of schools, color-coded by league/classification
- Schedules (entered ahead of time, editable)
- Live, period-by-period score tracking with scorer/assist detail
- Links to news/content about each school's teams

**Scope**: 4 WIAA leagues — **KingCo, NPSL, SPSL, Metro** — 72 schools
total, verified against official sources (not general web knowledge; see
§5).

**Two frontends, one backend**: a mobile app and a desktop app, built as
genuinely separate UIs (not one responsive design), sharing a single
backend data source. Mobile is assumed to be ~85%+ of real usage, so it's
the design priority, not an afterthought.

---

## 2. Architecture

The explicit goal: an open-source stack that behaves like an **ArcGIS
Feature Service** (one REST endpoint, many GUIs, live-editable) — because
Tim's day job uses that pattern on ArcGIS, but **he does not want to pay
for an ArcGIS license** for this side project. This is a real, working
open-source equivalent, not a compromise:

```
 Mobile app (wa_hs_sports.html)      Desktop app (wa_hs_sports_desktop.html)
           │                                      │
           └──────────────┬───────────────────────┘
                           │  both call the SAME two services
                           ▼
   PostgREST — auto-generated REST API from schema.sql
   (the ArcGIS Feature Service equivalent: one endpoint, many GUIs, editable)
                           │
   Martin / pg_tileserv — vector tiles for the map layer
   (the ArcGIS Map Service equivalent)
                           │  SQL
                           ▼
   PostGIS — the actual database (schema.sql / seed_data.sql / db_roles_and_grants.sql)
```

Separately: **basemap tiles** (roads, water, place names in the
background) come from **Protomaps** (self-hostable) or, for now,
MapLibre's free public demo style — not from this database. **QGIS** is
the desktop GIS tool for one-off work (district boundary dissolves,
boundary QA), the open-source equivalent of ArcGIS Pro.

Why not one bundled tool: ArcGIS packages all of this into one licensed
product. Here, each layer is independently swappable — Martin for
pg_tileserv, hand-rolled auth for Supabase — at the cost of more moving
pieces instead of one vendor.

### Current build status

| Layer | Status |
|---|---|
| Database schema | **Designed**, not yet run anywhere live |
| Seed data (72 schools) | **Generated**, not yet loaded into a live DB |
| PostgREST config | **Written**, not yet run |
| Martin/vector tiles | **Not started** |
| Mobile prototype | **Working UI demo**, currently on browser `localStorage` only — not yet talking to any backend |
| Desktop prototype | Same — working UI demo, `localStorage` only |
| Real backend connecting the two apps | **Not done** — this is the actual next milestone |

So: nothing is "live" yet. Both frontend apps work as UI demos but each
has its own private browser storage — they do not currently share data
with each other. That's the next concrete piece of work (see §7).

---

## 3. Data model

Postgres + PostGIS. Full DDL is in `schema.sql`; summarized:

- **`leagues`** — name, short_code (KINGCO/NPSL/SPSL/METRO), classification,
  division, `wiaa_district` (int), `season_start`/`season_end` (WIAA
  realigns on a 4-year cycle, so leagues are season-versioned).
- **`schools`** — name, `nces_id` (join key for geocoding), district,
  city, county, address, `geom GEOGRAPHY(POINT,4326)`.
- **`school_league_memberships`** — many-to-many, versioned (a school's
  league can change between WIAA cycles).
- **`teams`** — one row per school + sport + gender + season_year.
- **`games`** — sport, home/away team id, date, time, venue, `venue_geom`,
  `score_home`/`score_away`, `status` (scheduled/live/final/postponed/
  cancelled), `confidence` (unverified/single_source/confirmed).
- **`sources`** — every score is tied to who reported it: source_type
  (coach/ad/student_stringer/fan/x_mention/scrape/manual), trust_score
  (0–1, meant to adjust over time based on accuracy).
- **`game_scoring_events`** — the live scoring log: period, game_clock,
  scoring_team, scorer_name, assisted_by, play_description, running
  score_home/score_away, source_id, reported_at. **Must be created after
  `sources`** in the DDL (foreign key).
- **`game_reports`** — raw/unreconciled submissions (e.g. a parsed tweet)
  before they're matched to a canonical `games` row — keeps an audit
  trail.
- **`content_links`** — news/blog/Substack links tied to a school, team,
  or game.

---

## 4. API design (PostgREST)

No backend code is written for CRUD — PostgREST reads the Postgres schema
and generates `GET`/`POST`/`PATCH`/`DELETE` on every table automatically.
Roles (see `db_roles_and_grants.sql`): `web_anon` (read-only, the default
for unauthenticated requests), `web_editor` (read/write, meant for
coaches/ADs/stringers once real auth exists), `authenticator` (the
connection role PostgREST uses to switch into the other two based on a
JWT).

Concrete examples for every call either frontend needs live in
`postgrest_examples.md`:
- `GET /schools`, `GET /games?game_date=eq.2026-10-03`
- `POST /games` (add a scheduled game — the "Schedule" tab)
- `POST /game_scoring_events` (log a live scoring event — the "Live
  update" tab); the frontend (or a Postgres trigger, better long-term)
  also needs to PATCH the parent `games` row's score/status to match
- `PATCH /games?id=eq.N` (fix a wrong schedule entry)
- `POST /content_links`

Geometry columns (`geom`, `venue_geom`) come back as raw WKB by default;
the fix is a view wrapping them in `ST_AsGeoJSON()` — see
`postgrest_examples.md` for the exact `CREATE VIEW schools_geojson AS …`.

**Local testing before real auth exists**: temporarily
`GRANT INSERT, UPDATE ON games, game_scoring_events, content_links TO
web_anon;` and revoke it before ever exposing this to the internet. This
is a dev convenience, not a security model.

---

## 5. How the 72-school dataset was verified

Started from general web knowledge/old news articles — this produced real
errors (wrong classifications, a school in the wrong league, one school
missed entirely). Fixed by, in order of reliability:

1. WIAA's own directory (via `wiaa.finalforms.com`, linked from
   `wiaa.com` as WIAA's official directory)
2. Each league's own administration site — the single most reliable
   source: `kingcoathletics.com`, `metroleaguewa.org`,
   `npslathletics.org`, `spsl.org`
3. Tim's own direct local knowledge (used to resolve one genuine conflict
   between two otherwise-authoritative sources, re: one school's league)

**Lesson for whoever continues this**: prefer a league's own
administration site over news articles or general/trained knowledge, and
don't trust a single source — multiple real conflicts turned up between
sources that each looked credible alone.

School **coordinates** come from WA OSPI's official public-schools GIS
layer (`Schools_Explorer_Data_2024` ArcGIS FeatureServer), not NCES —
OSPI's data is building-centroid-corrected and WA-specific. `NCES` was
the original plan, superseded once the OSPI layer was found.
`enrich_and_load.py` reflects this. Schools are static — this is a
one-time load, not a recurring sync.

---

## 6. Security (deliberately minimal right now)

Tim's own words: **"I do not need real security just enough to keep our
shenanigans"** — i.e. the current passcode gate in the two prototype HTML
files (`PASSCODE` constant, guarding 4 write actions) is explicitly **not
real security**, just a casual deterrent. Don't "fix" this unprompted or
represent it as secure.

When real auth is eventually built, the recommended path (not yet
decided for certain — flagged as an open question) is **Supabase**
(packaged Postgres + Auth + Row-Level Security, same PostgREST pattern
already in use) over hand-rolling JWT issuance and a login flow. Planned
roles: coach (own school only), AD, fan/stringer, admin.

---

## 7. Open questions / explicitly deferred (not oversights)

- **Auth approach**: Supabase vs. hand-rolled — leaning Supabase, not
  confirmed.
- **WIAA district boundary polygon** for a basemap: WIAA has **6**
  districts (a Wikipedia-derived claim of 9 was wrong and was corrected
  from an official WIAA district map screenshot). KingCo + Metro = WIAA
  District 2; NPSL + SPSL = WIAA District 3. District 3 is
  **non-contiguous** (Olympic Peninsula + South Puget Sound as one
  number). **No official GIS polygon exists** for WIAA districts; building
  one means approximating from county boundaries, including a genuinely
  fuzzy split of King County itself (KingCo/Metro schools vs. NPSL/SPSL
  schools both sit in King County but are different WIAA districts).
  Separately, WA OSPI *does* publish real individual **school district**
  boundaries (Federal Way SD, Auburn SD, etc. — a different concept from
  WIAA districts) via the same ArcGIS service, layer `/2`.
- **Fan/stringer recruitment**: a people problem, not a technical one.
  Original idea was a dedicated Twitter/X account reaching out to each
  school's student journalism program for old-school "stringer" reports.
  Deferred until there's a working prototype + actual audience to recruit
  from.
- **Scrollytelling / ESRI StoryMap-style narrative feature**: deliberately
  deprioritized in favor of the simpler drill-down school panels, which
  are done. Revisit once there's enough real content to narrate.

---

## 8. File inventory

| File | Purpose |
|---|---|
| `schema.sql` | PostGIS schema — leagues, schools, teams, games, scoring events, sources, memberships, content links |
| `schools_seed.csv` | The 72 verified schools w/ league/classification/district/city/county/NCES id |
| `seed_data.sql` | Ready-to-run INSERTs generated from the CSV + coordinates |
| `db_roles_and_grants.sql` | Postgres roles for PostgREST (web_anon / web_editor / authenticator) |
| `postgrest.conf` | PostgREST server config — turns the schema into a REST API |
| `postgrest_examples.md` | curl examples for every CRUD action either frontend needs |
| `enrich_and_load.py` | One-time script loading precise coordinates from WA OSPI's GIS layer |
| `README.md` | Setup instructions for the database layer |
| `TECH_STACK.md` | Full architecture explanation, install order, doc reading list |
| `ROADMAP.md` | Living task checklist — the project-management tool in use (chosen over Trello deliberately — tightly file-coupled solo project) |
| `wa_hs_sports.html` | Mobile prototype — bottom nav, map/schedule/live-scoring/content tabs, localStorage-backed |
| `wa_hs_sports_desktop.html` | Desktop prototype — same data/logic, sidebar nav, split-pane layout |
| `maplibre_demo.html` | Standalone proof that a real tiled basemap (MapLibre + public demo tiles) works outside a sandboxed preview |
| `HANDOFF.md` | An earlier, shorter AI-handoff file — this document supersedes it with more architectural/API/security detail, but both describe the same project consistently |

---

## 9. Getting started (if you're helping actually build next)

Stage order (also in `TECH_STACK.md` with exact install commands):

1. **Database**: install PostgreSQL + PostGIS, then
   `createdb wahsports && psql wahsports -f schema.sql -f seed_data.sql -f db_roles_and_grants.sql`
   (run `enrich_and_load.py` for precise coordinates — needs
   `psycopg2-binary`).
2. **API**: download the PostgREST binary, run `postgrest postgrest.conf`,
   confirm `GET http://localhost:3000/schools` returns JSON. This is the
   fastest way to see the "one API, many clients" pattern become real.
   Then walk every example in `postgrest_examples.md`.
3. **Tiles**: run Martin (or pg_tileserv) against the same DB on a
   different port (PostgREST uses 3000), confirm vector tiles come back.
4. **Map**: point `maplibre_demo.html` at Martin's tile endpoint instead
   of its current static GeoJSON array.
5. **Wire up both frontends**: replace `loadSchedule`/`saveSchedule`/etc.
   in both HTML files (currently reading/writing `localStorage`) with
   `fetch()` calls against the live PostgREST endpoint. This is the step
   that makes "same data, two apps" actually true instead of aspirational
   — and is the real test of the whole architecture.

Documentation reading order (each assumes the last): PostgreSQL docs (as
a refresher only) → PostGIS docs (geography-vs-geometry page + `ST_*`
reference) → **PostgREST's own Tutorial** (short, directly answers "how
do I turn a table into an API") → Martin's GitHub README → MapLibre GL JS
docs (Examples section, not the API reference, to start) → QGIS docs
(only the web-services and dissolve/union chapters, not cover-to-cover)
→ Supabase docs (Auth + RLS guide specifically), if that path is chosen.

---

## 10. Mistakes already made, so you don't repeat them

- **Don't trust a single secondary source for WIAA facts.** An early
  claim that WIAA has 9 districts (from a stale/Wikipedia-derived source)
  was wrong — it's actually 6, corrected from an official WIAA district
  map screenshot Tim provided.
- **Don't assume the localStorage prototypes can't share a backend.**
  Early framing implied the two-separate-apps pattern meant they
  structurally couldn't share data — that's wrong; it was only true of
  the current prototype stage. The real architecture (§2) shares one
  backend by design; this was a framing correction, not an architecture
  change.
- **Don't casually re-verify or second-guess the 72-school list** without
  cause — it already went through real cross-source conflict resolution
  (§5); redoing it carelessly risks reintroducing the errors that were
  already caught and fixed.
- **Coordinate source is OSPI, not NCES** — if you see NCES-sourced
  coordinates anywhere, they're the superseded version.
