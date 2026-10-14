---
description: "[KGP] Move a Netlify site to KGP Host step by step: plan, kgp.toml, env vars, PHP functions, local test, draft deploy"
argument-hint: "[plan|SITE_NAME]"
allowed-tools: [Skill(kgp-hosting), Read, Write, Edit, Bash, Grep, Glob, AskUserQuestion]
---

Move this Netlify project to KGP Host: $ARGUMENTS

Invoke the `kgp-hosting` skill first and follow its `<prerequisites>`, guardrails, and `<migrating_from_netlify>`
section. This command is the step-by-step driver for that section. It never publishes to production and never
runs an owner-only command without the user's yes for that step.

## Routing

- **`plan`** → run step 1 only and stop. Write nothing.
- **A site name** → use it as `SITE` in step 2.
- **No argument** → run every step, stopping at each gate.

## Steps

Stop and report at any failure. Never improvise a workaround for an `unsupported` item.

1. **Check and plan (read-only).**
   - Confirm `netlify.toml` exists at the project root. Without it, stop: `kgp migrate netlify` needs it (`--file PATH` if it lives elsewhere).
   - `kgp --version` and `kgp whoami --json --yes`. The bridge needs kgp 0.2.0 or later.
   - `kgp migrate netlify --json --yes`. Show the user, in plain words:
     - the proposed `kgp_toml` settings (build command, publish dir, SPA mode, headers, redirects)
     - `build_env_names`: build-time variables the site expects
     - `node_functions`: each one becomes a PHP port in step 4
     - `compiled_on_deploy`: `_redirects` / `_headers` files that need no change
     - `unsupported`: each item with its suggestion. A database-backed function is a blocker; say so.
   - Ask whether to continue. **Gate.**

2. **Write `kgp.toml`.** Owner action: `--write` is owner-only, so ask "Write kgp.toml now?" and run it only on a yes. **Gate.**
   - If `kgp.toml` already exists, `kgp migrate netlify --write --json --yes` merges into it.
   - If not, the site must exist on the instance. Ask for the name (`SITE`), check it with `kgp sites info SITE --json --yes`,
     and if missing ask the owner to create it (`kgp sites create SITE`). Then `kgp migrate netlify --write --site SITE --json --yes`.
   - Show the resulting file.

3. **Environment variables.**
   - Non-secret build values (`VITE_*` and other public names in `build_env_names`) go in a committed `.env.production`.
     Ask the user for any values not already in the repo.
   - Secrets the functions read go to the server. The owner runs `kgp env set NAME < file` or `kgp env import .env.server`.
     Never pass a value as an argument, never print one, never commit `.env.server`.
   - Add `.env.kgp-dev` and `.env.server` to `.gitignore`.

4. **Port each Node function** in `node_functions` to `functions/NAME.php` with the helpers in the skill's
   `references/functions.md`. Keep the path, methods, status codes, JSON field names, rate limits, and honeypot order the
   front end depends on. Replace `process.env` with `kgp_env()`, `fetch()` with `kgp_fetch()`, `context.waitUntil()` with
   `kgp_defer()`, and MailerSend calls with `kgp_send_email()`. If a function sends mail, check `kgp server mail status --json --yes`
   and tell the owner when it is not set up. Leave the Node files in place until the site is live on KGP Host.

5. **Test locally.** Put local values in `.env.kgp-dev`, run `kgp dev` (port 8888), and call each `/api/*` route and a
   few pages, including one deep link for SPA sites. Mail prints to the terminal. Stop `kgp dev` when done.

6. **Draft deploy.** Follow the skill's `<quick_start>`: build, then `kgp deploy --json --yes`. Report the `deploy_id`.
   KGP Host has no preview URLs, so the draft is checked by `kgp dev` (step 5), not in the browser. **Gate:** publish
   only when the user asks (`kgp releases publish ID --json --yes`), then read `verification` as the quick start says.

7. **Domain (optional, owner action).** When the user is ready to move DNS, the owner runs
   `kgp domains add DOMAIN --primary` (or asks you to, explicitly). Then give the DNS records from `kgp domains status DOMAIN --json --yes`. Keep the Netlify site running until DNS and the
   certificate are confirmed.

## Report

End with a checklist: done, waiting on the owner (with the exact command for them to run), and every `unsupported`
item still open.
