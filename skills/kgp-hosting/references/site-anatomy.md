# Anatomy of a KGP-hosted site

## In the site repo

| File | Purpose |
|---|---|
| `kgp.toml` | Links the repo to a site: `site`, optional `instance`, `spa`, `[build] command` / `publish`, optional `[verify]`, `[headers]`, `[functions] dir`, and `[[redirects]]`. No secrets. |
| `functions/` | PHP functions served under `/api/` (see [functions.md](functions.md)). Not part of the build output. |
| `.env.kgp-dev` | Local env for `kgp dev`. Never committed, never uploaded. |
| `AGENTS.md`, `CLAUDE.md` | Contain a "KGP Hosting" section between `BEGIN KGP HOSTING` and `END KGP HOSTING` markers, managed by `kgp link`. Do not edit inside the markers. |
| build output (`dist/` by default) | What gets deployed. Static files only. `_redirects` and `_headers` at its root are compiled into the rules and not served. |

## What a deploy does

1. Runs the build command (output goes to stderr).
2. Hashes every file in the publish folder (SHA-256). Leaves out `.DS_Store`, `.git`, `.htaccess`, PHP files, and the root `_redirects` / `_headers`. Hashes `functions/` separately and runs `php -l` on each function when PHP is installed.
3. Asks the agent which hashes it does not have, uploads only those, and assembles an immutable release. Functions land in the release's private `.kgp-fn/` folder. The agent refuses the deploy if a static file contains a runtime env value.
4. With `--prod`: publishes the release by swapping the site's rewrite file, then requests the site and checks the status, the `X-KGP-Release` header, and the security headers.

## Releases

- Release ids are 26-character, time-sortable ids. The live release's id is in the `X-KGP-Release` response header.
- The agent keeps the newest 10 releases plus the live, previous, and pinned ones.
- Rollback publishes an older release; it takes seconds because nothing is uploaded.

## Routing rules

In order, first match wins:

1. Requests for any other host get 404. With a primary custom domain, the site's other addresses 301 to it.
2. Forced redirects (`force = true`, or `302!` in `_redirects`).
3. `/api/*` runs the release's functions (404 when the release has none).
4. A file in the release is served as is. A folder serves its `index.html` (`/about` serves `about/index.html`).
5. Other redirects (only when no file matched).
6. An asset from the previous release (for pages loaded just before a publish), then the SPA fallback, then 404.

Details:

- Env vars are not part of a release: rolling back keeps today's values.
- With `spa = true`, a path without a file extension serves the root `index.html`.
- A missing file with an extension returns 404, using the release's own `404.html` when present.
- Files under `/assets/` are cached for a year (`immutable`), so give them content-hashed names. Everything else revalidates on every request.
