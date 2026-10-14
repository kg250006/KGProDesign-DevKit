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
| Run the site and functions locally | `kgp dev` (it keeps running; stop it when done) |
| What a Netlify site needs to move | `kgp migrate netlify --json --yes` |
| Host names of the site | `kgp domains list --json --yes` |
| DNS and certificate state of a custom domain | `kgp domains status DOMAIN --json --yes` |

Owner-only commands (run only on an explicit request): `kgp sites create`, `kgp sites delete`, `kgp server init`,
`kgp server upgrade`, `kgp server mail set`, `kgp instance add`, `kgp instance remove`, `kgp login`, `kgp logout`,
`kgp domains add`, `kgp domains remove`, `kgp env set`, `kgp env unset`, `kgp env import`, `kgp migrate netlify --write`.

Values for `kgp env set` and `kgp server mail set` come from stdin or a file, never from an argument:
`kgp env set NAME < file`, `kgp env import .env.server`, `kgp server mail set --key-stdin < file`.
