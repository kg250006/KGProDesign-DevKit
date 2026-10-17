# kgp commands for site work

Add `--json --yes` to every call, as shown.

| Task | Command |
|---|---|
| What is live? | `kgp status --json --yes` |
| Deploy for review (not live) | `kgp deploy --json --yes` |
| Deploy without rebuilding | `kgp deploy --no-build --json --yes` |
| Deploy another folder | `kgp deploy --dir out --json --yes` |
| Publish a reviewed release (only when asked) | `kgp releases publish RELEASE_ID --json --yes` |
| Deploy straight to production (only when asked) | `kgp deploy --prod --rollback-on-fail --json --yes` |
| List releases | `kgp releases list --json --yes` |
| Roll back to the previous release | `kgp rollback --json --yes` |
| Roll back to a specific release | `kgp rollback RELEASE_ID --json --yes` |
| Keep a release forever / let it expire | `kgp releases pin RELEASE_ID --json --yes` / `kgp releases unpin RELEASE_ID --json --yes` |
| Site details | `kgp sites info SITE --json --yes` |
| Link a repo to an existing site | `kgp link --site SITE --json --yes` |
| Check the hosting setup | `kgp instance doctor --json --yes` |
| Which credentials are in use | `kgp whoami --json --yes` |
| Runtime env var names (never values) | `kgp env list --json --yes` |
| Functions in the live release | `kgp functions list --json --yes` |
| Function errors | `kgp functions logs --json --yes` |
| Per-request log (method, path, status, ms; no query strings) | `kgp functions logs --requests --since 2h --json --yes` |
| Replay a contract file against the site | `kgp functions contract run --file contracts.yaml --json --yes` |
| Compare two bases with the same contract file | `kgp functions contract run --compare https://A https://B --file contracts.yaml --json --yes` |
| Run the site and functions locally | `kgp dev` (it keeps running; stop it when done) |
| What a Netlify site needs to move | `kgp migrate netlify --json --yes` |
| Migration report (functions, schedules, env names, SDKs, proxy) | `kgp migrate netlify --report --json --yes` |
| Host names of the site | `kgp domains list --json --yes` |
| DNS and certificate state of a custom domain | `kgp domains status DOMAIN --json --yes` |
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

Owner-only commands (run only on an explicit request): `kgp sites create`, `kgp sites delete`, `kgp server init`,
`kgp server upgrade`, `kgp server wildcard`, `kgp server cert setup`, `kgp server cert run` (production), `kgp server mail set`, `kgp instance add`, `kgp instance remove`, `kgp login`, `kgp logout`,
`kgp domains add`, `kgp domains remove`, `kgp domains park`, `kgp domains move`, `kgp env set`, `kgp env unset`, `kgp env import`, `kgp migrate netlify --write`,
`kgp mail block`, `kgp mail unblock`, `kgp mail limits` with values, `kgp mail wp set`, `kgp mail wp unlink`, `kgp mail identity set`, `kgp mail identity remove`,
`kgp deploy --skip-hooks`, `kgp releases publish --skip-hooks`, `kgp rollback --skip-hooks` (publish without the release's predeploy hook; never the answer to `predeploy_failed`),
`kgp analytics configure`, `kgp analytics install`, `kgp analytics upgrade`, `kgp analytics add-site --wordpress`,
`kgp analytics wp-token`, `kgp analytics invite`.

Values for `kgp env set` and `kgp server mail set` come from stdin or a file, never from an argument:
`kgp env set NAME < file`, `kgp env import .env.server`, `kgp server mail set --key-stdin < file`. The WordPress
application password for the email log link comes from stdin too:
`kgp mail wp set --url https://example.com --user kgp-log --app-password-stdin --json --yes < app-password.txt`.

Sender identities (ADR 0017): `kgp mail identity show --json --yes` and `kgp mail identity verify --json --yes` are safe to run; `kgp mail identity set --from EMAIL --name NAME --key-stdin --json --yes < token.txt` and `kgp mail identity remove --json --yes` are owner actions (the MailerSend token only through stdin).
