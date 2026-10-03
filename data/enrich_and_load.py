"""
Enrich schools_seed.csv with authoritative coordinates and load into PostGIS.

Source: Washington OSPI's "Washington State Public Schools" point layer —
the official, currently-active public school locations for the state,
building-centroid-corrected against aerial imagery (not just geocoded
street addresses). This is the same ArcGIS service that publishes the
school-district boundary layer used elsewhere in this project
(Schools_Explorer_Data_2024), so districts and schools come from one
consistent source.

Schools are static — this is meant to be run ONCE to seed real
coordinates, not re-synced on a schedule. Re-run it only if OSPI publishes
a new edition or you add schools to schools_seed.csv that weren't in the
original load.

Setup (one-time):
1. Find the school-points layer in the same service as the district
   boundaries — open this in a browser (not this script, which can't
   reach arbitrary hosts) to find the right layer number:
   https://services5.arcgis.com/q9Lwq3BC8p2H6RLg/ArcGIS/rest/services/Schools_Explorer_Data_2024/FeatureServer
2. Query it for a GeoJSON export (swap {N} for the layer number found above):
   https://services5.arcgis.com/q9Lwq3BC8p2H6RLg/ArcGIS/rest/services/Schools_Explorer_Data_2024/FeatureServer/{N}/query?where=1=1&outFields=*&outSR=4326&f=geojson
   Save the result as data/wa_public_schools.geojson relative to this script.
3. Set your Postgres connection string via the DATABASE_URL env var, e.g.
   export DATABASE_URL="postgresql://user:pass@localhost:5432/wahsports"
4. Run: python enrich_and_load.py

Rows in schools_seed.csv with verify_needed=TRUE are skipped for
matching and printed at the end as a checklist. Private schools generally
won't be in the OSPI layer (it's public schools only) — those still need
manual coordinates.
"""

import csv
import json
import os
import re
import sys
from pathlib import Path

try:
    import psycopg2
except ImportError:
    sys.exit("Missing dependency: pip install psycopg2-binary")

SEED_CSV = Path(__file__).parent / "schools_seed.csv"
OSPI_GEOJSON = Path(__file__).parent / "data" / "wa_public_schools.geojson"
DATABASE_URL = os.environ.get("DATABASE_URL")

# WIAA cycle these leagues belong to — update when leagues are re-verified
SEASON_START, SEASON_END = 2024, 2028

# WIAA administrative district per league, confirmed from WIAA/FinalForms records
WIAA_DISTRICT = {"KingCo": 2, "Metro": 2, "NPSL": 3, "SPSL": 3}


def normalize(name):
    s = name.lower()
    s = re.sub(r"\bhigh school\b|\bsr\.?\b|\bsenior\b", "", s)
    s = re.sub(r"[^a-z0-9]", "", s)
    return s


def load_ospi_lookup():
    """Build {normalized_name: (lat, lon)} from the OSPI GeoJSON export."""
    if not OSPI_GEOJSON.exists():
        print(f"NOTE: {OSPI_GEOJSON} not found — schools will be inserted "
              f"WITHOUT coordinates. See the setup steps in this file's "
              f"docstring to pull the OSPI layer first.")
        return {}
    with open(OSPI_GEOJSON, encoding="utf-8") as f:
        data = json.load(f)
    lookup = {}
    for feature in data.get("features", []):
        props = feature.get("properties", {})
        # Field name varies by which layer/edition you pulled — check your
        # downloaded file's properties and adjust if this doesn't match.
        name = (props.get("SchoolName") or props.get("Name") or "").strip()
        geom = feature.get("geometry") or {}
        coords = geom.get("coordinates")
        if name and coords and len(coords) == 2:
            lon, lat = coords
            lookup[normalize(name)] = (lat, lon)
    return lookup


def load_seed_rows():
    with open(SEED_CSV, newline="", encoding="utf-8") as f:
        return list(csv.DictReader(f))


def get_or_create_league(cur, name, division, classification):
    division = division or None
    district = WIAA_DISTRICT.get(name)
    cur.execute(
        """
        INSERT INTO leagues (name, short_code, classification, division, wiaa_district, season_start, season_end)
        VALUES (%s, %s, %s, %s, %s, %s, %s)
        ON CONFLICT (short_code, division, season_start) DO UPDATE SET name = EXCLUDED.name, wiaa_district = EXCLUDED.wiaa_district
        RETURNING id
        """,
        (name, name.upper().replace(" ", "_"), classification, division, district, SEASON_START, SEASON_END),
    )
    return cur.fetchone()[0]


def main():
    if not DATABASE_URL:
        sys.exit("Set DATABASE_URL env var first, e.g.\n"
                  '  export DATABASE_URL="postgresql://user:pass@localhost:5432/wahsports"')

    ospi_lookup = load_ospi_lookup()
    rows = load_seed_rows()

    needs_verification = []
    unmatched_coords = []
    conn = psycopg2.connect(DATABASE_URL)
    cur = conn.cursor()

    for row in rows:
        name = row["school_name"]
        league_name = row["league"]
        division = row["division"]
        classification = row["classification"]
        district = row["district"]
        city = row.get("city", "")
        county = row["county"]
        address = row.get("address", "")
        nces_id = row["nces_id"].strip() or None
        verify_flag = row["verify_needed"].strip().upper() == "TRUE"

        if verify_flag or league_name == "VERIFY_LEAGUE":
            needs_verification.append(name)

        coords = ospi_lookup.get(normalize(name))
        if ospi_lookup and not coords and "Private" not in district:
            unmatched_coords.append(name)

        cur.execute(
            """
            INSERT INTO schools (name, nces_id, district, city, county, address, geom)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
            ON CONFLICT (nces_id) DO UPDATE SET
                district = EXCLUDED.district,
                city = EXCLUDED.city,
                county = EXCLUDED.county,
                address = COALESCE(NULLIF(EXCLUDED.address, ''), schools.address),
                geom = COALESCE(EXCLUDED.geom, schools.geom),
                updated_at = now()
            RETURNING id
            """,
            (
                name,
                nces_id,
                district,
                city,
                county,
                address,
                f"POINT({coords[1]} {coords[0]})" if coords else None,
            ),
        )
        school_id = cur.fetchone()[0]

        if league_name and league_name != "VERIFY_LEAGUE":
            league_id = get_or_create_league(cur, league_name, division, classification)
            cur.execute(
                """
                INSERT INTO school_league_memberships (school_id, league_id, classification)
                VALUES (%s, %s, %s)
                ON CONFLICT (school_id, league_id) DO NOTHING
                """,
                (school_id, league_id, classification),
            )

    conn.commit()
    cur.close()
    conn.close()

    print(f"\nLoaded {len(rows)} schools.")
    if needs_verification:
        print(f"\n{len(needs_verification)} schools still need league verification:")
        for n in needs_verification:
            print(f"  - {n}")
    if unmatched_coords:
        print(f"\n{len(unmatched_coords)} public schools didn't match a name in the OSPI layer "
              f"(name mismatch, or check the field name this script reads):")
        for n in unmatched_coords:
            print(f"  - {n}")
        print("\nPrivate schools are expected to be unmatched — OSPI's layer covers public schools only.")


if __name__ == "__main__":
    main()
