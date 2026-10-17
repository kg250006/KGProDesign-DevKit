# PHP functions on KGP Host

Functions are PHP 8.1+ files in the project's `functions/` folder (`[functions] dir` in `kgp.toml`). They deploy
with each release, roll back with it, and run only through `/api/`. There is no Node runtime on KGP Host.

## Layout and routing

| File | Answers |
|---|---|
| `functions/contact.php` | `/api/contact` and `/api/contact/anything` |
| `functions/events.php` | `/api/events/12/signup` (`kgp_path()` returns `/12/signup`) |
| `functions/index.php` | every other `/api/*` path (optional catch-all) |
| `functions/_shared/*.php` | nothing; `require __DIR__ . '/_shared/name.php'` |
| `functions/vendor/**` | nothing; a Composer install, autoloaded before every function (see "Dependencies") |
| `functions/_assets/**` | nothing; non-PHP files read with `kgp_asset()` (see "Assets") |

Function names are lower-case `a-z`, `0-9`, `_` and `-` (no dots, so not `x.generated.php`), at most 64 characters, one
level deep (plus `_shared/`). The function side of a release (functions, `_shared/`, `vendor/` and `_assets/` together)
holds at most 5,000 files, 8 MiB per file and 64 MiB in total (agent 0.6.0+; before that 100 files of 1 MiB and no
`vendor/` or `_assets/`). A release without functions answers 404 for every `/api/*` path.

## Helpers

| Helper | What it does |
|---|---|
| `kgp_method('POST', ...)` | Ends with 405 and an `Allow` header for any other method. |
| `kgp_path()` | The path after `/api/NAME` (`""` when none). |
| `kgp_json_body($max = 65536)` | The body as a JSON object; ends with 400 `invalid_json` or 413 `too_large`. |
| `kgp_raw_body($max = 6291456)` | The exact request bytes (webhook signatures). Works before or after `kgp_json_body()`; the body is read once. 413 `too_large`. |
| `kgp_form_body($max = 1048576)` | An `application/x-www-form-urlencoded` body as an array, nested keys included (`data[email]`), with PHP's `parse_str` rules: at most `max_input_vars` fields (1000 on cPanel) and dots in names become underscores. 415 for other content types. |
| `kgp_headers()`, `kgp_header('Stripe-Signature')` | Request headers as a lower-cased map, or one header (case-insensitive) or `null`. `authorization` is included (see below). |
| `kgp_query()`, `kgp_query_all()` | Query parameters: last value per key (`['a' => '2']`), or every value (`['a' => ['1', '2']]`). Keys keep dots and brackets; `$_GET` would not. |
| `kgp_respond($status, $array, $headers = [])` | Sends JSON (`Cache-Control: no-store`) and ends the function. A header value may be a list (`'X-A' => ['1', '2']`) for repeated lines. |
| `kgp_send($status, $body, $contentType, $headers = [])` | Sends any body (PDF, HTML, empty) with the right `Content-Length`, `Cache-Control: no-store` unless given, and ends the function. |
| `kgp_redirect($url, $status = 302)` | Ends with a redirect to an `https://` URL or a path starting with one `/` (301, 302, 303, 307 or 308). Protocol-relative targets and line breaks are refused. |
| `kgp_set_cookie($name, $value, $opts = [])` | Queues one `Set-Cookie` line; call it once per cookie. Options `path` (`/`), `max_age` (seconds; `0` clears), `domain`, `secure` (on unless `CONTEXT` is `dev`), `http_only` (`true`), `same_site` (`Strict`, `Lax` default, `None` forces `Secure`). Encode the value yourself; spaces, `;`, `,`, quotes and line breaks are refused. |
| `kgp_env('NAME', $default)` | A runtime env var (set with `kgp env set`), or an injected one: `URL`, `SITE_NAME`, `CONTEXT`. |
| `kgp_cors([$origin, ...], $methods, $credentials, $opts)` | Allows only the listed origins; answers preflight `OPTIONS` with 204. Never `*`. `$opts`: `allow_headers` (default `['Content-Type']`; add `Authorization` for bearer tokens), `preflight_status` (`204` or `200`). |
| `kgp_rate_limit('bucket', $max, $windowSeconds)` | Fixed window per bucket and client IP; ends with 429 `rate_limited` and `Retry-After`. |
| `kgp_send_email(['to', 'subject', 'text' or 'html', 'reply_to', 'from_name', 'attachments', 'trusted', 'log_body'])` | Sends through the site's own sender identity when one is registered and verified (`kgp mail identity set`), else through the platform sender; returns `true` when accepted. The sender name is `from_name`, else `[mail] from_name` in `kgp.toml`, else the identity's or the instance's ("KGP Mailer"). The From address is never set per message. `attachments`: a list of `{filename, content or path, type}` (see "Attachments"); `trusted`: skip the per-IP caps for webhook-triggered sends (see "Trusted sends and the daily cap"). |
| `kgp_fetch($method, $url, ['headers', 'json' or 'body', 'timeout', 'follow_redirects'])` | Outbound HTTPS. Returns `['status', 'headers', 'body']`; status 0 means the request failed. |
| `kgp_mail_configured()` | `true` when mail can go out: a verified site identity, else the platform sender (`kgp server mail set`). |
| `kgp_mail_identity()` | The site's sender identity `{configured, from_email, from_name, reply_to, domain, verified, verified_at}` without the key, or `null` (always `null` under `kgp dev`). |
| `kgp_mark_trusted()` | Marks the rest of this request as trusted for `kgp_send_email()` (after a webhook signature or session check passed). |
| `kgp_defer(fn () => ...)` | Runs after the response is sent (Netlify's `waitUntil`). |
| `kgp_client_ip()` | The caller's IP (`REMOTE_ADDR`; forwarded headers are not trusted). |
| `kgp_log('message')` | One line in `kgp functions logs`. Never log secrets or form contents. |
| `kgp_pg_query($sql, $params = [])` | Rows of a Postgres query as a list of assoc arrays, `$1..$n` placeholders, values normalized like the Neon JS driver (see "Postgres"). Reads `DATABASE_URL`. |
| `kgp_pg_one($sql, $params = [])` | The first row, or `null`. |
| `kgp_pg_exec($sql, $params = [])` | The affected row count of an INSERT, UPDATE or DELETE. |
| `kgp_pg_transaction([$sql or [$sql, $params], ...], $opts = [])` | Runs the statements in one atomic transaction; one row list per statement. `$opts`: `isolation`, `read_only`, `deferrable`. |
| `kgp_pg($envVar = 'DATABASE_URL', $opts = [])` | The client object for another database URL (`kgp_pg('REPORTS_URL')->query(...)`) or with options: `driver` (`http` or `pdo`), `timeout` (1 to 60 s). |
| `kgp_asset_path('logo.png')` | The absolute path of `functions/_assets/logo.png` in the live release (traversal refused; see "Assets"). |
| `kgp_asset('data.json')` | The bytes of an asset. |
| `kgp_jwt_sign($claims, $secret, $opts = [])` | An HS256 JWT; `$opts`: `ttl` (seconds, sets `exp`), `iat`, `nbf` (see "Kit"). |
| `kgp_jwt_verify($jwt, $secret, $opts = [], &$reason = null)` | The claims of a valid token, or `null` with `$reason`; `$opts`: `leeway`, `iss`, `aud`, `sub`. |
| `kgp_pdf($opts = [])` | A PDF document over FPDF with jsPDF-like methods; `->bytes()` for `kgp_send()` (see "Kit"). |
| `kgp_is_scheduled()` | The slot (ISO 8601 UTC) when the platform scheduler called this function, else `null`; a request header cannot fake it (see "Schedules"). |
| `kgp_oidc_providers()` | The release's login providers: `[{name, issuer, scopes, configured}]` (see "Login with Google / OpenID Connect"). |
| `kgp_oidc_login($provider, $opts = [])` | Starts a login: redirects to the provider with state, nonce and PKCE and sets the `kgp_oidc_state` cookie. `$opts`: `return_to` (a path, default `/`), `redirect_uri`, `scopes`, `params`, `prompt`, `login_hint`. |
| `kgp_oidc_callback()` | Finishes a login on the callback route: checks the state, exchanges the code, verifies the ID token and returns `{provider, issuer, sub, email, email_verified, name, picture, claims, tokens, return_to}`; throws `KgpOidcError`. |
| `kgp_oidc_logout_url($provider, $opts = [])` | The provider's logout URL (`id_token_hint`, `post_logout_redirect_uri` as a path or https URL), or `null` when the provider has none. |
| `kgp_session_start($data, $ttl, $opts = [])` | Sets the site's signed session cookie (`kgp_session`) holding `$data` for `$ttl` seconds (60 s to 30 days; keep ids, under 3 KB). `$opts`: `name`, `path`, `same_site`. |
| `kgp_session($opts = [])` | The session's data, or `null` when the cookie is missing, tampered with or expired. |
| `kgp_session_end($opts = [])` | Clears the session cookie. |

### Email log

Every `kgp_send_email()` call writes one entry to the site's email log (kept 90 days): the recipients, subject,
text and HTML bodies (64 KB each, runtime env values redacted), the function, and salted hashes of the sender's IP
(`ip_hash`, `net_hash`), never the raw IP. Outcomes: `sent`, `failed` (`provider_error`, `network_error`) or
`rejected` (`invalid_email`, `mail_not_configured`, `abuse_limit`).

- Pass `'log_body' => false` for mail that carries a secret (sign-in links, one-time codes). The log then stores
  `[not logged]`; the mail itself is unchanged:
  `kgp_send_email(['to' => $email, 'subject' => 'Your sign-in link', 'text' => $link, 'log_body' => false]);`
- A sender the owner blocked, or one over the send caps (by default 10 per IP and 30 per network per hour, across
  the instance), gets `false` from `kgp_send_email()`. Answer it like any other send failure (for example 503); do
  not retry in a loop.
- Read the log with `kgp mail log --json --yes`. Forms and deploy notices must also send through
  `kgp_send_email()` so they are logged.

`kgp_respond()`, `kgp_send()` and `kgp_redirect()` end the function by throwing; do not wrap them in `catch (Throwable)`.
Uncaught errors and warnings return `{"error":"internal"}` with status 500 and add one line to `kgp functions logs`.
A header, cookie or redirect target with a line break is such an error (`invalid_header`, `invalid_cookie`, `invalid_redirect`).

### Sender identity

By default every site sends through the platform's MailerSend sender (`kgp server mail set`, From `noreply@kgprodesign.com`
unless the owner changed it). A site may register its own sender (ADR 0017): its own MailerSend API token and a From
address on a domain verified in that MailerSend account.

