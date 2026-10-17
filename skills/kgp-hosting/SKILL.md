---
name: kgp-hosting
description: Deploys, publishes, rolls back, and diagnoses websites hosted on KGP Host (sitepage.app or a customer domain) safely through the kgp CLI, including PHP functions under /api/, runtime env vars, redirects, custom domains, the *.sitepage.app wildcard and its certificate, and Netlify migrations. Use when the repo contains kgp.toml, when asked to deploy, publish, roll back, check status, or fix a broken KGP-hosted site, when writing or debugging functions/*.php, setting env vars, adding redirects, headers or a custom domain, when a site shows "Nothing lives here." or a certificate error, when checking or renewing the wildcard certificate, or when moving a site from Netlify.
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
- `[functions] dir` (default `functions`): PHP functions served under `/api/`.
- `[[redirects]]`: redirects in netlify.toml's shape (`from`, `to`, `status`, `force`).
- `[mail] from_name`: the sender name for the site's emails (usually the client's company name).

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
- `functions/NAME.php` answers `/api/NAME` and `/api/NAME/...`; `functions/index.php` answers any other `/api/*` path; `functions/_shared/` is for `require` only. Functions deploy and roll back with the release. `/api/*` is reserved: a release without functions answers 404 there. Details and the helper API: [references/functions.md](references/functions.md).
- Runtime env vars (`kgp env set`) are write-only secrets for functions. They apply on the next request and are not part of releases. A deploy fails (exit 7, `secret_in_build`) if the static build contains a runtime value.
- Redirects come from `[[redirects]]` in kgp.toml and from `_redirects` / `_headers` files at the root of the publish folder; those two files are compiled into the rules and not served.
- Site addresses come from one `*.PLATFORM_DOMAIN` cPanel subdomain when the instance uses `site_addressing = "wildcard"` (sitepage.app does): `kgp sites create` makes no cPanel call, and a name without a site shows the 404 "Nothing lives here." page (`X-KGP-No-Site: 1`). The wildcard's Let's Encrypt certificate renews itself from a daily cPanel cron job (acme.sh, DNS-01 through a permanent `_acme-challenge` CNAME); check it with `kgp server cert status --json --yes`. Details: [references/sites-domains-certificates.md](references/sites-domains-certificates.md).
- Custom domains are attached with `kgp domains add`, which creates a cPanel addon domain, requests AutoSSL, and prints the DNS record for the domain owner to set. Never change DNS yourself.
- Page analytics come from the instance's self-hosted Matomo (cookieless, no consent banner). `kgp analytics add-site --json --yes` gives a site its Matomo id in `kgp.toml`; `kgp analytics snippet --format js --json --yes` prints the tracker for the React app. Deploys add the stats origin to a site's own Content-Security-Policy. Details: [references/analytics.md](references/analytics.md).
- Every `kgp_send_email()` call is logged on the server for 90 days (sent, failed or rejected), with its bodies and salted hashes of the sender's IP, never the raw IP. Read it with `kgp mail log --json --yes` and `kgp mail show ID --json --yes`. A blocked or capped sender gets `false` from `kgp_send_email()` and a `rejected` `abuse_limit` entry. A site can push its log to a WordPress site with the kgp-email-log plugin (`kgp mail wp`).
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
- put secrets, tokens, or passwords in `kgp.toml`, the build output, or function source (read them with `kgp_env()`);
- ship `.htaccess` or PHP files in the build output (PHP belongs in `functions/`; the deploy leaves build PHP out or refuses it);
- pass an env value or the mail key on the command line (use `kgp env set NAME < file`, `kgp env import FILE`, `kgp server mail set --key-stdin`), or print one back to the user;
- edit files on the server, in cPanel, or through the cPanel API directly;
- change DNS records or nameservers;
- pass a token or secret as a command-line argument (use `KGP_CPANEL_TOKEN`, `KGP_AGENT_SECRET`, or `kgp login --token-stdin`);
- run an owner-only command without an explicit user request: `kgp sites create|delete`, `kgp instance add|remove`, `kgp login|logout` (including `kgp login --acme`), `kgp server init|upgrade`, `kgp server wildcard`, `kgp server cert setup`, a production `kgp server cert run`, `kgp server mail set`, `kgp domains add|remove`, `kgp env set|unset|import`, `kgp migrate netlify --write`, `kgp mail block|unblock`, `kgp mail limits` with values, `kgp mail wp set|unlink`, `kgp mail identity set|remove`, `kgp analytics configure|install|upgrade|wp-token|invite`, `kgp analytics add-site --wordpress` (the full list is in [references/commands.md](references/commands.md));
- paste the Matomo `wp-connect` token or any Matomo credential into chat, files or tickets;
- pass a WordPress application password as an argument (use `kgp mail wp set ... --app-password-stdin`);
- paste an email body from `kgp mail show` into chat, tickets or commits unless the user asks; summarise it instead;
- run `kgp server cert run --force` against production unasked (Let's Encrypt allows 5 duplicates a week), or touch `~/kgp-acme`, the `# kgp-acme` cron line, or the `_acme-challenge` CNAME;
- publish to production without an explicit user request.

Always use `--json --yes` and read results from stdout only. Logs and build output go to stderr.
</guardrails>

<corporate_hardening>
The deployment-expert skill's corporate hardening pass also applies to KGP-hosted sites, with these differences:

- Headers (M2): the platform already sends the hardened set above. Add or override headers only in `kgp.toml` `[headers]`, never in an `.htaccess` file.
- HSTS (M4): the platform sends `max-age=31536000; includeSubDomains`. A `Strict-Transport-Security` value containing `preload` is refused with exit 7.
- `Cache-Control`: the platform caches `/assets/` for a year and revalidates everything else. Do not override it unless asked.
- Custom domain (M1): a `*.sitepage.app` address is a shared platform subdomain. Attach the client's own domain with `kgp domains add DOMAIN --primary` when the owner asks; until the owner sets the DNS record, record M1 as waiting on DNS, not as a failure to fix by hand.
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
`kgp sites create`, certificate waits, and 404s caused by using the wrong host. Site addresses, custom domains and
certificate renewal: [references/sites-domains-certificates.md](references/sites-domains-certificates.md). Commands are listed in
[references/commands.md](references/commands.md); the site layout is in [references/site-anatomy.md](references/site-anatomy.md).
</troubleshooting>

<migrating_from_netlify>
1. `kgp migrate netlify --json --yes`: read `kgp_toml`, `node_functions`, and `unsupported`. Run it again with `--write` only after the user agrees.
2. Move non-secret `VITE_*` build values into a committed `.env.production`; ask the owner to set secrets with `kgp env set`.
3. Port each Node function to `functions/NAME.php` with the helpers in [references/functions.md](references/functions.md), keeping the same paths, status codes and JSON. Test with `kgp dev` (env from `.env.kgp-dev`, never committed).
4. Deploy as a draft, then follow the quick start. Report every `unsupported` item with its suggestion instead of improvising.
</migrating_from_netlify>

<not_yet>
Previews, forms (Netlify form markup), site databases, scheduled functions, edge functions, Node functions,
redirect conditions (country, language, role), signed redirects, query-parameter matching, and proxying to external
URLs are not available. When asked for one of these, say so instead of improvising (for example, do not add PHP to
the build output or write `.htaccess` rules by hand). Edge-function work such as share previews can usually be done
with a 200 redirect to `/api/NAME` and a PHP function.
</not_yet>

<success_criteria>
- Every kgp call used `--json --yes`, and decisions came from stdout and the exit code.
- Nothing was published to production unless the user asked for it.
- No secret appeared in a command line, `kgp.toml`, the build output, function source, or a message to the user.
- Owner actions (domains, mail, deleting sites) ran only on an explicit request.
</success_criteria>
