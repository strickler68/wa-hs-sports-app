-- WA High School Sports Tracker — PostGIS schema
-- Prototype scope: KingCo, NPSL, SPSL leagues

CREATE EXTENSION IF NOT EXISTS postgis;

-- ---------------------------------------------------------------------
-- Leagues (versioned by season, since WIAA realigns every 4 years)
-- ---------------------------------------------------------------------
CREATE TABLE leagues (
    id              SERIAL PRIMARY KEY,
    name            TEXT NOT NULL,              -- e.g. 'KingCo', 'North Puget Sound', 'South Puget Sound'
    short_code      TEXT NOT NULL,               -- 'KINGCO', 'NPSL', 'SPSL'
    classification  TEXT,                        -- '4A', '3A', '2A' etc, nullable if mixed
    division        TEXT,                        -- 'North', 'South', 'KingCo 2A', null if n/a
    wiaa_district   INT,                         -- WIAA administrative district number (e.g. 2 for SeaKing, 3 for Pierce/South King)
    season_start    INT NOT NULL,                -- e.g. 2024 (WIAA cycle start year)
    season_end      INT NOT NULL,                -- e.g. 2028
    UNIQUE (short_code, division, season_start)
);

-- ---------------------------------------------------------------------
-- Schools
-- ---------------------------------------------------------------------
CREATE TABLE schools (
    id              SERIAL PRIMARY KEY,
    name            TEXT NOT NULL,
    nces_id         TEXT UNIQUE,                 -- NCES school ID, authoritative join key for geocoding
    district        TEXT,                        -- school district name
    city            TEXT,
    county          TEXT,
    address         TEXT,
    state           TEXT DEFAULT 'WA',
    zip             TEXT,
    website         TEXT,
    mascot          TEXT,
    geom            GEOGRAPHY(POINT, 4326),       -- filled in by enrich_from_nces.py
    created_at      TIMESTAMPTZ DEFAULT now(),
    updated_at      TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_schools_geom ON schools USING GIST (geom);

-- ---------------------------------------------------------------------
-- School <-> League membership, versioned by season
-- (a school's league can change between WIAA cycles; keep history)
-- ---------------------------------------------------------------------
CREATE TABLE school_league_memberships (
    id              SERIAL PRIMARY KEY,
    school_id       INT NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    league_id       INT NOT NULL REFERENCES leagues(id) ON DELETE CASCADE,
    classification  TEXT,                        -- this school's classification within the league (may differ, e.g. opted up)
    UNIQUE (school_id, league_id)
);

-- ---------------------------------------------------------------------
-- Teams (one per school+sport+season)
-- ---------------------------------------------------------------------
CREATE TABLE teams (
    id              SERIAL PRIMARY KEY,
    school_id       INT NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    sport           TEXT NOT NULL,                -- 'football', 'volleyball', 'boys_basketball', etc
    gender          TEXT,                         -- 'boys', 'girls', 'coed'
    season_year     INT NOT NULL,                 -- e.g. 2026 (the fall/school year this team plays)
    UNIQUE (school_id, sport, gender, season_year)
);

-- ---------------------------------------------------------------------
-- Games
-- ---------------------------------------------------------------------
CREATE TABLE games (
    id              SERIAL PRIMARY KEY,
    sport           TEXT NOT NULL,
    home_team_id    INT REFERENCES teams(id),
    away_team_id    INT REFERENCES teams(id),
    game_date       DATE NOT NULL,
    game_time       TIME,
    venue           TEXT,
    venue_geom      GEOGRAPHY(POINT, 4326),
    score_home      INT,
    score_away      INT,
    status          TEXT NOT NULL DEFAULT 'scheduled',  -- 'scheduled', 'live', 'final', 'postponed', 'cancelled'
    confidence      TEXT NOT NULL DEFAULT 'unverified',  -- 'unverified', 'single_source', 'confirmed'
    created_at      TIMESTAMPTZ DEFAULT now(),
    updated_at      TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_games_date ON games (game_date);
CREATE INDEX idx_games_status ON games (status);

-- ---------------------------------------------------------------------
-- Sources — every score/report is tied back to who reported it
-- ---------------------------------------------------------------------
CREATE TABLE sources (
    id              SERIAL PRIMARY KEY,
    source_type     TEXT NOT NULL,                -- 'coach', 'ad', 'student_stringer', 'fan', 'x_mention', 'scrape', 'manual'
    school_id       INT REFERENCES schools(id),
    display_name    TEXT,                         -- e.g. handle or contact name
    contact_info    TEXT,
    trust_score     NUMERIC DEFAULT 0.5,           -- 0..1, adjusted over time based on accuracy
    created_at      TIMESTAMPTZ DEFAULT now()
);

-- ---------------------------------------------------------------------
-- Game scoring events — the live "who scored, when" log. A game's
-- current score is always its most recent event's score_home/score_away
-- (or the games row directly, for a final score entered without a
-- period-by-period log — e.g. a coach filling in a final score after
-- the fact rather than live).
-- ---------------------------------------------------------------------
CREATE TABLE game_scoring_events (
    id              SERIAL PRIMARY KEY,
    game_id         INT NOT NULL REFERENCES games(id) ON DELETE CASCADE,
    period          TEXT,                          -- free text: '2nd Quarter', '1st Half', 'OT' — varies by sport
    game_clock      TEXT,                           -- free text, e.g. '7:42' remaining
    scoring_team    TEXT NOT NULL,                  -- 'home' | 'away'
    scorer_name     TEXT,                           -- optional
    assisted_by     TEXT,                           -- optional, comma-separated if more than one
    play_description TEXT,                          -- optional, e.g. 'field goal', 'penalty kick'
    score_home      INT NOT NULL,                   -- running score after this event
    score_away      INT NOT NULL,
    source_id       INT REFERENCES sources(id),
    reported_at     TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_scoring_events_game ON game_scoring_events (game_id, reported_at);

-- ---------------------------------------------------------------------
-- Game reports — raw submissions, before/alongside being reconciled
-- into the canonical `games` row. Keeps the audit trail.
-- ---------------------------------------------------------------------
CREATE TABLE game_reports (
    id              SERIAL PRIMARY KEY,
    game_id         INT REFERENCES games(id),      -- nullable until matched to a canonical game
    source_id       INT NOT NULL REFERENCES sources(id),
    raw_text        TEXT,                          -- original tweet/form text, for auditability
    parsed_home     TEXT,
    parsed_away     TEXT,
    parsed_score_home INT,
    parsed_score_away INT,
    parsed_sport    TEXT,
    parsed_date     DATE,
    reported_at     TIMESTAMPTZ DEFAULT now(),
    matched         BOOLEAN DEFAULT FALSE
);

-- ---------------------------------------------------------------------
-- Content links — news/substack/blog posts about a school's sports
-- ---------------------------------------------------------------------
CREATE TABLE content_links (
    id              SERIAL PRIMARY KEY,
    school_id       INT REFERENCES schools(id),
    team_id         INT REFERENCES teams(id),
    game_id         INT REFERENCES games(id),
    url             TEXT NOT NULL,
    title           TEXT,
    source_name     TEXT,                          -- 'Seattle Times', someone's Substack, etc
    published_at    TIMESTAMPTZ,
    fetched_at      TIMESTAMPTZ DEFAULT now()
);
