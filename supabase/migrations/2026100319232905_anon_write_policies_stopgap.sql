-- Anon write policies — STOPGAP, matching the passcode-gate security
-- level this project has deliberately chosen (see CLAUDE.md: "just
-- enough to keep our shenanigans," not real security yet).
--
-- The frontend has no real Supabase Auth login flow — every request it
-- makes runs as the `anon` role, authenticated only by the passcode
-- prompt in the UI itself (which anyone can bypass via browser devtools;
-- it was never meant to stop that). Migration 3's policies only granted
-- INSERT/UPDATE to `authenticated`, which would make every write from
-- the live app fail silently against RLS, since no login ever happens.
-- This migration grants the same writes to `anon` too, so the app
-- actually works today.
--
-- REVISIT THIS before treating the site as real-security: once Supabase
-- Auth is wired up (ROADMAP.md, "Auth" section), these anon policies
-- should be dropped so only logged-in coach/AD/fan/admin roles can write.

CREATE POLICY "anon insert (stopgap)" ON games FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "anon update (stopgap)" ON games FOR UPDATE TO anon USING (true);
CREATE POLICY "anon insert (stopgap)" ON game_scoring_events FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "anon insert (stopgap)" ON content_links FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "anon insert (stopgap)" ON game_reports FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "anon insert (stopgap)" ON sources FOR INSERT TO anon WITH CHECK (true);
