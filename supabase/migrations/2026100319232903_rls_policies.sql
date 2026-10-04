-- RLS policies — needed because Supabase enables Row Level Security by
-- default, which blocks ALL access (even to web_anon/anon) until policies
-- explicitly allow it. The GRANTs in the previous migration are necessary
-- but not sufficient on Supabase; this is the other half.
--
-- Same permission split as before: public read on everything, writes
-- restricted to `authenticated` (same "not real security yet" caveat —
-- any logged-in Supabase user can write, there's no per-role distinction
-- like coach/AD/fan/admin yet, see ROADMAP.md "Auth" section).

ALTER TABLE leagues ENABLE ROW LEVEL SECURITY;
ALTER TABLE schools ENABLE ROW LEVEL SECURITY;
ALTER TABLE school_league_memberships ENABLE ROW LEVEL SECURITY;
ALTER TABLE teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE games ENABLE ROW LEVEL SECURITY;
ALTER TABLE sources ENABLE ROW LEVEL SECURITY;
ALTER TABLE game_scoring_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE game_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE content_links ENABLE ROW LEVEL SECURITY;

-- Public read on everything (powers the map / browse experience, no login)
CREATE POLICY "public read" ON leagues FOR SELECT USING (true);
CREATE POLICY "public read" ON schools FOR SELECT USING (true);
CREATE POLICY "public read" ON school_league_memberships FOR SELECT USING (true);
CREATE POLICY "public read" ON teams FOR SELECT USING (true);
CREATE POLICY "public read" ON games FOR SELECT USING (true);
CREATE POLICY "public read" ON game_scoring_events FOR SELECT USING (true);
CREATE POLICY "public read" ON content_links FOR SELECT USING (true);

-- Writes restricted to logged-in users (anyone past the Supabase Auth
-- login, once that's wired up — today, nothing calls this with a user
-- session yet, so in practice writes still only happen via the
-- passcode-gated prototype calling with the anon key, which this does
-- NOT grant insert/update to on purpose)
CREATE POLICY "authenticated insert" ON games FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "authenticated update" ON games FOR UPDATE TO authenticated USING (true);
CREATE POLICY "authenticated insert" ON game_scoring_events FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "authenticated insert" ON content_links FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "authenticated insert" ON game_reports FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "authenticated insert" ON sources FOR INSERT TO authenticated WITH CHECK (true);
