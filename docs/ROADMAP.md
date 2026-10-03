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
- [ ] Wire the mobile app's `loadSchedule`/`saveSchedule`/etc. to the real backend instead of `localStorage` — **next concrete task**
- [ ] Wire the desktop app the same way
- [ ] Confirm both apps see the same data after that (the actual "one backend, many GUIs" test)

## Public deployment (new — low/no-cost path chosen)

- [x] Decided on stack: Supabase (free tier, DB+API) + Cloudflare Pages (free, static frontend hosting) + Cloudflare Registrar (~$10-12/yr domain) — total ~$1/mo amortized
- [x] Project reorganized into `wa-hs-sports/` with `sql/ data/ docs/ frontend/ config/ demo/ public/ supabase/migrations/`
- [x] `supabase/migrations/` prepared from the existing SQL files, with a Supabase-adapted roles file (Supabase's built-in `authenticator` role collides with the original `CREATE ROLE authenticator`; adapted version grants to Supabase's `anon`/`authenticated` roles instead)
- [x] `public/` built as the Cloudflare Pages deploy root (device-split `index.html` → `/mobile/` or `/desktop/`)
- [x] Git repo initialized and committed locally
- [x] `DEPLOY.md` written — exact click-by-click steps for the account-creation parts only you can do
- [ ] You: buy domain via Cloudflare Registrar
- [ ] You: create Supabase project, run the 3 migrations in order, grab the project URL + anon key
- [x] You: create a GitHub account + repo (`strickler68/wa-hs-sports`) and install the Claude GitHub App with push access
- [ ] **BLOCKED**: push from this session failed — this session's GitHub access got locked to a now-dead username (`tstr490`, renamed to `strickler68`, no redirect). Fix: start a brand-new Claude Code conversation naming `strickler68/wa-hs-sports` from the first message. Full project backed up at `/mnt/user-data/outputs/wa-hs-sports-full-backup.tar.gz` in case the container doesn't carry over. See `docs/EOD_2026-10-03.md` for the full story.
- [ ] Rewire both frontends to call the real Supabase URL instead of `localStorage` (same task as above, just targeting the hosted DB instead of localhost)
- [ ] You: connect the GitHub repo to Cloudflare Pages, attach the custom domain

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

- [ ] Recruit actual fan/stringer reporters — the real "who updates this" problem, still unsolved
- [ ] Revisit the X/Twitter-stringer idea once there's an audience to draw from
- [ ] Self-host a WA-only Protomaps basemap for production (currently using MapLibre's free demo tiles, fine for dev, not for a real launch)
- [ ] Scrollytelling / story-map feature — deferred in favor of the drill-down panels, which are done; revisit once there's enough real content to narrate
- [ ] AD outreach — the original "reach out once there's a working prototype" plan; prototype now exists

## Done (for morale, and so this doesn't just read like a wall of open items)

- [x] Data model designed (`schema.sql`)
- [x] 72 schools across KingCo/NPSL/SPSL/Metro, verified against official league sources
- [x] Mobile prototype (map, schedule, live scoring, content links)
- [x] Desktop prototype (same data model, split-pane layout)
- [x] Live scoring event log with assist tracking and auto-computed goal tallies
- [x] Coordinate-source decision made (OSPI over NCES)
- [x] Passcode gate (stopgap, documented as such)
