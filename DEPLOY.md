# Deploying this project for ~$1/mo (just the domain)

Stack: **Supabase** (free — database + API) + **Cloudflare Pages** (free —
hosts the two HTML apps) + **Cloudflare Registrar** (~$10-12/yr — the
domain, the only real cost). See `docs/TECH_STACK.md` for the underlying
architecture reasoning; this file is just the deploy steps for it.

None of these steps can be done from here — they all need your own login
and payment method. Do them in this order:

## 1. Buy the domain (Cloudflare Registrar)

1. Sign up / log in at `dash.cloudflare.com`
2. "Domain Registration" → search for the name you want → buy it
   (Cloudflare sells at wholesale cost, no markup — this is usually
   cheaper than GoDaddy/Namecheap for the same name)
3. DNS for it is now hosted on Cloudflare automatically — nothing else to
   configure yet, Pages setup below will add the records it needs.

## 2. Create the Supabase project (free tier)

1. Sign up / log in at `supabase.com` → "New project"
2. Pick a region close to WA (e.g. `us-west-1`) and set a strong database
   password — **save it somewhere**, it's the actual Postgres root
   password, separate from anything in this repo.
3. Once the project is up: **SQL Editor** → run each file in
   `supabase/migrations/` **in filename order** (they're numbered):
   1. `..._schema.sql`
   2. `..._seed_data.sql`
   3. `..._roles_and_grants.sql` (the Supabase-adapted version — see the
      comment at the top of that file for why it differs from
      `sql/db_roles_and_grants.sql`)
4. **Settings → API**: copy the "Project URL" and the `anon` public key —
   these replace `http://localhost:3000` in the two frontend files (see
   step 4 below).
5. Quick check it worked: **Table Editor** → `schools` should show 72
   rows. If it shows 0 despite the migrations running with no errors,
   read the RLS note at the bottom of the `roles_and_grants` migration
   file — Row Level Security is almost certainly the cause.

## 3. Push this repo to GitHub

Cloudflare Pages deploys from a GitHub repo, so this folder needs to be
one:
```bash
cd wa-hs-sports
git init
git add .
git commit -m "Initial commit: WA HS Sports Tracker"
# create a new repo on github.com first, then:
git remote add origin <your-new-repo-url>
git branch -M main
git push -u origin main
```

## 4. Point the frontend at the real backend

In both `public/mobile/index.html` and `public/desktop/index.html`, every
`loadSchedule`/`saveSchedule`/etc. function currently reads/writes
`localStorage`. Before (or right after) deploying, these need to become
`fetch()` calls against your Supabase URL from step 2, using the
`apikey` header set to your `anon` key — see `config/postgrest_examples.md`
for the exact request shapes (Supabase accepts the same PostgREST-style
query syntax, since that's what it runs underneath). **This rewiring
hasn't been done yet** — it's the next real piece of work, tracked in
`docs/ROADMAP.md`.

## 5. Deploy to Cloudflare Pages

1. In the Cloudflare dashboard: **Workers & Pages → Create → Pages →
   Connect to Git** → pick the repo from step 3
2. Build settings: **no build command**, **build output directory =
   `public`** (this repo's static files are already pre-built, there's no
   compile step)
3. Deploy. Cloudflare gives you a free `*.pages.dev` URL immediately.
4. **Custom domains** tab → add the domain from step 1 → follow its
   one-click DNS instructions (since the domain is already on Cloudflare,
   this is usually automatic, no manual DNS records needed)

## After this works

- Every `git push` to `main` auto-redeploys the site (Cloudflare Pages
  watches the repo).
- The Supabase free project **pauses after 7 days with zero API
  traffic** — one click in the Supabase dashboard to resume. Worth
  remembering before a season opener if the project's been dormant all
  summer.
- Nothing above sets up real authentication yet — the passcode-gate
  stopgap in the HTML files still applies until the Supabase Auth work
  happens (tracked in `docs/ROADMAP.md`, "Auth" section).
