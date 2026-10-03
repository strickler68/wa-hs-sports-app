# WA High School Sports Tracker — Tech Stack

Zero licensing cost anywhere in this stack. Everything below is open-source.

## The stack, layer by layer

```
┌──────────────────────┐     ┌──────────────────────┐
│  Mobile app           │     │  Desktop app          │
│  (wa_hs_sports.html)  │     │  (wa_hs_sports_        │
│                        │     │   desktop.html)        │
└──────────┬─────────────┘     └───────────┬────────────┘
           │                                │
           │  both hit the SAME two services below
           │                                │
┌──────────▼────────────────────────────────▼────────────┐
│  PostgREST — read/write REST API, auto-generated        │
│  from schema.sql (this is your ArcGIS Feature Service    │
│  equivalent: one endpoint, many GUIs)                    │
├────────────────────────────────────────────────────────┤
│  Martin or pg_tileserv — vector tiles for the map layer  │
│  (this is your ArcGIS Map Service equivalent)             │
└──────────────────────┬────────────────────────────────┘
                        │ SQL
┌──────────────────────▼────────────────────────────────┐
│  PostGIS — the database (schema.sql, seed_data.sql,     │
│  db_roles_and_grants.sql)                                │
└──────────────────────────────────────────────────────┘

  Separately: basemap tiles (the background imagery — roads,
  water, place names) come from Protomaps, not your database.
  QGIS talks directly to PostGIS for one-off GIS work (the
  WIAA-district county dissolve, boundary QA).
```

## What we already have

| Piece | File | Status |
|---|---|---|
| Database schema | `schema.sql` | Done — leagues, schools, teams, games, scoring events, sources, memberships, content links |
| Seed data | `seed_data.sql` | Done — 72 schools, real league/classification data, approximate coordinates |
| DB roles for the API | `db_roles_and_grants.sql` | New — web_anon (read) / web_editor (write) / authenticator roles for PostgREST |
| API server config | `postgrest.conf` | New — points PostgREST at the database |
| API usage examples | `postgrest_examples.md` | New — concrete curl calls for every write action both apps need |
| School coordinate enrichment | `enrich_and_load.py` | Done — sources from OSPI's public-schools layer (see README), run once |
| Mobile prototype UI | published artifact (`wa_hs_sports.html`) | Working demo — bottom nav, stacked layout, localStorage only (no shared backend yet) |
| Desktop prototype UI | published artifact (`wa_hs_sports_desktop.html`) | Working demo — sidebar nav, split-pane layout, same caveat |
| Real MapLibre + basemap demo | `maplibre_demo.html` | Run locally — shows an actual tiled basemap, which can't render inside a published artifact (sandbox restriction) |
| Project reference | `README.md` | Setup steps for the database layer |

**What's not built yet**: the actual PostgREST/Martin servers aren't running anywhere — the config files above are ready to point at a real database once you have one running locally or hosted. Until then, the two prototype apps are UI/UX exploration only, each with its own local browser storage, not yet talking to each other or to Postgres.

## What you need to install, in order

**Stage 1 — get the database real:**
1. **PostgreSQL + PostGIS** — `postgresql.org` / the `postgis` extension. Mac: `brew install postgresql postgis`. Windows: the PostgreSQL installer bundles a PostGIS option.
2. `createdb wahsports && psql wahsports -f schema.sql && psql wahsports -f seed_data.sql && psql wahsports -f db_roles_and_grants.sql`
3. **Python 3 + psycopg2** (`pip install psycopg2-binary`) if you want to run `enrich_and_load.py` for precise coordinates — see `README.md`.

**Stage 2 — get the API real (this is the ArcGIS-Feature-Service-equivalent piece):**
4. **PostgREST** — download the binary from its GitHub releases (no compiling needed, no dependencies). `postgrest postgrest.conf` and you have a REST API immediately. This is the single biggest unlock in this whole stack — try it early, it's the "oh, that's all it takes?" moment.
5. Work through `postgrest_examples.md` — every curl example in there is something one of the two frontend apps needs to eventually call for real.

