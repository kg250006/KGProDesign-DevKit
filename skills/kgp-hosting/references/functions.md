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

Names are lower-case `a-z`, `0-9`, `_` and `-` (no dots, so not `x.generated.php`), at most 64 characters, one level deep (plus `_shared/`). Each file is
at most 1 MiB. A release without functions answers 404 for every `/api/*` path.

## Helpers

| Helper | What it does |
|---|---|
| `kgp_method('POST', ...)` | Ends with 405 and an `Allow` header for any other method. |
| `kgp_path()` | The path after `/api/NAME` (`""` when none). |
| `kgp_json_body($max = 65536)` | The body as a JSON object; ends with 400 `invalid_json` or 413 `too_large`. |
| `kgp_respond($status, $array, $headers = [])` | Sends JSON (`Cache-Control: no-store`) and ends the function. |
| `kgp_env('NAME', $default)` | A runtime env var (set with `kgp env set`). |
| `kgp_cors([$origin, ...], $methods, $credentials)` | Allows only the listed origins; answers preflight `OPTIONS` with 204. Never `*`. |
| `kgp_rate_limit('bucket', $max, $windowSeconds)` | Fixed window per bucket and client IP; ends with 429 `rate_limited` and `Retry-After`. |
| `kgp_send_email(['to', 'subject', 'text' or 'html', 'reply_to', 'from_name'])` | Sends through the instance's MailerSend sender; returns `true` when accepted. The sender name is `from_name`, else `[mail] from_name` in `kgp.toml`, else the instance's ("KGP Mailer"). The From address is always the platform's verified one. |
| `kgp_fetch($method, $url, ['headers', 'json' or 'body', 'timeout', 'follow_redirects'])` | Outbound HTTPS. Returns `['status', 'headers', 'body']`; status 0 means the request failed. |
| `kgp_mail_configured()` | `true` when the instance mail sender is set up (`kgp server mail set`). |
| `kgp_defer(fn () => ...)` | Runs after the response is sent (Netlify's `waitUntil`). |
| `kgp_client_ip()` | The caller's IP (`REMOTE_ADDR`; forwarded headers are not trusted). |
| `kgp_log('message')` | One line in `kgp functions logs`. Never log secrets or form contents. |

`kgp_respond()` ends the function by throwing; do not wrap it in `catch (Throwable)`. Uncaught errors and warnings
return `{"error":"internal"}` with status 500 and add one line to `kgp functions logs`.

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
   depends on them.
2. Secrets the Node code read from `process.env` become `kgp_env()`; the owner sets them with `kgp env set NAME < file`.
   Public `VITE_*` values are build-time only; pass them to the function through a build step or keep them in the SPA.
3. `fetch()` becomes `kgp_fetch()` (pass `follow_redirects` when the Node code relied on fetch following redirects,
   for example Google Apps Script URLs). `context.waitUntil()` becomes `kgp_defer()`.
4. MailerSend calls become `kgp_send_email()`. Put the client's company name in `kgp.toml` (`[mail] from_name = "Acme Co"`) or pass `from_name` per message; replies go to `reply_to`.
5. Database-backed routes cannot be ported yet (no site databases).

## Testing locally

`kgp dev` builds the site and serves it on this machine (port 8888, `--port` to change) with PHP's built-in server: static files,
redirects, the SPA fallback, and `/api/*` through the same runtime. Env comes from `.env.kgp-dev` in the project
(never commit it); mail is printed to the terminal instead of sent.

## Trust model

Functions run as the same account user as the KGP agent. They are trusted code: anyone who can deploy can read what
the agent can. Review function code like server code.
