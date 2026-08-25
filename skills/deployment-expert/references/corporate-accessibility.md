# Corporate Network Accessibility

Knowledge base for hardening new sites against enterprise web filters and proxies.
Loaded by `workflows/corporate-accessibility-hardening.md`.

<problem>
## Why new sites break on corporate networks

A site can render perfectly on a personal/consumer network yet appear **broken,
unstyled, or blocked** on a corporate/enterprise network. This is not a code defect —
it is how enterprise web filters and proxies treat brand-new domains and certain
hosting configurations. Clients' boards, corporate donors, grant offices, and B2B
buyers frequently review sites from **locked-down work computers**, so this undermines
confidence in an otherwise finished site.

**Typical symptoms:**
- Page loads but appears **unstyled** (fonts/CSS/JS stripped).
- Site is **fully blocked** with a corporate "access denied / uncategorized" interstitial.
- Images, embedded media, or web fonts fail to load while HTML text shows.

### Three root causes

1. **Uncategorized / new-domain reputation.** Enterprise filters (Zscaler, Cisco
   Umbrella / Talos, Palo Alto, Forcepoint, Sophos, Symantec/Broadcom, Netskope,
   DNSFilter, etc.) assign every domain a category. A brand-new domain defaults to
   **"uncategorized,"** and many policies block or degrade uncategorized sites. When
   degraded rather than blocked, the HTML passes but **sub-resources are stripped** →
   the "loads but unstyled" symptom.

2. **Shared-host / free-subdomain distrust.** Sites served from shared free-hosting
   namespaces (`*.netlify.app`, `*.vercel.app`, `*.web.app`, `*.github.io`) are
   frequently **blocked wholesale** because those namespaces are abused by spammers and
   phishers. The individual site's content is irrelevant — the filter distrusts the
   parent namespace.

3. **Missing / weak security posture.** Sites lacking a standard security-header set,
   valid TLS/HSTS, or that pull many third-party external resources **score lower** in
   reputation engines and give strict filters more surface to strip or flag.
</problem>

<what_we_do_not_control>
## Best effort, not a warranty

Corporate proxies and web filters are configured and operated by the **client's or
visitor's own IT department and third-party filtering vendors** — entirely outside our
control. Every organization configures filters differently, and some block by policy in
ways **no website configuration can override.** We commit to **best efforts / best
practices** to maximize compatibility, but **cannot guarantee** that any specific
corporate network, proxy, or filter will permit or fully render the site.

The client-facing version of this caveat lives in
`small-business-legal-advisor` (service-agreement template, §6.4 Corporate Network
Accessibility, immediately following the Warranties/Disclaimer section).
Every deploy that runs this hardening writes the caveat into the deploy record and the
proposal/SOW (see M7 below).
</what_we_do_not_control>

<mitigations>
## Mitigations (what we control)

