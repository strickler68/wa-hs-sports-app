# Roadmap

A living checklist, not a status report — edit this file directly as
things move. Check items off, add new ones, delete what's no longer
relevant. Lives in the same folder as the code on purpose.

## Backend (the current focus)

- [x] Install PostgreSQL + PostGIS (done in the Claude Code sandbox — not yet on a persistent/public host)
- [x] Load `schema.sql`, `seed_data.sql`, `db_roles_and_grants.sql` — fixed a real bug along the way: `schema.sql`'s `schools` table had `city` declared twice, silently aborting the whole script before
- [x] Run PostgREST against it, confirmed `GET /schools` returns real JSON for all 72 schools
- [ ] Walk through every example in `postgrest_examples.md`
- [ ] Run Martin, confirm vector tiles come back (deferred — not a blocker at 72 points)
- [ ] Wire `maplibre_demo.html` to Martin's tile endpoint instead of static GeoJSON
- [x] Wire the mobile app's `loadSchedule`/`saveSchedule`/etc. to the real Supabase backend instead of `localStorage` (Schedule + Live update tabs)
- [x] Wire the desktop app the same way (Schedule + Live update tabs) — 2026-10-04
- [x] Confirm both apps see the same data after that (the actual "one backend, many GUIs" test) — both point at the same Supabase project/tables
- [ ] Migrate the content-links tab on both apps off `localStorage` (schema/FK mismatch between school name and school id not yet resolved)

## Public deployment (new — low/no-cost path chosen)

- [x] Decided on stack: Supabase (free tier, DB+API) + Cloudflare Pages (free, static frontend hosting) + Cloudflare Registrar (~$10-12/yr domain) — total ~$1/mo amortized
- [x] Project reorganized into `wa-hs-sports/` with `sql/ data/ docs/ frontend/ config/ demo/ public/ supabase/migrations/`
- [x] `supabase/migrations/` prepared from the existing SQL files, with a Supabase-adapted roles file (Supabase's built-in `authenticator` role collides with the original `CREATE ROLE authenticator`; adapted version grants to Supabase's `anon`/`authenticated` roles instead)
- [x] `public/` built as the Cloudflare Pages deploy root (device-split `index.html` → `/mobile/` or `/desktop/`)
- [x] Git repo initialized and committed locally
- [x] `DEPLOY.md` written — exact click-by-click steps for the account-creation parts only you can do
- [ ] You: buy domain via Cloudflare Registrar
- [x] You: create Supabase project, run the 6 migrations in order, grab the project URL + anon key
- [x] You: create a GitHub account + repo (renamed to `strickler68/wa-hs-sports-app`) and install the Claude GitHub App with push access
- [x] Push to GitHub resolved — repo renamed to `wa-hs-sports-app` to clear a session-level name lock; 9+ commits pushed, `main` up to date
- [x] Rewire both frontends to call the real Supabase URL instead of `localStorage` (mobile done 10-03, desktop done 10-04)
- [x] You: connect the GitHub repo to Cloudflare Pages — confirmed live
- [ ] You: attach the custom domain once purchased

## Design (parked — user has ideas, deliberately not discussing yet)

- [ ] **PARKED**: user wants to revisit the map's visual design — look
  specifically at `demo/maplibre_demo.html`'s rendering and how the
  input data (`data/schools_seed.csv`, the 72-school coordinate set)
  drives it. User has specific ideas already but said to park the
  discussion until the current deploy work (Supabase + Cloudflare) is
  finished. Don't start this unprompted — wait for the user to bring it
  back up. See CLAUDE.md's "Quality bar" section for the general design
  standard this should meet once it's picked back up.

## Data

- [ ] Find the school-points layer number in the `Schools_Explorer_Data_2024` ArcGIS service
- [ ] Download it, run `enrich_and_load.py` for precise coordinates
- [ ] Decide: WIAA administrative district outline (2/3/etc.) vs. individual school district boundaries vs. both — deferred earlier, still open
- [ ] If WIAA districts: work out the King County District 2/3 split (fuzzy, not a published line)

## Auth

- [ ] Decide: Supabase (packaged) vs. hand-rolled JWT + your own login flow
- [ ] Replace the passcode-gate stopgap once real auth exists
- [ ] Design actual roles: coach (own school only), AD, fan/stringer, admin

## Product / content

- [ ] Recruit actual crowdsourced contributors (fans/students/parents at games) — the real "who updates this" problem, still unsolved. **Not coach/AD outreach** — target audience is the crowd at the game, clarified 2026-10-04.
- [ ] Revisit the X/Twitter-stringer idea once there's an audience to draw from
- [ ] Self-host a WA-only Protomaps basemap for production (currently using MapLibre's free demo tiles, fine for dev, not for a real launch)
- [ ] Scrollytelling / story-map feature — deferred in favor of the drill-down panels, which are done; revisit once there's enough real content to narrate

## Done (for morale, and so this doesn't just read like a wall of open items)

- [x] Data model designed (`schema.sql`)
- [x] 72 schools across KingCo/NPSL/SPSL/Metro, verified against official league sources
- [x] Mobile prototype (map, schedule, live scoring, content links)
- [x] Desktop prototype (same data model, split-pane layout)
- [x] Live scoring event log with assist tracking and auto-computed goal tallies
- [x] Coordinate-source decision made (OSPI over NCES)
- [x] Passcode gate (stopgap, documented as such)
