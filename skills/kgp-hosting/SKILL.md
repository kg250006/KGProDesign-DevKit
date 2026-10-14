---
name: kgp-hosting
description: Deploys, publishes, rolls back, and diagnoses websites hosted on KGP Host (sitepage.app or a customer domain) safely through the kgp CLI. Use when the repo contains kgp.toml, when asked to deploy, publish, preview, roll back, check status, or fix a broken KGP-hosted site, or when editing build config, redirects, or headers of such a site.
---

<objective>
Deploy, publish, roll back, and diagnose a KGP-hosted static site using only the kgp CLI, without ever
publishing to production unasked, leaking a secret, or touching the server directly.
</objective>

<detection>
A site is KGP-hosted when `kgp.toml` exists in the current folder or a parent folder, up to the git root.
Read it before doing anything:

- `site`: the site name; its address is `https://SITE.PLATFORM_DOMAIN` (for example `https://acme.sitepage.app`).
- `instance`: the hosting instance, if not the machine's default.
- `[build] command` and `publish`: how the site is built and which folder is deployed.
- `spa`: when true, paths without a file extension fall back to `index.html`.

A marked "KGP Hosting" section in `AGENTS.md` or `CLAUDE.md` (written by `kgp link`) also means the repo is KGP-hosted.
</detection>

<prerequisites>
Check these before the first kgp call. Stop and tell the user what is missing instead of working around it.

1. `kgp --version` prints a version. If `kgp` is not found, the CLI is not installed. The owner installs it from
   the KGP-WebHosting-Tools repo (Node 20+ and pnpm 9 required): `pnpm install`,
   `pnpm --filter @kgp/host-cli build`, then put `packages/kgp-cli/dist/index.js` on PATH as `kgp`
   (`pnpm link --global` from `packages/kgp-cli`, which needs `pnpm setup` once, or a symlink into a PATH folder).
2. `kgp whoami --json --yes` shows an instance with `agent_secret: "present"`. If it fails with exit 3 or 7, the
   machine is not logged in. Logging in and `kgp server init` are owner tasks; do not attempt them unasked.
3. The repo has `kgp.toml`. If not, ask which site to use and run `kgp link --site SITE --json --yes` only after the user confirms.
</prerequisites>

<how_it_works>
- The build output is uploaded by content hash. Unchanged files are never uploaded again.
- Every deploy creates an immutable release. Publishing swaps one rewrite file atomically, so visitors never see a half-updated site. A page loaded just before a publish can still fetch its old assets.
- `kgp deploy` without `--prod` creates a ready but unpublished release. `--prod` publishes it and verifies the live site.
- The platform sets security headers on every response: `X-Frame-Options: DENY`, `X-Content-Type-Options: nosniff`, `Referrer-Policy: strict-origin-when-cross-origin`, `Permissions-Policy: geolocation=(), microphone=(), camera=()`, and HSTS over HTTPS. Sites can override or add headers in `kgp.toml` `[headers]`.
- `sitepage.app` is HTTPS-only (the `.app` TLD is on the HSTS preload list). Never link to `http://` addresses there.
- Each site answers only on its own host names. The same files requested through another host or path return 404.
- Customer domains point at a site through DNS records (a later milestone). Never change DNS yourself.
</how_it_works>

<quick_start>
The safe deploy workflow:

1. `kgp status --json --yes`: confirm which site and release are live.
2. Build locally with the project's build command and fix build errors before deploying.
3. `kgp deploy --json --yes`: uploads and creates a ready, unpublished release.
4. Report the release id (`deploy_id`) to the user and ask before publishing.
5. Publish only when the user asked for production: `kgp releases publish ID --json --yes`, or in one step `kgp deploy --prod --rollback-on-fail --json --yes`.
6. Read `verification` in the JSON. If it failed and `details.state` is not `rolled_back`, run `kgp rollback --json --yes` and report what failed.
</quick_start>

<guardrails>
Never:
- put secrets, tokens, or passwords in `kgp.toml` or in the build output (deploys refuse such keys);
- ship `.htaccess` or PHP files in the build output (the deploy leaves them out or refuses them);
- edit files on the server, in cPanel, or through the cPanel API directly;
- change DNS records or nameservers;
- pass a token or secret as a command-line argument (use `KGP_CPANEL_TOKEN`, `KGP_AGENT_SECRET`, or `kgp login --token-stdin`);
- run `kgp sites delete` or `kgp instance remove` without an explicit user request;
- publish to production without an explicit user request.

Always use `--json --yes` and read results from stdout only. Logs and build output go to stderr.
</guardrails>

<corporate_hardening>
The deployment-expert skill's corporate hardening pass also applies to KGP-hosted sites, with these differences:

- Headers (M2): the platform already sends the hardened set above. Add or override headers only in `kgp.toml` `[headers]`, never in an `.htaccess` file.
- HSTS (M4): the platform sends `max-age=31536000; includeSubDomains`. A `Strict-Transport-Security` value containing `preload` is refused with exit 7.
- `Cache-Control`: the platform caches `/assets/` for a year and revalidates everything else. Do not override it unless asked.
- Custom domain (M1): a `*.sitepage.app` address is a shared platform subdomain, so M1 stays blocked until custom domains ship. Record it as blocked, not as a failure to fix by hand.
</corporate_hardening>

<exit_codes>
| Code | Meaning |
|---|---|
| 0 | Success |
| 1 | Generic failure |
| 2 | Usage error |
| 3 | Authentication failed |
| 4 | Build failed |
| 5 | Upload failed |
| 6 | Publish or verification failed |
| 7 | Configuration error |
</exit_codes>

<troubleshooting>
See [references/troubleshooting.md](references/troubleshooting.md) for doctor check ids and fixes, the delay after
`kgp sites create`, certificate waits, and 404s caused by using the wrong host. Commands are listed in
[references/commands.md](references/commands.md); the site layout is in [references/site-anatomy.md](references/site-anatomy.md).
</troubleshooting>

<not_yet>
Previews, environment variables, forms, functions, custom domains, and Netlify-style `_redirects` and `_headers`
files arrive in later milestones. When asked for one of these, say it is not available yet instead of improvising
(for example, do not add PHP files or server-side redirects by hand).
</not_yet>

<success_criteria>
- Every kgp call used `--json --yes`, and decisions came from stdout and the exit code.
- Nothing was published to production unless the user asked for it.
- No secret appeared in a command line, `kgp.toml`, the build output, or a message to the user.
</success_criteria>
