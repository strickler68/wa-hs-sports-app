# WA High School Sports Tracker — prototype data layer

Scope: KingCo, North Puget Sound League (NPSL), South Puget Sound League (SPSL), Metro League (Seattle).

## Files

- `schema.sql` — PostGIS schema: leagues, schools, memberships (versioned by
  WIAA season), teams, games, sources, game_reports (raw submissions before
  reconciliation), content_links.
- `schools_seed.csv` — 72 schools across the four leagues, with league,
  division, classification, district, city, county, NCES ID, and street
  address (address populated for a handful of schools so far).
- `seed_data.sql` — **ready-to-run INSERT statements** for `leagues`,
  `schools`, and `school_league_memberships`, generated directly from
  `schools_seed.csv` joined with the tracker artifact's map coordinates.
  Run this against `schema.sql` and you have a fully populated, queryable
  database today. Coordinates in this file are the same city-level
  approximations used in the map — not geocoded addresses. Re-run
  `enrich_and_load.py` once you've downloaded the NCES file to replace them
  with precise ones; it upserts by NCES ID so it won't duplicate rows.
- `enrich_and_load.py` — pulls authoritative lat/lon from Washington OSPI's
  official public-schools point layer (keyed by school name) and
  loads/updates schools in Postgres with precise coordinates. Schools are
  static, so this is meant to run once, not on a schedule.

## Setup

**Fastest path — provisional data, works today:**
1. `createdb wahsports`
2. `psql wahsports -f schema.sql`
3. `psql wahsports -f seed_data.sql`

You now have 72 schools, correctly leagued, classified, and districted,
queryable with real spatial functions — just with approximate coordinates.

**To get precise coordinates (one-time, since schools don't move):**
4. Find the school-points layer in the same ArcGIS service that publishes
   WA's school-district boundaries — open this in a browser to find the
   layer number:
   https://services5.arcgis.com/q9Lwq3BC8p2H6RLg/ArcGIS/rest/services/Schools_Explorer_Data_2024/FeatureServer
5. Query that layer for GeoJSON (swap `{N}` for the layer number):
   `https://services5.arcgis.com/q9Lwq3BC8p2H6RLg/ArcGIS/rest/services/Schools_Explorer_Data_2024/FeatureServer/{N}/query?where=1=1&outFields=*&outSR=4326&f=geojson`
   Save it as `data/wa_public_schools.geojson`.
6. `pip install psycopg2-binary`
7. `export DATABASE_URL="postgresql://user:pass@localhost:5432/wahsports"`
8. `python enrich_and_load.py`

The script prints a checklist of schools still needing league verification,
plus any public schools whose name didn't match OSPI's layer (private
schools are expected to show up here — OSPI only covers public schools).

## Known gaps to close before this is demo-ready

1. **~30 schools need their NCES ID confirmed** (flagged in the CSV) — pull
   from the NCES school search by name + district.
2. **Enumclaw's league is ambiguous** — one source has it in NPSL (2016),
   another in SPSL 2A/3A more recently. Check the current WIAA league page
   directly.
3. **SPSL divisions/classifications are from a 2024 article** and could have
   shifted; same caveat for the KingCo 2A sub-division roster (Evergreen,
   Highline, Tyee, Foster).
4. **Private schools** (Kennedy Catholic) don't have a standard public-school
   NCES ID — they use a separate Private School Survey (PSS) ID; the
   enrichment script doesn't handle that yet.
5. No `games` or `teams` data yet — this is schools/leagues only. Next step
   is deciding the MVP ingestion path (coach self-report form vs. seeding a
   season's worth of historical scores for the demo).

## Next steps (pick one)

- Build the coach/AD self-report form (probably the fastest path to a live demo)
- Start the map UI against this schema (even with just markers, no scores yet)
- Nail down the ~30 unverified schools first so the seed data is solid
