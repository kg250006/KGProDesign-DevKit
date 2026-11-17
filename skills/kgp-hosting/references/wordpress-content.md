# WordPress content: targets and content push

Concept, demo and client sites often read their content (posts, pages, team, testimonials, events, site
settings) from a WordPress (sub)site. `kgp wp content push` puts that content into WordPress from files in the
repo, so nobody types it into wp-admin. Add `--json --yes` to every call.

## Targets

A target is a WordPress site this machine can write to: a name, the site address, a WordPress user and a kind.
The user's Application Password is stored on the machine, never in the repo, an argument or the output. It is
either in a mode-600 file, `~/.deployment-expert/kgp-wp-NAME.json` (`credential_ref = "file"`), or in the OS keychain
(service `kgp-wp`). Unattended machines use the file, because the keychain asks for approval again from time to
time and stops autonomous pushes. kgp reads either one itself.

| Kind | Meaning | Agent may push drafts? |
|---|---|---|
| `concept` | an industry concept site | yes |
| `demo` | a demo for a prospect, or the shared demo subsite | yes |
| `client` | a signed client's live site | no: owner only, needs `--allow-client` |
| `other` | anything else | no: owner only, needs `--allow-client` |

```bash
kgp wp site list --json --yes          # targets; "credential": "present (file)", "present (keychain)" or "missing"
kgp wp site test demo-site --json --yes # logs in; reports roles, can_edit, can_publish, warnings
```

What a password can reach is set in WordPress, not by kgp. An Application Password belongs to one WordPress
user. On a multisite it works on every subsite where that user is a member, with that user's role there. The service
user should be an Editor on as few subsites as possible. kgp only writes to targets that were added, but anyone
holding the password can call the API directly.

