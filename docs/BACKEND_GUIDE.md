# Backend guide — for maintaining this without an AI assistant

Written 2026-10-04, after the backend and both frontends were first
wired together, specifically so you can keep this running if Claude
isn't available. Assumes no prior Supabase/Postgres experience, but
you're comfortable with code and SQL-adjacent thinking.

## The one-paragraph mental model

There is no server you run or deploy. "The backend" is **Supabase** — a
company that hosts a real Postgres database for you and automatically
turns every table into a web API. You (or a past session) wrote SQL
files describing tables; Supabase turned those into URLs like
`https://ezjimaeotjfwnjxofhbd.supabase.co/rest/v1/games` that return
JSON. Both frontend apps (`public/mobile/index.html`,
`public/desktop/index.html`) are just HTML/JS that call those URLs with
plain `fetch()`. If Supabase is up, the backend is up. There's nothing
else to restart, host, or patch.

## Where the real controls are

Everything below happens at **supabase.com**, logged into your account,
inside **"strickler68's Project"**.

- **Table Editor** (left sidebar) — a spreadsheet-like view of every
  table. Good for: eyeballing data, fixing one bad row by hand (a wrong
  score, a typo'd school name), deleting a test game you created.
- **SQL Editor** — a box where you can type and run any SQL directly
  against the live database. This is how every schema change so far
  was actually applied — paste, click Run.
- **Project Settings → API** — this is where the project URL and the
  **anon key** live. The anon key is *not* a secret — it's a public,
  read-restricted-by-policy key, deliberately visible in both apps'
  JavaScript (search `SUPABASE_ANON_KEY` in either `index.html`). Never
  put the `service_role`/`secret` key in the frontend code — that one
  bypasses all the access rules below and should stay inside Supabase's
  dashboard only.
- **Project Settings → Database → Connection info** — if you ever need
  to connect a desktop SQL tool (e.g. TablePlus, pgAdmin) directly
  instead of using the web SQL Editor.

## The data model, in plain terms

Six tables that matter day to day (two more — `game_reports`,
`sources` — exist for future provenance-tracking and aren't used by
either app yet):

| Table | What it holds | Who writes to it |
|---|---|---|
| `leagues` | KingCo/NPSL/SPSL/Metro, with classification/division/WIAA district | Nobody — loaded once, static |
| `schools` | The 72 verified schools, name/district/city/coordinates | Nobody — loaded once, static |
| `school_league_memberships` | Which school is in which league | Nobody — loaded once, static |
| `teams` | One row per school+sport+season — **not currently used by either app** (see below) | Nobody yet |
| `games` | One row per scheduled/live/final game | **Both apps**, constantly |
| `game_scoring_events` | One row per score update during a live game (who scored, running score) | **Both apps**, during live games |
| `content_links` | News/article links per school | Both apps (but still saved to the browser only, not Supabase yet — see ROADMAP.md) |

**The one wrinkle worth understanding — the "bridge columns":**
`games` has both a normalized `home_team_id`/`away_team_id` (pointing
at the `teams` table) *and* two plain text columns, `home_school` /
`away_school`. The apps only ever use the text columns — they write
`"Federal Way"` directly as a string, not a team ID. This was a
deliberate shortcut (see
`supabase/migrations/2026100319232904_games_school_text_bridge.sql`) to
avoid rebuilding the frontend's "School X vs opponent Y" UI around
proper team IDs before anything else could work. It means:
- You can safely ignore the `teams` table for now — it's unused.
- School names typed into the "Opponent" field are freeform text, not
  validated against the `schools` list. A typo there just creates an
  opponent name that won't match anything on the map. Not dangerous,
  just worth knowing if a game "disappears" from a school's detail
  panel — check for a name mismatch first.

## How the apps actually talk to it

Inside each `index.html`'s `<script>`, near the top of the Supabase
section:
```js
const SUPABASE_URL = 'https://ezjimaeotjfwnjxofhbd.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_...';
async function sb(path, options) { /* fetch wrapper */ }
```
Every read/write is just `sb('games?select=*...')` or
`sb('games', {method: 'POST', body: ...})`. If you ever needed to point
the apps at a *different* Supabase project (e.g. you spun up a fresh
one), these two constants in both files are the only things to change.

## RLS (Row Level Security) — the thing most likely to confuse you later

This is the single most non-obvious piece of Supabase, and the thing
most likely to make it look like "the backend is broken" when it isn't.

Supabase turns on Row Level Security on every table by default, which
means **zero access, not even reads, until you write a policy saying
who can do what.** Granting permissions the normal Postgres way (`GRANT
SELECT...`) is necessary but *not sufficient* — RLS sits on top and
blocks everything until a matching `CREATE POLICY` exists.

Two migrations hold all the policies:
- `2026100319232903_rls_policies.sql` — public read on everything
  (powers the map), plus write access for a hypothetical logged-in
  `authenticated` role (which nothing actually uses yet)
- `2026100319232905_anon_write_policies_stopgap.sql` — the one that
  actually matters today: since there's no real login, every request
  from the live app runs as the `anon` role, authenticated by nothing
  but the in-browser passcode prompt. This migration is what lets
  `anon` actually write to `games`/`game_scoring_events`/etc. **If this
  ever gets dropped or "cleaned up" without replacing it with real
  auth, every write from both apps will start failing.**

**Symptom to recognize:** if the Table Editor shows data is there, but
the live app shows nothing, or a write seems to silently do nothing —
check RLS policies first (Supabase dashboard → Authentication →
Policies, per table) before assuming the frontend code broke.

## Making a backend change yourself

1. Write the SQL (add a column, add a policy, whatever).
2. Run it in Supabase's SQL Editor against the live database — this
   takes effect immediately.
3. Also save it as a new numbered file in `supabase/migrations/`
   (follow the existing naming: a timestamp prefix, a short
   description) and commit it to git. **This step is what makes the
   change durable and documented** — step 2 alone changes the live
   database but leaves no record in the repo of what changed or why.
4. If the frontend needs to use the new column/table, edit the
   relevant `sb(...)` calls in `public/mobile/index.html` and
   `public/desktop/index.html` (keep both in sync — they're separate
   files, nothing auto-syncs them).

If Supabase's project ever needs to be rebuilt from scratch (new
account, disaster recovery), running every file in `supabase/migrations/`
**in filename order** against a fresh Supabase project recreates the
whole schema, policies, and seed data.

## Costs / limits to keep an eye on

Supabase's free tier (what this runs on) has no hard spending risk —
it's genuinely free up to usage limits (database size, API requests,
auth users), not a card-on-file-that-can-be-charged situation. If the
project ever gets paused for inactivity (free-tier projects can pause
after a week with zero traffic) or limits get close, the dashboard's
home page shows usage and will prompt you — nothing happens silently.

## Where this fits with the rest of the project's docs

- `docs/ROADMAP.md` — current status/checklist
- `docs/WORKFLOW.md` — how backlog/issues are tracked
- `docs/HANDOFF.md` / `docs/CHATGPT_HANDOFF.md` — fuller original
  architecture reasoning and data-model decisions
- **This file** — specifically "how do I keep the lights on without
  help," the piece those didn't cover directly
