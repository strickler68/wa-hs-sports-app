-- Roles and grants for PostgREST.
-- Run this AFTER schema.sql and seed_data.sql.
--
-- PostgREST turns each of these roles into a permission level, selected
-- by which auth token (if any) a request carries. Two roles for now,
-- matching the passcode-gate spirit of the prototype — tighten this
-- later with real per-user roles once Supabase/JWT auth is in place.

-- Anonymous / public: read-only. This is what powers the map and the
-- "browse schools and scores" experience for anyone, no login needed.
CREATE ROLE web_anon NOLOGIN;
GRANT USAGE ON SCHEMA public TO web_anon;
GRANT SELECT ON
    leagues, schools, school_league_memberships, teams,
    games, game_scoring_events, content_links
    TO web_anon;

-- Editor: anyone who's passed the passcode gate (or, later, a logged-in
-- coach/AD/fan). Can create and update schedule entries, log live scoring
-- events, and add content links — but not touch the school/league
-- reference data, which stays admin-only.
CREATE ROLE web_editor NOLOGIN;
GRANT web_anon TO web_editor;  -- editors can also read everything web_anon can
GRANT INSERT, UPDATE ON games, game_scoring_events, content_links, game_reports, sources TO web_editor;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO web_editor;

-- PostgREST needs one more role: the "authenticator" it actually connects
-- as, which switches into web_anon or web_editor per-request based on the
-- JWT it's given (or web_anon by default with no token). Set a real
-- password before using this anywhere but local dev.
CREATE ROLE authenticator NOINHERIT LOGIN PASSWORD 'change_me_before_deploying';
GRANT web_anon TO authenticator;
GRANT web_editor TO authenticator;