If the target is missing, or its credential is `missing`, stop. Ask the owner to add it on this machine
(`kgp wp site add` is an owner action; the owner's new-device runbook has the steps). Never create a WordPress
user, an Application Password or a keychain item yourself.

When the owner asks you to add a target, store it in a file and pipe the password in from where the owner keeps it,
without showing it:

```bash
kgp wp site add NAME --url https://wp.example.com/site --user LOGIN --kind demo \
  --credential file --app-password-stdin --json --yes < PASSWORD_FILE
```

The result reports `roles`, `can_edit` and `warnings`. An Application Password works on every subsite where its
user is a member, so one Editor service user can serve several targets: add each subsite once.

## The content folder

Default `wordpress/content/`. It holds one file per REST base: `posts.json`, `pages.json`, `testimonials.json`,
`site-settings.json` and so on. Each file is a JSON array of entries keyed by `slug`. The REST base is the file
name. `kgp wp content push` refuses a base the site does not have and lists the ones it does.

| Field | Notes |
|---|---|
| `slug` | required, lowercase letters, digits and dashes, unique in the file. WordPress turns `--` into `-`, and results show the stored slug |
| `title`, `excerpt` | text |
| `content` or `content_file` | HTML, or a `.md` / `.html` file next to the JSON (Markdown is converted) |
| `status` | `draft` (default), `pending`, `private`, `publish` (only with `--publish`) |
| `date` | ISO 8601: with an offset it is exact, without one it is site time. Never changed on a published entry |
| `menu_order` | integer |
| `parent` | slug of another entry in the same file (pages) |
| `featured_image` | `{"file": "img/hero.jpg", "alt": "…"}` or `{"url": "https://…", "alt": "…"}` |
| `acf` | content-model field values, for example `{"quote": "…", "attribution": "…"}` |
| `images` | image fields of the content model: `{"photo": {"file": "img/jane.jpg", "alt": "Jane"}}` |
| `terms` | `{"categories": ["news"]}`: the terms must already exist |

Images are png, jpg, gif, webp or pdf, at most 10 MB. svg is refused. Each image is uploaded once, and
the same file used twice is reused.

Examples:

```json
[
  {
    "slug": "welcome-to-the-demo",
    "title": "Welcome to the demo",
    "content_file": "posts/welcome.md",
    "excerpt": "What this site shows.",
    "featured_image": { "file": "img/welcome.jpg", "alt": "The shop front" },
    "terms": { "categories": ["news"] }
  }
]
```

```json
[
  { "slug": "services", "title": "Services", "content_file": "pages/services.md" },
  { "slug": "installation", "title": "Installation", "content_file": "pages/installation.md", "parent": "services" }
]
```

```json
[
  {
    "slug": "demo--testimonial--on-time",
    "title": "On time (demo)",
    "acf": { "quote": "Everything was ready when they said.", "attribution": "Sample customer" },
    "images": { "photo": { "file": "img/customer.jpg", "alt": "Sample customer" } }
  }
]
```

The site factory's content files (`factory/demo-wp/content/GROUP/REST_BASE.json`) use this shape. The one
exception is `acf_dates`, which push refuses. Put the dates in `acf`.

## Workflow

1. `kgp wp site list --json --yes`: confirm the target exists and its kind.
2. `kgp wp content push wordpress/content --target demo-site --dry-run --json --yes`: read `entries`. Each one has
   `action` (`create`, `update`, `unchanged`), `changed` (field names), `status` and `held`.
3. `kgp wp content push wordpress/content --target demo-site --json --yes`: writes drafts. Report `counts` and
   `media` to the user.
4. Publish only when the user asks:
   `kgp wp content push wordpress/content --target demo-site --publish --json --yes`.

Rules the push follows:

- It matches by slug. It never deletes, trashes or unpublishes anything.
- It never lowers a status. A post published in wp-admin stays published.
- A second identical push reports every entry `unchanged` and writes nothing.
- An entry whose file says `publish` is written as a draft and reported `held` until `--publish` is given.
- `--only posts,pages` limits the push to some files.
- It stops at the first failed write. Entries before it are done, and running it again is safe.

To start from content that already exists on a site, pull one type into the folder. Media is not exported:

```bash
kgp wp content pull --target demo-site --type posts --json --yes   # writes wordpress/content/posts.json
```

## Content models: post types, fields, taxonomies and terms

The kgp-content-models plugin gives each subsite its post types (presets such as `testimonial`, `team`, `faq`,
`gallery`, `event`, `menu_item`, `product`, `service`, `case_study`, `location`, `site_section`, `site_settings`,
`release`), their ACF fields, and taxonomies with starting terms, all from one JSON config per site. A client repo
keeps its copy at `wordpress/content-models.json`. A push refuses a REST base, taxonomy or term the site does not
have, so add those to the config first.

No kgp command changes the config. Use the plugin's REST route as the target's service user:

```
GET  https://SITE/wp-json/kgp/v1/content-models/config   -> {site_id, version, config, writable}
PUT  https://SITE/wp-json/kgp/v1/content-models/config   body {"config": FULL_CONFIG}
```

- **Who:** an Editor on the subsite whose login is in the config's `managers` list, or a site administrator. Check
  `managers` in the GET result. If the service user is not listed, stop and ask the owner. Only a network super
  admin can change `managers`.
- **Additive only:** add presets, `extra_fields`, taxonomies (`taxonomies` items need `name`, `rest_base`, `labels`
  and `object_types`) and terms (`{slug, name}` in a taxonomy's `terms`, at most 100 per taxonomy). Never remove or
  rename anything, change a REST base or a field type, or send `force`. Starting terms are created on the next
  request after the PUT.
- **How:** GET, change the `config` object, PUT the whole object back, then GET again to confirm. Keep
  `wordpress/content-models.json` in the repo equal to what you PUT. The schema is
  `wordpress/plugins/kgp-content-models/content-models.schema.json` in KGP-WebHosting-Tools.
- **Login:** Basic auth with the service user and the target's Application Password. This is the one case where you
  read a target's credential file, and only for a target with `credential_ref = "file"`. Read it into a shell
  variable inside the command and never print it:

```bash
P=$(node -e 'process.stdout.write(JSON.parse(require("fs").readFileSync(process.env.HOME+"/.deployment-expert/kgp-wp-NAME.json","utf8")).app_password)')
curl -s -u "LOGIN:$P" https://SITE/wp-json/kgp/v1/content-models/config > cm.json    # then edit .config, write body.json
curl -s -u "LOGIN:$P" -X PUT -H 'Content-Type: application/json' --data-binary @body.json \
  https://SITE/wp-json/kgp/v1/content-models/config; unset P
```

| PUT answer | Meaning and fix |
|---|---|
| `200 {config, previous_backup}` | Saved; the old file was backed up |
| `422 invalid` | `errors` lists what the schema refused. Fix the config |
| `409 not_additive` | `violations` lists removals or renames. Put them back; never use `force` |
| `403 managers_locked` / `force_forbidden` | Only a super admin can do that. Ask the owner |
| `401` / `403` | Wrong password, or the user is not a manager Editor on this subsite. Report it to the owner |
| no route (404) | The site has no valid config yet. The owner uploads the first one |

## Errors

| Code | Exit | Meaning and fix |
|---|---|---|
| `unknown_wp_target` | 7 | No such target on this machine. Ask the owner to add it. |
| `missing_wp_credentials` | 3 | The target has no password on this machine. Ask the owner to run `kgp wp site add` again. |
| `wp_auth` | 3 | WordPress refused the login or the action: revoked password, or a user without the role. Run `kgp wp site test`. If `details.wp_code` is `rest_not_logged_in`, WordPress did not accept the password. Either it is wrong or revoked, or the web server dropped the `Authorization` header. Some security plugins hide the more specific errors. Do not retry with other passwords. Report it to the owner. |
| `wp_redirect` | 7 | The target URL redirects (www, http, path). The owner fixes the target URL. |
| `wp_client_target` | 7 | Client or other site without `--allow-client`. Owner only. |
| `config` | 7 | The content folder or the site does not match: bad JSON, an unknown REST base, a missing term. `details.problems` lists each one. |
| `wp_push_failed` | 1 | A write failed. `details.entries` shows what was done and `details.failed` what stopped it. Fix it and push again. |
| `wp_unreachable`, `wp_error` | 1 | Network or WordPress error. Retry once, then report. |

Never paste an Application Password into chat, files, tickets or commands. If one is shown to you, tell the user
to revoke it in wp-admin (Users > Profile > Application Passwords).