```sh
kgp mail identity set --from billing@example.org --name "Acme Co" --reply-to help@example.org --key-stdin < token.txt
kgp mail identity verify        # asks MailerSend whether example.org is verified in that account
kgp mail identity show          # never the key
kgp mail identity remove        # back to the platform sender
```

What changes with an identity: the bearer token and the From address of every `kgp_send_email()` call, the default
`reply_to`, and `identity: site` in the email log. What does not: the one send function, the log, sender blocks, the
caps. The From address is always the stored one (a per-message `from_name` only changes the display name, and `@`, `<`,
`>` are stripped from it). Until `kgp mail identity verify` succeeds, every send throws `domain_not_verified` (logged as
`rejected domain_not_verified`): a configuration error like `mail_not_configured`, not a provider outcome. Changing the
address or the key resets verification. The key lives in `data/SITE/mail-identity.json` (mode 0600) and never appears
in any API response, CLI output or log line.

### Trusted sends and the daily cap

The per-IP (10 per hour), per-network and per-recipient caps protect public forms. A webhook (Stripe, PayPal) or a
scheduled job sends from one address in bursts, so after the signature or session check passed, send with
`'trusted' => true` or call `kgp_mark_trusted()` once for the rest of the request. Trusted sends skip the per-IP and
per-network caps, never the blocklist, and always count toward the site's daily cap: `[mail] daily_cap` in `kgp.toml`
(default 2000, 1 to 100000), which bounds every send through the site's own identity and every trusted send; untrusted
platform sends keep today's rules only. Over the cap the send returns `false`, the log says `rejected abuse_limit` and
`kgp functions logs` shows `mail: daily cap N reached`. Never set `trusted` from request data.

### Attachments

```php
kgp_send_email([
    'to' => $email,
    'subject' => 'Invoice ' . $number,
    'text' => 'Your invoice is attached.',
    'attachments' => [
        ['filename' => 'invoice.pdf', 'content' => $pdf->bytes(), 'type' => 'application/pdf'],   // bytes
        ['filename' => 'terms.pdf', 'path' => '_assets/terms.pdf', 'type' => 'application/pdf'],   // a file under functions/
    ],
]);
```

