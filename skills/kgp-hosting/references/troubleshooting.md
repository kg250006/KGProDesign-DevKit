# Troubleshooting KGP-hosted sites

## Doctor checks (`kgp instance doctor --json --yes`)

| Check id | Fails when | Fix |
|---|---|---|
| `registration` | The platform domain expires within 30 days (warns within 60). | The owner renews it at the registrar. |
| `delegation` | Public nameservers differ from the zone's NS records. With `dns_authority = "external"` it only reports them. | The owner updates nameservers at the registrar. |
| `zone_sync` | Live nameservers serve different records than cPanel's zone. | Send the check's `fix` text to the host's support. |
| `write_test` | A test DNS record written in cPanel never reaches the nameservers. | Same as `zone_sync`. |
| `acme_alias` | `_acme-challenge.PLATFORM_DOMAIN` does not CNAME to `_acme-challenge.ALIAS`, no cPanel zone holds the alias, or a TXT record written there does not reach its nameservers (ADR 0007). | The owner adds the CNAME at the platform domain's public DNS (not cPanel's Zone Editor), per the check's `fix`. |
| `no_proxy` | A name resolves through a proxy or CDN (SiteLock, Cloudflare). | The owner removes the proxy records. |
| `agent_health` | The agent is down, rejects the secret, or belongs to another platform domain. | `kgp server init` (owner). |
| `agent_version` | The server's agent differs from the CLI's bundled one. | `kgp server upgrade` (owner). |
| `rewrite` | Requests do not reach the agent (mod_rewrite or `.htaccess` disabled). | Contact the host. |
| `ssl` | A site or agent host has no certificate, or one expires within 14 days. With `site_addressing = "wildcard"` the `*.PLATFORM_DOMAIN` certificate is required (fail under 7 days, warn under 14); otherwise its absence is only a warning. | Wildcard: `kgp server cert status`, then the owner runs `kgp server cert run` (docs/runbooks/wildcard-certificate.md). Others: AutoSSL in cPanel; custom domains need their DNS record first. |
| `folder_isolation` | Site folders are inside the main domain's document root (warning). | Informational. |
| `primary_domain` | The platform domain is the account's primary domain (warning). | Informational; affects mail moves. |
| `reserved_names` | A site uses a reserved name, or a non-KGP subdomain exists. | Rename or remove it (owner). |
| `custom_hosts` | Wildcard addressing only (ADR 0008): the platform folder's `.htaccess` does not match the site records, a custom domain has no cPanel domain, or one points somewhere other than the platform folder or its site folder. Warns for a domain still at its site folder. | `kgp server wildcard` (owner); for a missing cPanel domain, `kgp domains add DOMAIN --site SITE` (owner). |

## Common symptoms

- **"Nothing lives here." (404, `X-KGP-No-Site: 1`) on a site that exists**: the router found no `sites/SITE/.htaccess`. The site has never been published, or was deleted. Deploy it (`kgp deploy --prod`), or ask the owner to run `kgp server upgrade` (it re-renders every site's rules).
- **Every `*.PLATFORM_DOMAIN` site shows a certificate error at once**: the wildcard certificate expired or renewal failed. `kgp server cert status --json --yes` shows `days_left` and the last run; the owner fixes it (runbook wildcard-certificate.md).

- **A new site redirects to `/404.html` for a few minutes**: new subdomains take about 3 minutes to go live on the host. `kgp sites create` waits up to 5 minutes; re-run `kgp sites info SITE --json --yes` later if it gave up.
- **The browser warns about the certificate on a new site**: AutoSSL is still issuing it. Wait, then reload. Do not switch to `http://`.
- **404 for a page that exists**: you used the wrong host. Each site answers only on `SITE.PLATFORM_DOMAIN` (and its custom domains). Paths like `https://sitepage.app/sites/SITE/` always return 404.
- **403 or 404 for `/releases/...`**: release folders are never addressable directly. Use the site's normal URLs.
- **Exit 5 (upload failed)**: re-run the same `kgp deploy`; it uploads only what is still missing.
- **Exit 6 with `details.state` = `rolled_back`**: verification failed and the previous release is live again. Read `details.verification.checks` to see which check failed.
- **Exit 7 mentioning secrets**: remove the named key from `kgp.toml`.
- **A function answers 500 `{"error":"internal"}`**: run `kgp functions logs --json --yes`. `[mail_not_configured]` means the owner has not run `kgp server mail set`; `[fetch_refused]` means a non-https URL; `[invalid_email]` means `kgp_send_email()` was called without `to`, `subject`, and `text` or `html`.
- **A form says it sent but no mail arrived**: run `kgp mail log --json --yes`. `failed` `provider_error` means MailerSend refused it (`provider_status`); `failed` `network_error` means MailerSend was unreachable; `rejected` `abuse_limit` means the sender is blocked (`kgp mail blocks --json --yes`) or over a cap (`kgp mail limits --json --yes`). Changing blocks or caps is an owner decision.
- **A form answers 503 for one visitor but works for others**: the visitor's IP or network hash is blocked or over a cap; `kgp mail log --status rejected --json --yes` shows `abuse_limit` entries with the sender's `ip_hash`.
- **`wp_sync: "pending"` in `kgp mail log`**: the entry has not reached WordPress yet. Pushes retry on later sends. Run `kgp mail wp test --json --yes`: `rest_not_logged_in` or 401 means a wrong user or application password; `site_match: false` means the plugin's KGP site name (Tools > Email log on that WordPress site) is different.
- **WordPress answers 403 `site_mismatch` to pushes**: the service user was added to the wrong subsite, or `kgp_email_log_site` on the subsite does not match the KGP site name. Fix it in Tools > Email log on the right subsite.
- **429 `rate_limited` from a function**: the function's `kgp_rate_limit()` window is full for that IP; wait for `Retry-After` seconds.
- **`/api/...` answers 404 after a rollback or deploy**: the live release has no `functions/` folder, or the file name does not match the path.
- **Exit 4 `function_syntax`**: PHP syntax error in the named function; fix it locally (`php -l functions/NAME.php`).
- **Exit 7 `secret_in_build`**: a runtime env value is in the static build (often a `VITE_*` variable). Remove it from the build; keep the env var.
- **Exit 7 naming `_redirects:N` or `kgp.toml redirects[N]`**: that redirect uses something unsupported (conditions, signing, query matching, proxying).
- **`kgp domains add` says "waiting for customer DNS"**: the domain owner has not set the printed record yet, or it has not propagated. Re-check with `kgp domains status DOMAIN --json --yes`. The certificate follows once DNS reaches the server.
- **Certificate `pending` after `kgp sites create` or `kgp domains add`**: AutoSSL is still working (minutes, sometimes longer). Do not switch to `http://`.
