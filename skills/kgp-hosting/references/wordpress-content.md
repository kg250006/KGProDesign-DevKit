# WordPress content: targets and content push

Concept, demo and client sites often read their content (posts, pages, team, testimonials, events, site
settings) from a WordPress (sub)site. `kgp wp content push` puts that content into WordPress from files in the
repo, so nobody types it into wp-admin. Add `--json --yes` to every call.

## Targets

A target is a WordPress site this machine can write to: a name, the site address, a WordPress user and a kind.
The user's Application Password stays in the OS keychain. It is never in the repo, an argument or the output.

| Kind | Meaning | Agent may push drafts? |
|---|---|---|
| `concept` | an industry concept site | yes |
| `demo` | a demo for a prospect, or the shared demo subsite | yes |
| `client` | a signed client's live site | no: owner only, needs `--allow-client` |
| `other` | anything else | no: owner only, needs `--allow-client` |

```bash
kgp wp site list --json --yes          # targets on this machine; "credential": "present (keychain)" or "missing"
kgp wp site test demo-site --json --yes # logs in; reports roles, can_edit, can_publish, warnings
```

What a password can reach is set in WordPress, not by kgp. An Application Password belongs to one WordPress
user. On a multisite it works on every subsite where that user is a member, with that user's role there. The service
user should be an Editor on as few subsites as possible. kgp only writes to targets that were added, but anyone
holding the password can call the API directly.

If the target is missing, or its credential is `missing`, stop. Ask the owner to add it on this machine
(`kgp wp site add` is an owner action; the owner's new-device runbook has the steps). Never create a WordPress
user, an Application Password or a keychain item yourself.

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
