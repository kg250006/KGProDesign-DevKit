# Anatomy of a KGP-hosted site

## In the site repo

| File | Purpose |
|---|---|
| `kgp.toml` | Links the repo to a site: `site`, optional `instance`, `spa`, `[build] command` / `publish`, optional `[verify]` and `[headers]`. No secrets. |
| `AGENTS.md`, `CLAUDE.md` | Contain a "KGP Hosting" section between `BEGIN KGP HOSTING` and `END KGP HOSTING` markers, managed by `kgp link`. Do not edit inside the markers. |
| build output (`dist/` by default) | What gets deployed. Static files only. |

## What a deploy does

1. Runs the build command (output goes to stderr).
2. Hashes every file in the publish folder (SHA-256). Leaves out `.DS_Store`, `.git`, `.htaccess`, and PHP files.
3. Asks the agent which hashes it does not have, uploads only those, and assembles an immutable release.
4. With `--prod`: publishes the release by swapping the site's rewrite file, then requests the site and checks the status, the `X-KGP-Release` header, and the security headers.

## Releases

- Release ids are 26-character, time-sortable ids. The live release's id is in the `X-KGP-Release` response header.
- The agent keeps the newest 10 releases plus the live, previous, and pinned ones.
- Rollback publishes an older release; it takes seconds because nothing is uploaded.

## Routing rules

- A file in the release is served as is. A folder serves its `index.html` (`/about` serves `about/index.html`).
- With `spa = true`, a path without a file extension serves the root `index.html`.
- A missing file with an extension returns 404, using the release's own `404.html` when present.
- Files under `/assets/` are cached for a year (`immutable`), so give them content-hashed names. Everything else revalidates on every request.
