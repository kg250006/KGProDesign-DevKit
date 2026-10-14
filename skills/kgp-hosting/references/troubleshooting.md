# Troubleshooting KGP-hosted sites

## Doctor checks (`kgp instance doctor --json --yes`)

| Check id | Fails when | Fix |
|---|---|---|
| `registration` | The platform domain expires within 30 days (warns within 60). | The owner renews it at the registrar. |
| `delegation` | Public nameservers differ from the zone's NS records. | The owner updates nameservers at the registrar. |
| `zone_sync` | Live nameservers serve different records than cPanel's zone. | Send the check's `fix` text to the host's support. |
| `write_test` | A test DNS record written in cPanel never reaches the nameservers. | Same as `zone_sync`. |
| `no_proxy` | A name resolves through a proxy or CDN (SiteLock, Cloudflare). | The owner removes the proxy records. |
| `agent_health` | The agent is down, rejects the secret, or belongs to another platform domain. | `kgp server init` (owner). |
| `agent_version` | The server's agent differs from the CLI's bundled one. | `kgp server upgrade` (owner). |
| `rewrite` | Requests do not reach the agent (mod_rewrite or `.htaccess` disabled). | Contact the host. |
| `ssl` | A certificate is missing or expires within 14 days. | The owner runs AutoSSL in cPanel; then wait. |
| `folder_isolation` | Site folders are inside the main domain's document root (warning). | Informational. |
| `primary_domain` | The platform domain is the account's primary domain (warning). | Informational; affects mail moves. |
| `reserved_names` | A site uses a reserved name, or a non-KGP subdomain exists. | Rename or remove it (owner). |

## Common symptoms

- **A new site redirects to `/404.html` for a few minutes**: new subdomains take about 3 minutes to go live on the host. `kgp sites create` waits up to 5 minutes; re-run `kgp sites info SITE --json --yes` later if it gave up.
- **The browser warns about the certificate on a new site**: AutoSSL is still issuing it. Wait, then reload. Do not switch to `http://`.
- **404 for a page that exists**: you used the wrong host. Each site answers only on `SITE.PLATFORM_DOMAIN` (and its custom domains). Paths like `https://sitepage.app/sites/SITE/` always return 404.
- **403 or 404 for `/releases/...`**: release folders are never addressable directly. Use the site's normal URLs.
- **Exit 5 (upload failed)**: re-run the same `kgp deploy`; it uploads only what is still missing.
- **Exit 6 with `details.state` = `rolled_back`**: verification failed and the previous release is live again. Read `details.verification.checks` to see which check failed.
- **Exit 7 mentioning secrets**: remove the named key from `kgp.toml`.