| # | Mitigation | Why it helps | Enforced at |
|---|-----------|--------------|-------------|
| M1 | **Deploy on the client's own custom domain** — never ship a `*.netlify.app`/shared subdomain as the presented URL. | Removes shared-namespace distrust (cause #2). | Profile setup / deploy |
| M2 | **Ship a hardened security-header set** from day one (see below). | Raises reputation-engine trust (cause #3); no external surface to strip. | Deploy (headers config) |
| M3 | **Self-host fonts; minimize/remove third-party external resources.** | A strict filter has nothing external to block/strip → no "unstyled" symptom. | Build config |
| M4 | **Serve valid HTTPS/TLS + HSTS.** | Baseline trust; blocks downgrade. | Deploy |
| M5 | **Pre-submit the domain for categorization** to major filter vendors BEFORE launch. | Directly fixes the "uncategorized" default (cause #1). | Pre-launch |
| M6 | **Verify from a corporate-like environment** (VPN/proxy/second machine) before handoff. | Catches the symptom before the client does. | Post-deploy |
| M7 | **Document what was done + no-guarantee caveat** in the deploy record and client outputs. | Sets expectations; proof of best effort. | Deploy record + proposal/SOW |
</mitigations>

<security_headers>
## Baseline security-header set (M2)

The proven header set. Ship all of these on every route. Templates for each platform
live in `templates/security-headers.*.template`.

| Header | Value |
|--------|-------|
| `X-Frame-Options` | `DENY` |
| `X-XSS-Protection` | `1; mode=block` |
| `X-Content-Type-Options` | `nosniff` |
| `Referrer-Policy` | `strict-origin-when-cross-origin` |
| `Strict-Transport-Security` | `max-age=31536000; includeSubDomains; preload` |
| `Permissions-Policy` | `geolocation=(), microphone=(), camera=()` |
| `Cache-Control` | `public, max-age=0, must-revalidate` |

### Netlify — `netlify.toml`
```toml
[[headers]]
  for = "/*"
  [headers.values]
    X-Frame-Options = "DENY"
    X-XSS-Protection = "1; mode=block"
    X-Content-Type-Options = "nosniff"
    Referrer-Policy = "strict-origin-when-cross-origin"
    Strict-Transport-Security = "max-age=31536000; includeSubDomains; preload"
    Permissions-Policy = "geolocation=(), microphone=(), camera=()"
    Cache-Control = "public, max-age=0, must-revalidate"
```
Netlify can also read a `_headers` file (`templates/security-headers.netlify.template`).

### nginx (Azure VM / NPM / self-hosted) — inside the `server` block
```nginx
add_header X-Frame-Options "DENY" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header X-Content-Type-Options "nosniff" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
add_header Permissions-Policy "geolocation=(), microphone=(), camera=()" always;
```
See `templates/security-headers.nginx.template`. In Nginx Proxy Manager, add these under
the proxy host's **Advanced → Custom Nginx Configuration** and reload NPM.

### GitHub-production (Docker + NPM)
Headers are served by the same NPM/nginx layer — use the nginx snippet above in the
proxy host config.

### Content-Security-Policy (optional / advanced)
A CSP header further raises trust but **must be tuned per-site** from the actual resource
inventory to avoid breaking legitimate resources. Treat as a phase-2 enhancement; do not
ship an untuned CSP.
</security_headers>

<font_self_hosting>
## Self-hosting fonts & removing external resources (M3)

A strict filter strips third-party sub-resources (fonts, CDN CSS/JS), producing the
"loads but unstyled" symptom. The fix is to serve everything first-party.

- **Fonts:** self-host rather than loading from the Google Fonts CDN. The KG ProDesign
  self-hosting recipe (Sora `@font-face` + local `woff2`) is the source of truth in the
  `kgprodesign-branding` skill → `references/typography.md` (self-hosting section). Do
  not duplicate it here — follow that recipe.
- **Other external resources:** audit the built output for external hosts (analytics,
  icon CDNs, embedded widgets, image CDNs). Bundle or self-host anything on the critical
  render path. Keep an `externalResourceAllowlist` in the deployment profile for hosts
  that must remain external (record why).
</font_self_hosting>

<categorization_vendors>
## Filter-vendor categorization submission (M5)

Each vendor offers a free "request categorization / site review" form. Submit the
**custom domain** BEFORE launch. Suggested category: **Business / Nonprofit / Charity**
(match the site's actual purpose). Log the submission date + confirmation link into the
profile's `corporateAccessibility.categorizationSubmitted` map.

| Vendor | Submission point |
|--------|------------------|
| Zscaler | Site Review / URL categorization request |
| Cisco Talos / Umbrella | Talos reputation dispute + Umbrella domain categorization |
| Palo Alto Networks | URL categorization / "Test A Site" |
| Forcepoint | URL category submission |
| Symantec / Broadcom (BlueCoat) | Site Review |
| Netskope | URL category submission |
| DNSFilter | Domain categorization / review |
| Fortinet (FortiGuard) | Web filter category submission |
| Trend Micro | Site Safety Center |

This is a **guided manual checklist** — vendor forms use captchas and lack stable APIs,
so submissions are performed by hand and their results logged, not scripted.
</categorization_vendors>

<verification>
## Verifying the hardening (M2 + M4)

Assert the live response carries the full header set and is served over HTTPS from the
custom domain:

```bash
curl -sS -D - -o /dev/null https://<custom-domain> | grep -iE \
  'x-frame-options|x-content-type-options|referrer-policy|strict-transport-security|permissions-policy'
```

All five must be present. This is the same assertion `workflows/post-deploy-health.md`
runs (and fails the health check on if headers are missing). For a corporate-like render
check (M6), load the site through a filtering VPN/proxy or a second locked-down machine
before handoff and record the result to `corporateAccessibility.corporateVerified`.
</verification>
