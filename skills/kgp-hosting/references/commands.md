# kgp commands for site work

Add `--json --yes` to every call, as shown.

| Task | Command |
|---|---|
| What is live? | `kgp status --json --yes` |
| Deploy for review (not live) | `kgp deploy --json --yes` |
| Deploy without rebuilding | `kgp deploy --no-build --json --yes` |
| Deploy another folder | `kgp deploy --dir out --json --yes` |
| Deploy with a note stored on the release | `kgp deploy --message "TEXT" --json --yes` |
| Publish a reviewed release (only when asked) | `kgp releases publish RELEASE_ID --json --yes` |
| Deploy straight to production (only when asked) | `kgp deploy --prod --rollback-on-fail --json --yes` |
| List releases | `kgp releases list --json --yes` |
| Roll back to the previous release | `kgp rollback --json --yes` |
| Roll back to a specific release | `kgp rollback RELEASE_ID --json --yes` |
| Keep a release forever / let it expire | `kgp releases pin RELEASE_ID --json --yes` / `kgp releases unpin RELEASE_ID --json --yes` |
| Delete a release that is not live or previous (ask first) | `kgp releases delete RELEASE_ID --json --yes` |
| Sites on the instance | `kgp sites list --json --yes` |
| Instances on this machine / one instance's settings | `kgp instance list --json --yes` / `kgp instance show --json --yes` |
| Site details | `kgp sites info SITE --json --yes` |
| Link a repo to an existing site | `kgp link --site SITE --json --yes` |
| Check the hosting setup | `kgp instance doctor --json --yes` |
| Which credentials are in use | `kgp whoami --json --yes` |
| Runtime env var names (never values) | `kgp env list --json --yes` |
| Value of a public env var (secrets answer exit 7 `env_write_only`) | `kgp env get NAME --json --yes` |
| Functions in the live release | `kgp functions list --json --yes` |
| Function errors | `kgp functions logs --json --yes` (`--tail N` for more lines) |
| Scheduled functions and their next run | `kgp functions schedules list --json --yes` |
| Past scheduled runs | `kgp functions schedules runs --json --yes` |
| Run a scheduled function now (runs real code; ask first) | `kgp functions schedules run NAME --json --yes` |
| Login providers of the site (OIDC) | `kgp functions auth providers --json --yes` |
| Per-request log (method, path, status, ms; no query strings) | `kgp functions logs --requests --since 2h --json --yes` |
| Replay a contract file against the site | `kgp functions contract run --file contracts.yaml --json --yes` |
| Contract file against `kgp dev` or another base | `kgp functions contract run --base http://127.0.0.1:PORT --file contracts.yaml --json --yes` |
| Compare two bases with the same contract file | `kgp functions contract run --compare https://A https://B --file contracts.yaml --json --yes` |
| Run the site and functions locally | `kgp dev` (it keeps running; stop it when done) |
| What a Netlify site needs to move | `kgp migrate netlify --json --yes` |
| Migration report (functions, schedules, env names, SDKs, proxy) | `kgp migrate netlify --report --json --yes` |
| Host names of the site | `kgp domains list --json --yes` |
| DNS and certificate state of a custom domain | `kgp domains status DOMAIN --json --yes` |
| Scheduler cron line and last tick | `kgp server cron status --json --yes` |
| What the host supports (PHP version, zip, upload limits) | `kgp server probe --json --yes` |
| Platform mail sender state | `kgp server mail status --json --yes` |
| KGP Console sessions and users (read only) | `kgp console sessions list --json --yes` / `kgp console users list --json --yes` |
| Mail the site sent or tried to send (no bodies) | `kgp mail log --since 24h --json --yes` |
| Only refused mail | `kgp mail log --status rejected --json --yes` |
| One log entry with its bodies (do not paste bodies unasked) | `kgp mail show ENTRY_ID --json --yes` |
| Busiest senders on every site, by salted IP hash | `kgp mail top --by ip --json --yes` |
| Blocked senders and send caps | `kgp mail blocks --json --yes` / `kgp mail limits --json --yes` |
| WordPress link state and pending pushes | `kgp mail wp status --json --yes` |
| Test the WordPress link | `kgp mail wp test --json --yes` |
| Analytics install state | `kgp analytics status --json --yes` |
| Give a site its Matomo id (writes kgp.toml) | `kgp analytics add-site --json --yes` |
| Tracker code for the React app | `kgp analytics snippet --format js --json --yes` |
| Wildcard certificate state (days left, cron, last run) | `kgp server cert status --json --yes` |
| Try the renewal safely (Let's Encrypt staging) | `kgp server cert run --staging --json --yes` |
| WordPress targets on this machine (never the password) | `kgp wp site list --json --yes` |
| Check a WordPress target's login and role | `kgp wp site test NAME --json --yes` |
| What a content push would change (writes nothing) | `kgp wp content push wordpress/content --target NAME --dry-run --json --yes` |
| Push content as drafts (concept and demo targets) | `kgp wp content push wordpress/content --target NAME --json --yes` |
| Push only some types | `kgp wp content push wordpress/content --target NAME --only posts,pages --json --yes` |
| Export one type from a site into the folder | `kgp wp content pull --target NAME --type posts --json --yes` (`--status`, `--out`, `--force`) |
| Push and publish (only when asked) | `kgp wp content push wordpress/content --target NAME --publish --json --yes` |
| Add a post type, field, taxonomy or term (additive) | GET then PUT `/wp-json/kgp/v1/content-models/config`; see [wordpress-content.md](wordpress-content.md) |
| Where kgp reads secrets (`file`, `keychain`, `env`) | `kgp whoami --json --yes` (`token_source`) |

Owner-only commands (run only on an explicit request): `kgp sites create` (and `--reserved-ok`), `kgp sites delete`, `kgp server init` (and `--rotate-secret`, `--console-secret-stdin`),
`kgp server upgrade` (and `--config`), `kgp server wildcard`, `kgp server cert setup`, `kgp server cert run` (production), `kgp server mail set`, `kgp instance add`, `kgp instance remove`, `kgp login`, `kgp logout`,
`kgp domains add`, `kgp domains remove`, `kgp domains park`, `kgp domains move` (and `--adopt` on add and park), `kgp env set` (including `--public` and `--multiline`), `kgp env unset`, `kgp env import` (including `--replace`), `kgp console sessions revoke`, `kgp migrate netlify --write`,
`kgp mail block`, `kgp mail unblock`, `kgp mail limits` with values, `kgp mail wp set`, `kgp mail wp unlink`, `kgp mail identity set`, `kgp mail identity remove`,
`kgp deploy --skip-hooks`, `kgp releases publish --skip-hooks`, `kgp rollback --skip-hooks` (publish without the release's predeploy hook; never the answer to `predeploy_failed`),
`kgp analytics configure`, `kgp analytics install`, `kgp analytics upgrade`, `kgp analytics add-site --wordpress`,
`kgp analytics wp-token`, `kgp analytics invite`, `kgp wp site add`, `kgp wp site remove`,
`kgp wp content push --allow-client` (client and other targets) and `--publish` on those targets.

Ask before running, even though they are not owner-only: `kgp releases delete` (cannot be undone),
`kgp functions schedules run NAME` (runs real code: mail, database writes), `kgp instance use` (changes this
machine's default instance) and `kgp unlink` (removes the repo's link to its site).

Values for `kgp env set` and `kgp server mail set` come from stdin or a file, never from an argument:
`kgp env set NAME < file`, `kgp env import .env.server`, `kgp server mail set --key-stdin < file`. The WordPress
application password for the email log link comes from stdin too:
`kgp mail wp set --url https://example.com --user kgp-log --app-password-stdin --json --yes < app-password.txt`.

Sender identities (ADR 0017): `kgp mail identity show --json --yes` and `kgp mail identity verify --json --yes` are safe to run; `kgp mail identity set --from EMAIL --name NAME --key-stdin --json --yes < token.txt` and `kgp mail identity remove --json --yes` are owner actions (the MailerSend token only through stdin). Named identities (ADR 0021, agent 0.11.0): every one of these takes `--identity NAME` (default: `default`, the ADR 0017 identity, unchanged); `kgp mail identity list --json --yes` is safe to run; `set --identity NAME` and `remove --identity NAME` stay owner actions. `--name` is the From name, `--identity` the identity name.
