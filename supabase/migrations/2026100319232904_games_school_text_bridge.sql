-- Bridge columns — lets the prototype frontend write games directly by
-- school NAME, without first resolving every school/sport/season combo
-- into a `teams` row via home_team_id/away_team_id.
--
-- This is a deliberate, documented simplification, not an oversight: the
-- frontend prototypes (public/mobile, public/desktop) already model a
-- game as "school X vs opponent Y", not "team A vs team B" — rebuilding
-- that UI around team IDs is real work (see ROADMAP.md) and isn't worth
-- blocking on before the frontends can talk to a real backend at all.
-- home_team_id/away_team_id stay in the schema, nullable, for when that
-- normalization happens later; nothing here removes them.

ALTER TABLE games ADD COLUMN IF NOT EXISTS home_school TEXT;
ALTER TABLE games ADD COLUMN IF NOT EXISTS away_school TEXT;

CREATE INDEX IF NOT EXISTS idx_games_home_school ON games (home_school);