At most 10 files and 10 MiB in total (decoded) per message, else `attachment_too_large`. `path` is relative to the
release's `functions/` folder and must stay inside it (`..`, absolute paths and symlinks pointing out are
`invalid_attachment`); `functions/_assets/` is the deployable place for files. `filename` is reduced to its base name
without control characters; `type` is recorded in the log only (MailerSend infers the type). The log stores
`attachments: [{filename, size, type}]`, never content. A send with attachments waits up to 25 s for MailerSend;
behind a Netlify proxy (28 s) a 10 MiB attachment can time out at the proxy while still being sent.

### Cookies, redirects and binary responses

```php
kgp_set_cookie('kgp_admin_token', $jwt, ['max_age' => 86400, 'same_site' => 'Strict']);   // Secure + HttpOnly by default
kgp_set_cookie('kgp_admin_token', '', ['max_age' => 0]);                                   // clear it
kgp_respond(200, ['ok' => true]);                                                          // both Set-Cookie lines are sent
kgp_send(200, $pdfBytes, 'application/pdf', ['Content-Disposition' => 'attachment; filename="invoice.pdf"']);
kgp_send(200, '', 'text/plain');                                                           // an empty 200 (webhook acks)
kgp_redirect('/portal');                                                                   // 302 to a path on this site
```

### Raw body and webhooks

Signature checks need the exact bytes: `$raw = kgp_raw_body(); $sig = kgp_header('stripe-signature');`. Reading the raw
body does not stop a later `kgp_json_body()`, and the other way round. Form-encoded webhooks (Mailchimp) use
`kgp_form_body()`.

The `Authorization` header reaches functions as `kgp_header('authorization')` on agents 0.4.0 and later (the release
rules copy it; `kgp instance doctor` reports `agent_runtime_compat`). Never log it or echo it back.

### Netlify path compatibility

With `[functions] netlify_compat = true` in `kgp.toml`, `/.netlify/functions/NAME[/rest]?query` runs the same function as
`/api/NAME[/rest]?query` with the same method, body, sub-path and query, so a front end ported from Netlify ships
unchanged. `kgp dev` honours it too. Without a functions folder the alias is dropped.

### Injected env vars and timezone

