# PostgREST API examples

Once `postgrest postgrest.conf` is running, every table in `schema.sql`
is a REST endpoint at `http://localhost:3000/<table>` — no backend code
written for any of this; PostgREST reads the schema and generates it.

## Read (works immediately, no auth — this is web_anon)

```bash
# All schools
curl http://localhost:3000/schools

# One school by name
curl "http://localhost:3000/schools?name=eq.Federal%20Way%20High%20School"

# All games for a school, joined to the school name (PostgREST follows
# foreign keys automatically when you ask for it)
curl "http://localhost:3000/games?select=*,home_team:teams!home_team_id(school_id)"

# Games happening today
curl "http://localhost:3000/games?game_date=eq.2026-09-20"

# Every scoring event for one game, oldest first
curl "http://localhost:3000/game_scoring_events?game_id=eq.1&order=reported_at.asc"
```

## Write (needs the web_editor role — see "Local testing" below until real auth exists)

**Add a scheduled game** (the "Schedule" tab's equivalent):
```bash
curl -X POST http://localhost:3000/games \
  -H "Content-Type: application/json" \
  -d '{
    "sport": "Football",
    "home_team_id": 12,
    "away_team_id": 45,
    "game_date": "2026-10-03",
    "game_time": "19:00",
    "venue": "Stadium Bowl, Tacoma",
    "status": "scheduled"
  }'
```

**Log a live scoring event** (the "Live update" tab's equivalent):
```bash
curl -X POST http://localhost:3000/game_scoring_events \
  -H "Content-Type: application/json" \
  -d '{
    "game_id": 1,
    "period": "3rd Quarter",
    "scoring_team": "home",
    "scorer_name": "Jordan Smith",
    "assisted_by": "Riley Chen",
    "play_description": "Corner kick crossed for a header near post",
    "score_home": 2,
    "score_away": 1
  }'
```

**Edit a scheduled game that was entered wrong** (PATCH, not POST):
```bash
curl -X PATCH "http://localhost:3000/games?id=eq.1" \
  -H "Content-Type: application/json" \
  -d '{"game_time": "18:30", "venue": "Corrected venue name"}'
```

**Add a content link:**
```bash
curl -X POST http://localhost:3000/content_links \
  -H "Content-Type: application/json" \
  -d '{
    "school_id": 12,
    "url": "https://example.com/article",
    "title": "Federal Way clinches league title",
    "source_name": "Seattle Times"
  }'
```

## Local testing before real auth exists

Until `jwt-secret` is configured and something actually issues tokens
(Supabase, or a login flow you build), every request runs as `web_anon`
— read-only, per `db_roles_and_grants.sql`. To test writes locally
before that's built, temporarily grant `web_anon` the same write
permissions as `web_editor`:

```sql
GRANT INSERT, UPDATE ON games, game_scoring_events, content_links TO web_anon;
```

**Revoke that before this is ever exposed to the internet** — it's a
local-dev convenience only, not a real permission model. Real auth is
the actual fix, not a permanent workaround.

## Geometry columns

`schools.geom` and `games.venue_geom` are PostGIS `geography` columns.
By default PostgREST returns these as raw WKB hex, not GeoJSON — the
reliable way to get GeoJSON out is to wrap the column with
`ST_AsGeoJSON()`, either in the query directly:
```bash
curl "http://localhost:3000/schools?select=name,geom_json:geom::json"
```
or, better, create a view that does this once so every frontend query
against it just gets clean GeoJSON without repeating the cast:
```sql
CREATE VIEW schools_geojson AS
SELECT id, name, district, city, county,
       ST_AsGeoJSON(geom)::json AS geom
FROM schools;

GRANT SELECT ON schools_geojson TO web_anon;
```
Then `GET /schools_geojson` returns something MapLibre can consume as a
GeoJSON source with no conversion step in the frontend at all.

## Where each frontend plugs in

- **Map (both mobile and desktop apps)**: `GET /schools`, `GET /games`
  filtered to today or upcoming, `GET /content_links` filtered by school.
- **Schedule tab**: `POST /games` to add, `PATCH /games?id=eq.N` to edit.
- **Live update tab**: `POST /game_scoring_events`, then `PATCH
  /games?id=eq.N` to update the game's own `score_home`/`score_away`/
  `status` fields to match the latest event (PostgREST doesn't do this
  automatically — either the frontend does both calls, or add a Postgres
  trigger on `game_scoring_events` that updates `games` itself, which is
  the more robust option once this is real).
- **Content link tab**: `POST /content_links`.
