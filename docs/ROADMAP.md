# Roadmap

A living checklist, not a status report — edit this file directly as
things move. Check items off, add new ones, delete what's no longer
relevant. Lives in the same folder as the code on purpose.

## Backend (the current focus)

- [ ] Install PostgreSQL + PostGIS locally
- [ ] Load `schema.sql`, `seed_data.sql`, `db_roles_and_grants.sql`
- [ ] Run PostgREST against it (`postgrest.conf`), confirm `GET /schools` works
- [ ] Walk through every example in `postgrest_examples.md`
- [ ] Run Martin, confirm vector tiles come back
- [ ] Wire `maplibre_demo.html` to Martin's tile endpoint instead of static GeoJSON
- [ ] Wire the mobile app's `loadSchedule`/`saveSchedule`/etc. to PostgREST instead of `localStorage`
- [ ] Wire the desktop app the same way
- [ ] Confirm both apps see the same data after that (the actual "one backend, many GUIs" test)

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