`kgp_env()` also answers `URL` (`https://` plus the site's primary host, else its first host), `SITE_NAME` (the site id)
and `CONTEXT` (`production`, or `dev` under `kgp dev`), as Netlify did. A var set with `kgp env set` under the same name
wins. Functions run in UTC; `[functions] timezone = "America/New_York"` changes that for the whole release (jobs
included). Values set with `kgp env set NAME --public` (browser-side keys such as a Stripe publishable key) may appear in
the build and are not redacted from logs; everything else stays write-only.

### Schedules

A function can run on a schedule (agent 0.7.0+, ADR 0014). Declare it in `kgp.toml`; the list deploys with each
release and rolls back with it, so the restored release's schedules apply:

```toml
[[schedules]]
function = "invoice-reminders"      # functions/invoice-reminders.php
cron = "0 9 * * *"                  # 5-field cron or @hourly, @daily, @weekly, @monthly, @yearly
timezone = "America/Chicago"        # optional; default [functions] timezone, default UTC

[[schedules]]
function = "dunning"
cron = "0 */6 * * *"

[[schedules]]
function = "recurring-invoices"
cron = "0 0 1 * *"

[[schedules]]
function = "email-sequences"
cron = "*/15 * * * *"

[[schedules]]
function = "weekly-digest"
cron = "0 12 * * 0"

[[schedules]]
function = "reports"
cron = "30 8 * * 1-5"

[[schedules]]
function = "cleanup"
cron = "@daily"
```

**The 15-minute rule.** HostGator resets cron intervals under 15 minutes (terms 7a(8)), so the platform runs one
`*/15` tick per account and every schedule must fire on a quarter hour: the minute field may only name `0`, `15`,
`30`, `45` (lists and ranges of those), `*/15` or `*/30`. `* * * * *`, `*/5` and `10 9 * * *` are config errors
(exit 7) naming the rule, at `kgp deploy` and again on the agent. Netlify allowed one minute; this is the one
difference in the `[functions."NAME"] schedule` mapping. At most 20 schedules per site; `index` and `_shared` cannot
be scheduled, and the function file must exist in `functions/`.

**What the job receives.** The tick runs the function in its own PHP process as a synthetic `POST /api/NAME` from
`127.0.0.1` with the header `X-KGP-Scheduled: <slot>`, the JSON body `{"next_run": "<next slot>"}` (Netlify's shape),
and the env var `KGP_SCHEDULE_SLOT`. `kgp_is_scheduled()` returns the slot (`2026-10-16T14:00:00+00:00`) when the
scheduler called, else `null`; it reads the runtime context only, so a web caller sending the header still gets
`null`. Scheduled functions stay reachable over HTTP; guard the ones that must not be, in one line:

```php
if (kgp_is_scheduled() === null) {
    kgp_respond(404, ['error' => 'not_found']);
}
```

**Catch-up.** Each schedule remembers the last slot it was checked for; a tick runs every matching slot since then,
each at most once, newest four only, and writes one `skipped` record naming how many were missed beyond that. A
schedule seen for the first time (a fresh deploy) starts from the current slot, so nothing runs retroactively. Slots
are UTC instants matched in the schedule's zone: a local time that does not exist on the spring-forward day is skipped
and one that repeats on the fall-back day runs twice. Each job has a 600 s wall-clock cap (`timeout` in the record;
the next job still runs); jobs of one tick run one after another, and a tick that finds the previous one still
running exits at once.

**Seeing it work.** `kgp functions schedules list` (next due slot and last run per schedule), `kgp functions
schedules runs [--function NAME] [--limit N]` (the last 200 records: slot, status `ok`, `error`, `timeout`, `skipped`,
`running` or `lost`, duration, error code), `kgp functions schedules run NAME [--query a=1]` (runs it now as source
`manual`; exit 1 when it fails), `kgp server cron status` (the cron line, the PHP it runs, the last tick), and `kgp
instance doctor` (`cron_line_present`, `cron_php_matches_web`, `last_tick_recent`). Function output is discarded;
`kgp_log()` lines land in `kgp functions logs` as always.

**Mail from jobs.** Every job's `REMOTE_ADDR` is `127.0.0.1`, so `kgp_rate_limit()` buckets and the email log's
per-IP cap (10 per hour) apply to all jobs of a site together until PRP-mail-v2-identities exempts scheduler sends.

### Postgres

Functions query an external Postgres database (Neon for kgprodesign.com; any `postgresql://` URL works) through
`kgp_pg_*` (agent 0.5.0+, ADR 0012). The owner sets the URL once, from a file, never as an argument:

```sh
kgp env set DATABASE_URL < url.txt     # postgresql://user:password@ep-....neon.tech/neondb?sslmode=require
```

**Drivers.** Two drivers share one contract. `http` sends each query to Neon's SQL-over-HTTPS endpoint (the only path
that works from the host, where outbound port 5432 is blocked; measured at p50 15 ms, ADR 0010). `pdo` uses
`pdo_pgsql` and is what `kgp dev` and the test harness use. The choice is automatic: `http` when the URL host ends in
`.neon.tech`, `pdo` otherwise. `DATABASE_DRIVER=http|pdo` (`kgp env set DATABASE_DRIVER`, or a line in `.env.kgp-dev`)
overrides it; a second database `REPORTS_URL` takes `REPORTS_URL_DRIVER`; `kgp_pg('DATABASE_URL', ['driver' => 'pdo'])`
overrides it for one call site. Any other value fails with `KgpPgError` 08006.

**Placeholders.** Always `$1..$n`, the same in both drivers and the same as the Node source; params travel beside the
SQL, never inside it. Under `pdo` a literal `?` (the jsonb `?` operator) must be written `??`, as PDO itself requires;
`http` passes the SQL through unchanged. Params may be strings, numbers, booleans or null; arrays are refused (22P02).

```php
$rows = kgp_pg_query('SELECT id, total, created_at FROM invoices WHERE account_id = $1 ORDER BY id DESC LIMIT $2', [$accountId, 20]);
$inv = kgp_pg_one('SELECT * FROM invoices WHERE id = $1', [$id]);          // null when missing
$n = kgp_pg_exec('UPDATE invoices SET paid = true WHERE id = $1', [$id]);  // affected rows
$new = kgp_pg_query('INSERT INTO invoices (account_id, total) VALUES ($1, $2) RETURNING id, created_at', [$accountId, '12.50']);
[$a, $b] = kgp_pg_transaction([
    ['INSERT INTO payments (invoice_id, amount) VALUES ($1, $2) RETURNING id', [$id, '12.50']],
    ['UPDATE invoices SET paid = true WHERE id = $1', [$id]],
], ['isolation' => 'Serializable']);  // one row list per statement; nothing survives a failing statement
```

**Errors.** Every failure is a `KgpPgError` with `sqlstate` (five characters; `08006` for a connection or transport
failure, `57014` for a timeout), `constraint` (the violated constraint's name, else null), `detail` and the server's
message. Idempotency and invoice-number retries read the SQLSTATE:

```php
try {
    kgp_pg_exec('INSERT INTO invoices (number, account_id) VALUES ($1, $2)', [$number, $accountId]);
} catch (KgpPgError $e) {
    if ($e->sqlstate === '23505' && $e->constraint === 'invoices_number_key') {
        $number = nextInvoiceNumber();   // retry with the next number
    } else {
        throw $e;                        // logged as "KgpPgError [SQLSTATE]: message", answered 500
    }
}
```

**Transactions** are non-interactive: a list of statements sent as one batch (Neon's HTTP endpoint offers nothing
else), so there is no "run some PHP between BEGIN and COMMIT". Both drivers roll back the whole batch on the first
error. `read_only => true` makes the batch fail with 25006 on any write; `deferrable` needs `read_only` and
`Serializable`. There is no pooling: one connection per request, closed when the response is sent.

**Timeouts.** Connect 10 s, total 20 s by default; `kgp_pg('DATABASE_URL', ['timeout' => 5])` sets the total (1 to
60 s). Keep the whole function under 25 s when a Netlify proxy sits in front of the site: Netlify's proxy gives up at
26 s (ADR 0010 SP5), and the host's own 60 s limit counts CPU time, so a hung database must be cut by this timeout.

**What is logged.** An uncaught `KgpPgError` lands in `kgp functions logs` as `KgpPgError [23505]: duplicate key value
violates unique constraint "invoices_number_key" at pg.php:12`: the SQLSTATE and the server's message, never the SQL
text, the params, or the connection URL. The runtime also redacts the URL, its password (raw and URL-encoded), user
and host from every log line. `kgp_respond()` bodies are not redacted: answer `sqlstate` and `constraint`, never
`getMessage()`.

**Values.** Both drivers return exactly what the app's Node code sees from `@neondatabase/serverless` today (pg-types
defaults plus the app's DATE override), so the frontend's JSON does not change. Postgres text is normalized by type OID:

| # | Postgres type | Text from server | PHP value | JSON |
|---|---|---|---|---|
| T1 | int2, int4 | `42` | int `42` | `42` |
| T2 | int8, also `count(*)` | `9007199254740993` | string | `"9007199254740993"` |
| T3 | numeric | `12.50` | string | `"12.50"` |
| T4 | float4, float8 | `1.5` | float | `1.5` |
| T5 | bool | `t` / `f` | bool | `true` |
| T6 | json, jsonb | `{"a": [1, 2]}` | `['a' => [1, 2]]` (decoded, assoc) | `{"a":[1,2]}` |
| T7 | timestamptz | `2026-10-16 12:00:00.123456+00` | `"2026-10-16T12:00:00.123Z"` (UTC, milliseconds, truncated) | same |
| T8 | timestamp (no zone) | `2026-10-16 12:00:00` | `"2026-10-16T12:00:00.000Z"` (read as UTC) | same |
| T9 | date | `2026-10-16` | `"2026-10-16"` | same |
| T10 | text, varchar, uuid, other | `x` | string | `"x"` |
| T11 | NULL of any type | | null | `null` |
| T12 | int4[] | `{1,2}` | `[1, 2]` | `[1,2]` |
| T13 | text[], varchar[] | `{"a b",NULL,"q\"x"}` | `["a b", null, "q\"x"]` | same |
| T14 | int8[], numeric[] | `{1,2}` | `["1", "2"]` | `["1","2"]` |
| T15 | bool[] | `{t,f}` | `[true, false]` | same |
| T16 | jsonb[], json[] | `{"{\"a\":1}"}` | `[['a' => 1]]` | `[{"a":1}]` |
| T17 | timestamptz[], date[] | `{"2026-10-16 12:00:00+00"}` | `["2026-10-16T12:00:00.000Z"]` / `["2026-10-16"]` | same |
| T18 | empty array | `{}` | `[]` | `[]` |
| T19 | timestamptz with an offset | `2026-10-16 07:00:00.5-05` | `"2026-10-16T12:00:00.500Z"` | same |
| T20 | bytea, composite, range, 2-D array | as sent | string unchanged | string |

One known difference: a float with a zero fraction is `2` in Node and `2.0` from `kgp_respond()`; money is `numeric`
(a string) and unaffected. Timestamps are UTC whatever `[functions] timezone` says.

## Request log

Every request to a function appends one JSON line to the site's `requests.log` on the host (agent 0.10.0+, ADR 0018):

```json
{"ts":"2026-10-16T20:31:07+00:00","m":"POST","p":"/api/invoice/[email]","s":200,"ms":41,"b":152,"r":"01M5…","fn":"invoice"}
```

`p` is `/api/NAME` plus `kgp_path()`, cut at 200 characters, never the query string; email-shaped segments become
`[email]` and stored secret values `[redacted]`. `j` carries the scheduled slot when the scheduler called. Headers,
bodies and cookies are never logged. The file is capped at 4 MiB and rotated once (`requests.log.1`). Read it with
`kgp functions logs --requests [--since 2h|7d|30m|ISO] [--tail N]`; `kgp functions logs` (errors and `kgp_log()`) is
unchanged. Under `kgp dev` the line goes to stderr.

## Deploy hooks and migrations

`[hooks] predeploy = "functions/_predeploy.php"` in `kgp.toml` (agent 0.10.0+, ADR 0018) runs that file on the host,
through the same runtime and with the site's env, inside the new release and before it is published: on
`kgp deploy --prod`, `kgp releases publish` and `kgp rollback`. The hook is never a route (`/api/_predeploy` answers
404) and never listed by `kgp functions list`. It receives a POST whose JSON body is
`{deploy_id, site, context, previous_release, live_release}`; `kgp_json_body()` reads it, `kgp_env()`, `kgp_pg_*()`,
`kgp_fetch()`, `kgp_log()` work as usual. It passes when it ends normally or answers a 2xx with `kgp_respond()`.
A non-2xx answer, an uncaught error or a run past `[hooks] timeout` (seconds, 5 to 70, default 50) fails it: the
release stays `ready` and unpublished, the live release is untouched, `kgp deploy` exits 6 `predeploy_failed` with
the printed text and `kgp_log()` lines under `details.hooks.predeploy.output` (16 KiB cap, secrets redacted). A
release whose hook passed is not run again (a retried publish or a rollback to it skips it). `--skip-hooks` publishes
without running the hook: for redeploying the same code, never for a failing migration. Do not call `exit()`: the
record stays `running` and the next publish of that release reports that the hook did not return, then retries it.
`kgp dev` does not run hooks; run a local migration with `php functions/_predeploy.php` by hand.

Write migrations as idempotent steps, each recorded in a table inside one transaction, so a retried deploy applies
nothing twice (the platform cannot undo SQL):

```php
<?php // functions/_predeploy.php
kgp_method('POST');
$in = kgp_json_body();                      // deploy_id, site, context, previous_release, live_release
kgp_pg_exec('CREATE TABLE IF NOT EXISTS schema_migrations (version text PRIMARY KEY, applied_at timestamptz NOT NULL DEFAULT now())');
$steps = [
    '026_add_invoice_note' => 'ALTER TABLE invoices ADD COLUMN IF NOT EXISTS note text',
    '027_index_invoice_customer' => 'CREATE INDEX IF NOT EXISTS invoices_customer_idx ON invoices (customer_id)',
];
foreach ($steps as $version => $sql) {
    if (kgp_pg_one('SELECT 1 FROM schema_migrations WHERE version = $1', [$version]) !== null) {
        continue;
    }
    kgp_pg_transaction([[$sql, []], ['INSERT INTO schema_migrations (version) VALUES ($1)', [$version]]]);
    echo "applied $version\n";                 // shows up in the deploy JSON hooks.predeploy.output
}
kgp_log("migrations checked for {$in['deploy_id']}");
kgp_respond(200, ['ok' => true]);
```

## Contract tests

`kgp functions contract run --file contracts.yaml` (ADR 0018) replays HTTP cases against the site, `--base URL`
(for `kgp dev`) or two bases with `--compare URL_A URL_B`, and exits 1 `contract_failed` on any failed expectation or
difference. The file is YAML or JSON, version 1:

```yaml
version: 1
defaults:
  headers: { X-Contract: kgprodesign }
  ignore: ["$.request_id"]                 # JSON paths dropped before json_equal and before a compare
  ignore_headers: [date, server, x-kgp-*, x-nf-*, etag, content-length, vary]   # part of the default list
  timeout_ms: 30000
vars: { who: admin }
cases:
  - name: health
    path: /api/health                       # method defaults to GET
    expect:
      status: 200
      headers: { content-type: "^application/json" }     # name to regex
      json: { ok: true, version: { $type: string }, id: { $any: true } }   # partial match; $regex, $type, $any
  - name: login
    method: POST
    path: /api/auth/login
    body: { user: "${who}", password: "${env:CONTRACT_PASS}" }   # ${env:NAME} from the environment, never a value in the file
    expect:
      status: 200
      cookies: { kgp_session: "HttpOnly; SameSite=Lax" }        # name to regex over the attributes
      json_equal: { ok: true, token: "ignored" }
      ignore: ["$.token"]                                       # deep equality after removing these paths
    capture: { token: "$.token" }                                # later cases may use ${token}
  - name: me
    path: "/api/me/${token}"                                     # the cookie jar sends the session cookie back
    expect: { status: 200, body_regex: "\"email\"" }
  - name: upload
    method: POST
    path: /api/import
    body_file: fixtures/import.csv                               # raw body from a file next to the contract
    expect: { status: 202, body_sha256: "e3b0c442…" }
```

Compare mode normalizes both responses (ignored headers and paths removed, cookies compared by name and attributes,
never value or `Expires`) and reports each difference by case, kind (`status`, `header`, `cookie`, `json`, `body`)
and path. The table and the JSON never carry request or response bodies.

## Login with Google / OpenID Connect

Identity comes from a provider (Google, or a WordPress site running the miniOrange OAuth Server); access (roles,
user rows) stays the site's job (ADR 0015). Declare providers in `kgp.toml`; secrets go in env vars (agent 0.8.0+):

```toml
[[auth.providers]]
name = "google"
issuer = "https://accounts.google.com"
client_id_var = "GOOGLE_CLIENT_ID"
client_secret_var = "GOOGLE_CLIENT_SECRET"
# scopes = ["openid", "email", "profile"]   # the default
[auth.providers.params]                      # extra authorize parameters (optional)
prompt = "select_account"
```

```sh
openssl rand -hex 32 > secret.txt
kgp env set KGP_AUTH_SECRET < secret.txt        # signs the state and session cookies (32+ characters)
kgp env set GOOGLE_CLIENT_ID --public < id.txt
kgp env set GOOGLE_CLIENT_SECRET < client-secret.txt
rm secret.txt id.txt client-secret.txt
```

`kgp deploy` refuses a project with providers until `KGP_AUTH_SECRET` and every named var are set (`auth_env_missing`),
and `kgp functions auth providers` shows what is set without showing values. The registered redirect URI at the
provider is `https://YOUR-SITE/api/auth/callback`.

On the KG ProDesign host, Google's answer to that URL is refused by the host's firewall (406 Not Acceptable,
because Google adds `iss=https://accounts.google.com`). Add a relay to the provider and register the relay URL at
Google instead; the relay forwards `code` and `state` to `/api/auth/callback`, and nothing else in the site changes
(ADR 0015 D18; KG ProDesign adds the site to the relay's list):

```toml
relay = "https://kgprodesign-tools.netlify.app/oidc/YOUR-SITE/callback"
```

The complete login (`functions/auth.php`, one function with four routes):

```php
<?php
// Login with Google / OpenID Connect (ADR 0015): one function, four routes.
//   GET /api/auth/login?provider=google&return_to=/account   starts the login
//   GET /api/auth/callback                                   the provider returns here (the registered redirect URI)
//   GET /api/auth/me                                         who is logged in
//   GET /api/auth/logout                                     ends the session
// Providers come from kgp.toml ([[auth.providers]]); KGP_AUTH_SECRET and the client vars from kgp env set.
kgp_method('GET');
switch (kgp_path()) {
    case '/login':
        kgp_oidc_login(kgp_query()['provider'] ?? 'fake', ['return_to' => kgp_query()['return_to'] ?? '/']);

    case '/callback':
        try {
            $id = kgp_oidc_callback();
        } catch (KgpOidcError $e) {
            // A stable code for the page to show; never the provider's body or any token.
            kgp_respond(400, ['error' => $e->errorCode]);
        }
        // Identity comes from the provider; access is the site's job (ADR 0015 D1). Link accounts by
        // (issuer, sub). Use the email only when $id['email_verified'] is true, and only to create a
        // new account or to attach after the logged-in user confirmed it; never to match an existing
        // account by itself.
        kgp_session_start(['provider' => $id['provider'], 'sub' => $id['sub'], 'email' => $id['email'], 'name' => $id['name']], 86400);
        kgp_redirect($id['return_to']);

    case '/me':
        $s = kgp_session();
        kgp_respond(200, $s === null ? ['logged_in' => false] : ['logged_in' => true] + $s);

    case '/logout':
        $s = kgp_session();
        kgp_session_end();
        kgp_respond(200, ['logged_in' => false, 'provider_logout' => $s === null ? null : kgp_oidc_logout_url($s['provider'], ['post_logout_redirect_uri' => '/'])]);
}
kgp_respond(404, ['error' => 'not_found']);
```

Errors are `KgpOidcError` with a stable `errorCode` (`$e->details` carries the specifics, never a secret):
`not_configured` (no or short `KGP_AUTH_SECRET`), `provider_unknown`, `provider_not_configured` (`details.var`),
`invalid_return_to`, `invalid_params` (a reserved authorize parameter), `discovery_failed` (`details.status`),
`jwks_failed`, `state_missing`, `state_mismatch`, `state_expired` (over 10 minutes), `provider_error`
(`details.error`, `error_description`: the user cancelled, `login_required` after `prompt=none`),
`token_exchange_failed` (`details.status`, `provider_error`), `id_token_invalid` (`details.reason`: `alg`,
`signature`, `issuer`, `audience`, `expired`, `nonce`, `unknown_kid`, ...), `session_too_large`. Uncaught, the
function answers 500 and `kgp functions logs` shows `[errorCode]`.

Provider notes. Google: discovery at the issuer, `email_verified` is a boolean, the `hd` claim names a Workspace
domain, `prompt = "select_account"` shows the chooser, `access_type = "offline"` returns `tokens.refresh_token`
(the site stores it, the platform does not). WordPress with miniOrange OAuth Server: issuer
`https://SITE/wp-json/moserver/CLIENT_ID` (one issuer per client), token errors come back as HTTP 200 bodies
(handled), no `prompt=none`, no logout URL (`kgp_oidc_logout_url()` is `null`), PKCE accepted but not enforced,
and `email_verified` is absent (treated as `false`).

Linking accounts: link by (`issuer`, `sub`). Use `email` only when `email_verified` is `true`, and only to create a
new account or to attach the identity after the logged-in user confirmed it; never match an existing account by
email alone (an unverified address from another provider would take it over).

Cookies: `kgp_oidc_state` lives on the callback path for 10 minutes; `kgp_session` is `HttpOnly`, `SameSite=Lax`,
`Secure` (not under `kgp dev`) and holds a signed copy of the data you pass, so keep ids in it, not profiles. Ending
a session clears the cookie; a session cannot be revoked before its `exp` from the server unless you keep a session
id in a table.

## Dependencies (vendor/)

A site may ship PHP libraries in `functions/vendor/` (agent 0.6.0+, ADR 0013). Run Composer locally, never on the
host and never from `kgp deploy`:

```sh
cd functions && composer require stripe/stripe-php --no-dev --classmap-authoritative
```

`kgp deploy` ships `functions/vendor/` as found on disk, skipping `vendor/bin/`, `.git`, dot files, `.ht*`, `.DS_Store`
and `Thumbs.db`; a symlink anywhere under `functions/` still fails the deploy. The runtime requires
`vendor/autoload.php` before every function, so `use Stripe\StripeClient;` works with no extra line. Vendor files
deploy with the release, are deduplicated by content hash (a second deploy with an unchanged `vendor/` uploads nothing
for it), roll back with the release, and are never routable (`/.kgp-fn/vendor/...` answers 404; `/api/vendor/...`
cannot name a file). Pin API versions in code as the Node app did (`'stripe_version' => '2024-06-20'`).

**Vendor-scoped strictness.** Site code keeps the strict handler of ADR 0003: every warning, notice or deprecation is a
500. A warning, notice or deprecation raised from a file under the release's `vendor/` is instead logged once per
release as `vendor notice: MESSAGE at vendor/PATH:LINE` (tag `(vendor)` in `kgp functions logs`) and the request
continues; a second request of the same release writes nothing. Exceptions and fatal errors from vendor code are still a
500, and `@`-suppressed errors stay suppressed. The rule is the raising file's path only: a function named `vendor.php`,
a `_shared/vendor.php` or an `eval()` in site code get no leniency.

**What is not checked.** The deploy's secret scan reads static files only; a runtime env value pasted into a vendor
file is not caught (vendor is trusted code like the functions themselves, ADR 0003 D3). `php -l` runs on functions and
`_shared/` only. `functions/composer.json` without `functions/vendor/autoload.php` is a warning
(`run composer install --no-dev`). When `vendor/composer/installed.json` requires an extension (`ext-gd`) that the
host's probe reports absent, the deploy warns `vendor_ext_missing: gd (needed by PACKAGE)`; extensions the probe
does not report are not mentioned. `kgp deploy --json --yes` reports `release_size` (files, bytes, vendor_files,
asset_files and the three limits) and warns once a value passes 50% of a limit; `kgp functions list --json --yes` reports
`vendor` and `assets`.

## Assets

Non-PHP files in `functions/_assets/` (the invoice logo, an email template, a JSON table) deploy with the release
under the same rules as `vendor/` and are read with `kgp_asset_path('logo.png')` (absolute path, for `image()` or
`file_get_contents`) or `kgp_asset('templates/welcome.html')` (the bytes). Names are relative, up to 8 segments of
letters, digits, dot, dash and underscore; no segment may start with a dot, and the resolved path must stay under
`_assets/` (symlinks out of it are refused). A bad name throws `KgpFnError` `invalid_asset`, a missing file
`asset_not_found`; both are a 500 with the code in the log. PHP files under `_assets/` are refused at deploy time. Under
`kgp dev` the project's `functions/_assets/` is read directly.

## Kit

The runtime ships two modules, no Composer needed (ADR 0013 D4, D5).

**JWT (HS256).** `kgp_jwt_sign(array $claims, string $secret, array $opts = [])` returns a compact token with the header
`{"alg":"HS256","typ":"JWT"}`; `iat` is added unless the claims carry one (`$opts['iat']` or `now`), `exp` from
`$opts['ttl']` seconds unless given, `nbf` from `$opts['nbf']`. `kgp_jwt_verify(string $jwt, string $secret, array
$opts = [], ?string &$reason = null): ?array` returns the claims or `null` with `$reason` one of `malformed` (not three
parts, over 8 KiB, bad base64, a list payload), `alg` (anything but HS256, including `none`, or a `crit` header),
`signature`, `expired`, `not_yet_valid`, `claims` (non-numeric `exp`/`nbf`/`iat`, or an `iss`, `aud`, `sub` expectation
not met; `aud` may be a list). `$opts`: `leeway` (seconds), `iss`, `aud`, `sub`, `now`. The signature is checked with
`hash_equals()` before any claim is read. An empty secret throws `jwt_secret`. Tokens interoperate with jsonwebtoken 9:
the same claims in the same key order with the same secret give the same bytes, so admin, portal and magic-link
tokens keep verifying across a cutover. `password_verify()` accepts bcryptjs `$2a$` hashes and bcryptjs accepts PHP's
`$2y$` (ADR 0010 SP6), so password hashes need no rewrite either.

```php
$token = kgp_jwt_sign(['sub' => $user['id'], 'email' => $user['email'], 'role' => 'admin'], kgp_env('JWT_SECRET'), ['ttl' => 86400]);
$claims = kgp_jwt_verify((string) kgp_header('authorization') ? substr(kgp_header('authorization'), 7) : '', kgp_env('JWT_SECRET'), ['leeway' => 30], $reason);
if ($claims === null) {
    kgp_respond(401, ['error' => 'unauthorized', 'reason' => $reason]);
}
```

**PDF.** `kgp_pdf(['orientation' => 'P', 'unit' => 'mm', 'size' => 'A4'])` returns a `KgpPdf` over FPDF 1.9 with
jsPDF-like names, each returning the document for chaining: `addPage()`, `setFont($family, $style, $size)` (core fonts
Helvetica, Times, Courier, Symbol, ZapfDingbats; `B`, `I`, `BI`), `setFontSize()`, `setTextColor($r, $g, $b)`,
`setDrawColor()`, `setFillColor()`, `setLineWidth()`, `text($x, $y, $str)`, `textWidth($str)`, `splitText($str,
$maxWidth): array` (like `splitTextToSize`), `rect($x, $y, $w, $h, $style)` (`''`, `'F'`, `'DF'`), `line()`,
`image($path, $x, $y, $w, $h)` (JPEG or PNG; `$path` from `kgp_asset_path()` is the portable form), `pages()`,
`bytes()`, and `fpdf()` for the underlying object. Text is UTF-8 and is transliterated to Windows-1252 (`é` stays,
`–` becomes `-`, unknown characters become `?`). An FPDF error (unknown font, unreadable image) is `KgpFnError`
`pdf_error` with FPDF's message. An alpha-channel PNG is flattened by FPDF into an SMask (zlib is on the host); TrueType
fonts are not bundled. TCPDF is not in the kit: 25 MB of fonts, a deprecation on load, and HTML error output; a site
that wants it can ship it in `vendor/`.

```php
$p = kgp_pdf();
$p->addPage()->image(kgp_asset_path('logo.png'), 10, 10, 30);
$p->setFont('Helvetica', 'B', 16)->text(50, 20, "Invoice {$invoice['number']}");
$p->setFont('Helvetica', '', 10)->setTextColor(80, 80, 80);
$y = 40;
foreach ($p->splitText($invoice['notes'], 90) as $line) {
    $p->text(10, $y, $line);
    $y += 5;
}
kgp_send(200, $p->bytes(), 'application/pdf', ['Content-Disposition' => 'attachment; filename="invoice.pdf"']);
```

## Example: a contact form

```php
<?php
kgp_cors([kgp_env('SITE_URL', '')]);   // unset SITE_URL allows no other origins (same-origin calls still work)
kgp_method('POST');
kgp_rate_limit('contact', 5, 900);
$b = kgp_json_body();
if (($b['website'] ?? '') !== '') {          // honeypot field: pretend it worked
    kgp_respond(200, ['ok' => true]);
}
$email = filter_var($b['email'] ?? '', FILTER_VALIDATE_EMAIL);
$message = trim((string) ($b['message'] ?? ''));
if ($email === false || strlen($message) < 10 || strlen($message) > 5000) {
    kgp_respond(400, ['error' => 'validation_error']);
}
$sent = kgp_send_email([
    'to' => kgp_env('CONTACT_TO'),
    'subject' => 'New message from ' . str_replace(["\r", "\n"], ' ', (string) ($b['name'] ?? 'a visitor')),
    'text' => $message,
    'reply_to' => $email,
]);
kgp_respond($sent ? 200 : 503, $sent ? ['ok' => true] : ['error' => 'send_failed']);
```

## Porting a Netlify (Node) function

1. Keep the same path, method, status codes, JSON fields, rate limits and honeypot order; the site's front end
   depends on them. Keep `/.netlify/functions/...` call sites working with `[functions] netlify_compat = true`.
2. Secrets the Node code read from `process.env` become `kgp_env()`; the owner sets them with `kgp env set NAME < file`.
   A value that is also in the browser bundle (`VITE_STRIPE_PUBLISHABLE_KEY`) is set with `--public`, or the deploy
   fails with `secret_in_build`. Build-only `VITE_*` values stay in a committed `.env.production`.
3. `fetch()` becomes `kgp_fetch()` (pass `follow_redirects` when the Node code relied on fetch following redirects,
   for example Google Apps Script URLs). `context.waitUntil()` becomes `kgp_defer()`.
4. MailerSend calls become `kgp_send_email()`. Put the client's company name in `kgp.toml` (`[mail] from_name = "Acme Co"`) or pass `from_name` per message; replies go to `reply_to`.
5. Database routes: `query(text, params)` becomes `kgp_pg_query($text, $params)`; `` sql`...` `` tagged templates become
   `$1` placeholders with a params list; `result.rows` is the return value (`kgp_pg_one()` for `rows[0]`); `error.code`
   becomes `$e->sqlstate` and `error.constraint` becomes `$e->constraint` (see "Postgres"). The owner sets `DATABASE_URL`
   with `kgp env set DATABASE_URL < file`; nothing else changes for a Neon URL.
6. Legacy `exports.handler(event, context)` fields map to helpers:

| Netlify event / response | KGP Host |
|---|---|
| `event.httpMethod` | `$_SERVER['REQUEST_METHOD']`, or `kgp_method(...)` to enforce |
| `event.path` after the function name | `kgp_path()` |
| `event.headers['x-y']` (lower-cased) | `kgp_header('x-y')`, `kgp_headers()` |
| `event.queryStringParameters` | `kgp_query()` |
| `event.multiValueQueryStringParameters` | `kgp_query_all()` |
| `event.body`, `isBase64Encoded` | `kgp_raw_body()` (bytes as sent), `kgp_json_body()`, `kgp_form_body()` |
| `process.env.URL`, `SITE_NAME`, `CONTEXT` | `kgp_env('URL')`, `kgp_env('SITE_NAME')`, `kgp_env('CONTEXT')` |
| `{ statusCode, body: JSON.stringify(x) }` | `kgp_respond($status, $x)` |
| `{ statusCode, headers: {'Content-Type': ...}, body, isBase64Encoded: true }` | `kgp_send($status, $bytes, $type)` |
| `multiValueHeaders: { 'Set-Cookie': [...] }` | one `kgp_set_cookie()` per cookie |
| `{ statusCode: 302, headers: { Location } }` | `kgp_redirect($url)` |
| `context.waitUntil(p)` | `kgp_defer(fn () => ...)` |
| `[functions."NAME"] schedule = "0 9 * * *"` in netlify.toml | `[[schedules]] function = "NAME" cron = "0 9 * * *"` in kgp.toml (15-minute grid; `kgp_is_scheduled()` replaces `event.body.next_run` checks) |

## Testing locally

`kgp dev` builds the site and serves it on this machine (port 8888, `--port` to change) with PHP's built-in server: static files,
redirects, the SPA fallback, and `/api/*` through the same runtime. Env comes from `.env.kgp-dev` in the project
(never commit it); mail is printed to the terminal instead of sent.

Database functions need a `DATABASE_URL` line in `.env.kgp-dev`. The repo's harness Postgres (`pnpm harness:up`,
Postgres 16 on `127.0.0.1:5432`) works with the `pdo` driver and a local `pdo_pgsql`:

```sh
DATABASE_URL=postgresql://postgres:harnesspg@127.0.0.1:5432/kgp?sslmode=disable
```

A Neon branch URL works too (the `http` driver is picked for `.neon.tech` hosts); use a branch, never production.

Login functions need `KGP_AUTH_SECRET` and the client vars in `.env.kgp-dev` as well. The repo's harness runs a fake
provider at `http://127.0.0.1:2083/oidc` (client `kgp-test-client`, secret `kgp-test-secret-0123456789abcdef`, one
user) that `kgp dev` can log in against with `issuer = "http://127.0.0.1:2083/oidc"` in `kgp.toml`; the registered
redirect is `http://127.0.0.1:8888/api/auth/callback`. Under `kgp dev` (`CONTEXT=dev`) the cookies carry no
`Secure`, so a browser accepts them on plain http. For Google, add `http://127.0.0.1:8888/api/auth/callback` to
the OAuth client's redirect URIs.

## Trust model

Functions run as the same account user as the KGP agent. They are trusted code: anyone who can deploy can read what
the agent can. Review function code like server code.
