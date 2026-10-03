-- Roles and grants — SUPABASE-ADAPTED VERSION.
-- Run this AFTER schema.sql and seed_data.sql.
--
-- Supabase already creates and owns a role literally named `authenticator`
-- (it runs PostgREST internally too, same as our local setup) — so the
-- original db_roles_and_grants.sql's `CREATE ROLE authenticator ...` line
-- would collide and fail here. It's been removed. Supabase also already
-- ships two built-in roles that play the same part as our custom ones:
--   - `anon`          ~= our `web_anon`   (used for unauthenticated requests)
--   - `authenticated` ~= our `web_editor` (used once a user has a valid
--                                          Supabase Auth session/JWT)
-- So instead of creating web_anon/web_editor, this grants the same
-- permissions directly to Supabase's `anon` and `authenticated` roles.
-- The ORIGINAL db_roles_and_grants.sql in sql/ is unchanged and still the
-- correct file for a self-hosted (non-Supabase) PostgREST setup.

GRANT USAGE ON SCHEMA public TO anon, authenticated;

GRANT SELECT ON
    leagues, schools, school_league_memberships, teams,
    games, game_scoring_events, content_links
    TO anon, authenticated;

-- Writes: until real per-user roles exist (coach/AD/fan/admin — still an
-- open item, see ROADMAP.md), any authenticated Supabase user can write.
-- This is the same "just enough to keep our shenanigans down" level of
-- security as the passcode gate, not real access control yet.
GRANT INSERT, UPDATE ON games, game_scoring_events, content_links, game_reports, sources TO authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- NOTE: Supabase enables Row Level Security (RLS) by default on new
-- tables in some project configs, which would silently block all of the
-- above GRANTs from having any effect until RLS policies are also
-- written. If `GET /schools` comes back empty via Supabase's API despite
-- this migration running cleanly, that's almost certainly why — check
-- Supabase Dashboard → Authentication → Policies, and either add a
-- permissive SELECT policy per table or temporarily disable RLS on these
-- tables for local testing (same "revisit before real launch" caveat as
-- everything else in this file).