**Stage 3 — get the map real:**
6. **Martin** — single binary, `cargo install martin` if you have Rust, or grab a prebuilt release. Point it at the same Postgres connection string. **Run it on a different port than PostgREST** (PostgREST defaults to 3000 in `postgrest.conf`; start Martin with `martin --listen-addresses 0.0.0.0:3001 <connection-string>` so they don't collide).
7. **QGIS** (`qgis.org`) — for the WIAA-district county dissolve, boundary QA, and loading OSPI's layers directly.
8. **Protomaps**, for basemap tiles — nothing to install for development; MapLibre's own free public demo style (`demotiles.maplibre.org`) works with zero setup. `maplibre_demo.html` already uses it.

**Stage 4 — wire the frontends to the real backend:**
9. Update the two prototype HTML files' `loadSchedule()`/`saveSchedule()` etc. (currently reading/writing `localStorage`) to instead `fetch()` against your running PostgREST endpoint. This is the step that makes "same data, two apps" actually true instead of aspirational.

## Documentation — where to actually learn each piece

Read in roughly this order; each builds on assumptions from the last.

1. **PostgreSQL** — you likely know a lot of this from DNR work already. [postgresql.org/docs](https://www.postgresql.org/docs/current/) if you need a refresher on anything specific; not worth reading cover to cover.
2. **PostGIS** — [postgis.net/documentation](https://postgis.net/documentation/) — the "geography vs geometry" page and the `ST_*` function reference are the two things worth bookmarking.
3. **PostgREST** — [postgrest.org/en/stable](https://postgrest.org/en/stable/) — read the Tutorial (their own, not a third party's) start to finish once; it's short and it's exactly the "how do I turn a table into an API" question you have right now.
4. **Martin** — [martin docs on GitHub](https://github.com/maplibre/martin) — the README alone covers most of what you need; it's a much smaller tool than PostgREST.
5. **MapLibre GL JS** — [maplibre.org/maplibre-gl-js/docs](https://maplibre.org/maplibre-gl-js/docs/) — the "Examples" section is more useful early on than the API reference; find an example close to what you're building and adapt it.
6. **QGIS** — [qgis.org/docs](https://docs.qgis.org/) has a full training manual; you probably only need specific chapters (working with web services / ArcGIS REST layers, and the dissolve/union tools) rather than the whole thing.
7. **Supabase** (optional, if you decide to use it instead of hand-rolling auth) — [supabase.com/docs](https://supabase.com/docs) — their Auth + Row Level Security guide is the relevant piece; the rest of Supabase is the same PostgREST-based stack described above, just hosted and packaged.

## Suggested learning order (hands-on)

1. **Run PostgREST against the seeded database first** — before touching Martin or the frontends, this is the fastest way to see "one API, many clients" become real: load the schema, run PostgREST, hit `http://localhost:3000/schools` in a plain browser tab, get back JSON.
2. **Try the write examples in `postgrest_examples.md`** — POST a scheduled game, PATCH it, POST a scoring event. This is the exact API surface both apps will eventually call.
3. **Run Martin second** — point it at the same database, hit its endpoint, see vector tiles come back instead of JSON.
4. **MapLibre third** — `maplibre_demo.html` already shows GeoJSON rendering; the next step is pointing it at Martin's vector tile endpoint instead of a static GeoJSON array.
5. **QGIS whenever a specific GIS task needs it** — not something to learn end to end up front; the county dissolve for WIAA districts is a good first real task once you're ready for it.

## Why not just one tool

ArcGIS bundles all of this into a single licensed product. Here, PostGIS stores and queries, PostgREST exposes it as an editable API, Martin/pg_tileserv turns it into map tiles, MapLibre draws it, and Protomaps supplies the background basemap. Each piece is independently replaceable — swap Martin for pg_tileserv without touching PostgREST or MapLibre, swap hand-rolled auth for Supabase without touching the schema — which is the tradeoff for going open-source over an all-in-one product: more pieces, but no single point of vendor lock-in or licensing cost.
