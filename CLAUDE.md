# Start-of-session SOP — read this first

This file is read automatically at the start of any Claude Code session
working in this directory. Follow these steps before doing anything else,
and before telling the user what state the project is in.

## 1. Confirm what's actually here

This container is ephemeral — nothing persists between sessions unless
it's in this git repo (or has been pushed to GitHub/Supabase/Cloudflare).
Don't assume a database, running server, or installed tool from a past
session still exists. Check:

```bash
pwd && ls -la
git -C . log --oneline -10 2>/dev/null
```

If this directory is empty or missing, the repo may need to be cloned
fresh from GitHub (once the user has pushed it — see `DEPLOY.md`), or the
user hasn't attached it yet. Say so plainly rather than fabricating
project state from memory.

## 2. Read, in this order

1. **`docs/ROADMAP.md`** — the living checklist. This is the single
   source of truth for what's done vs. not done. Trust its checkboxes
   over anything you recall from a prior conversation.
2. **The most recent `docs/EOD_*.md`** (sort by date in the filename,
   read the latest one) — last session's end-of-day summary: what
   happened, what's explicitly NOT done, and the recommended next step.
3. **`docs/HANDOFF.md`** and **`docs/CHATGPT_HANDOFF.md`** only if you
   need the fuller project history/architecture reasoning — these are
   stable background, not where day-to-day status lives.
4. **`DEPLOY.md`** only if the task involves hosting/deployment.
5. **`docs/BACKEND_GUIDE.md`** whenever the task touches Supabase, RLS,
   the schema, or anything the user would need to maintain solo —
   written specifically so the user isn't dependent on an AI session to
   keep this running.
6. **`docs/WORKFLOW.md`** whenever the task involves picking what to work
   on next, adding a new feature idea, or anything backlog/sprint/issue
   related — GitHub Issues + a Project board is the real backlog now,
   not a flat checklist. `ROADMAP.md` stays for high-level status/history
   only.

## 3. If picking up backend work (local Postgres/PostgREST)

Nothing about a locally-run database or PostgREST process survives
between sessions in this sandbox. If the task needs them running again:
```bash
sudo service postgresql start
# then re-check whether `wahsports` DB / PostgREST are already up before
# reloading schema/seed — don't blindly re-run migrations against data
# that's already there
```
If the user has since set up the real Supabase project (check
`docs/ROADMAP.md`'s "Public deployment" section), prefer pointing new
work at that instead of rebuilding a local throwaway copy.

## 4. End of session

Before wrapping up a working session, update `docs/ROADMAP.md`'s
checkboxes to reflect reality, and write a new `docs/EOD_<date>.md` (same
format as existing ones) summarizing what happened, what's still open,
and the recommended next step — this file's whole point is making that
handoff unnecessary to ask for.

## Quality bar for the end product

This is not just a working prototype — the user has explicitly said the
finished app needs to be **highly functional, highly user-friendly, and
has to look really good**. Keep this in mind on every UI/UX change, not
just backend plumbing:
- Don't ship something that merely works if a noticeably better version
  is a reasonable amount of extra effort — polish matters here, it's not
  a "fix it later" item.
- When touching `public/mobile/index.html` or `public/desktop/index.html`,
  look at the surrounding design (spacing, color, interaction feedback —
  see the KingCo/NPSL/SPSL/Metro color system already established) and
  match or improve it, not just bolt on functional-but-ugly markup.
- Loading states, error states, and empty states all count as part of
  "highly functional" — a blank screen or a silent failure while waiting
  on a Supabase call is not acceptable without feedback to the user.
- If a tradeoff has to be made under time/credit pressure, say so
  explicitly rather than quietly shipping the rougher version — this
  matches the project's existing pattern of flagging simplifications
  (e.g. the `home_school`/`away_school` text-bridge columns) instead of
  hiding them.

## House rules for this project (don't re-litigate without a reason)

- **Target audience is crowdsourced, not coaches/ADs.** The people entering
  schedules and live scores are fans, students, and parents at the game —
  not official athletic department staff. Don't drift into
  "coach/AD self-report" framing in UI copy, docs, or feature design;
  earlier drafts used that language before this was clarified
  (2026-10-04) and it's since been corrected in the app taglines.
- Open-source stack, zero ArcGIS licensing — see `docs/TECH_STACK.md`.
- Security is intentionally minimal right now (passcode-gate stopgap,
  not real auth) — the user's own words: "just enough to keep our
  shenanigans," not a request for real security yet.
- Project management is this `ROADMAP.md`, not Trello — deliberately.
- School coordinates come from WA OSPI, not NCES (superseded).
- 72-school dataset is already verified against official league sources
  — don't casually re-verify or second-guess it (see `docs/HANDOFF.md`
  §5 for how, if it ever needs redoing).
