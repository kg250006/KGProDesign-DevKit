<required_reading>
Read references/corporate-accessibility.md for the root causes, header set, and vendor list.
This workflow applies and verifies mitigations M1–M7 during a site build/deploy.
Run it before handing a new site to the client.
</required_reading>

<overview>
## Corporate Network Accessibility Hardening

Makes a new site corporate-network-hardened by default: custom domain, security headers,
self-contained resources, HTTPS/HSTS, pre-launch filter categorization, corporate-like
verification, and a documented best-effort caveat.

**This is a mitigation, not a warranty** — corporate filters are outside our control
(see references/corporate-accessibility.md → what_we_do_not_control).
</overview>

<process>
## Step 1: Confirm custom domain (M1)

The presented URL must be the client's own custom domain — never a shared subdomain.

```bash
URL=$(jq -r '.verification.url' .deployment-profile.json)
case "$URL" in
  *.netlify.app|*.vercel.app|*.web.app|*.github.io|*.pages.dev)
    echo "⚠️  BLOCKER: presented URL '$URL' is a shared free-host subdomain."
    echo "    Corporate filters block these wholesale. Set up the custom domain first." ;;
  https://*) echo "✓ Custom domain: $URL" ;;
  *) echo "⚠️  URL not set or not HTTPS: '$URL'" ;;
esac
```

**If a shared subdomain:** warn loudly and stop. Configure the custom domain (DNS +
platform domain binding) before continuing. Do not hand a `*.netlify.app`-class URL to
the client.

Record: set `corporateAccessibility.customDomainRequired = true`.

## Step 2: Apply security headers (M2)

Detect the platform and drop in the matching header template from
`templates/security-headers.*.template`:

- **Netlify** → add the `[[headers]]` block to `netlify.toml`, or copy
  `security-headers.netlify.template` to `_headers` in the publish directory.
- **Azure VM / GitHub-production (nginx / NPM)** → add `security-headers.nginx.template`
  to the `server` block (or NPM proxy host → Advanced → Custom Nginx Configuration), then
  reload nginx/NPM.
- **FTP / static host** → use the host's header mechanism (e.g. `.htaccess` for Apache)
  with the same header set.

Record: `corporateAccessibility.securityHeadersApplied = true`.

## Step 3: Scan for external resources; self-host (M3)

Scan the built output for external hosts on the critical render path:

```bash
# Adjust the build dir (dist/out/build) to match the profile's build.output
BUILD_DIR=$(jq -r '.build.output // "dist"' .deployment-profile.json)
grep -rhoE 'https?://[a-zA-Z0-9.-]+' "$BUILD_DIR" 2>/dev/null \
  | sed -E 's#https?://([^/]+).*#\1#' | sort -u
```

Flag any host not in `corporateAccessibility.externalResourceAllowlist`. For each flagged
host, self-host or bundle it. **Fonts especially** — follow the self-hosting recipe in
`kgprodesign-branding` → `references/typography.md` (self-hosting section) instead of the
Google Fonts CDN.

Record: `corporateAccessibility.fontsSelfHosted = true` once fonts are local; keep the
allowlist current with any host that must stay external (and why).

## Step 4: Confirm HTTPS + HSTS (M4)

```bash
URL=$(jq -r '.verification.url' .deployment-profile.json)
curl -sS -D - -o /dev/null "$URL" | grep -iE 'strict-transport-security'
```

Must return the HSTS header, and the URL must be `https://`. If TLS isn't live yet
(fresh domain), provision the certificate (platform-managed or Let's Encrypt) first.

## Step 5: Submit domain for categorization (M5)

Emit the vendor submission list with the domain + suggested category pre-filled. This is
a **guided manual checklist** (vendor forms have captchas / no stable API):

```
Submit https://<custom-domain> for categorization — suggested category:
Business / Nonprofit / Charity (match the site's actual purpose).

  [ ] Zscaler — Site Review
  [ ] Cisco Talos / Umbrella — reputation + domain categorization
  [ ] Palo Alto Networks — URL categorization / Test A Site
  [ ] Forcepoint — URL category submission
  [ ] Symantec / Broadcom (BlueCoat) — Site Review
  [ ] Netskope / DNSFilter / Fortinet / Trend Micro — as applicable
```

See references/corporate-accessibility.md → categorization_vendors for the links. For
each vendor submitted, log the date + confirmation link:

```json
"categorizationSubmitted": {
  "zscaler": "2026-08-24 — <confirmation link>",
  "cisco": null, "paloAlto": null, "forcepoint": null, "symantec": null
}
```

## Step 6: Corporate-like accessibility check (M6)

Load the live site through a corporate-like environment before handoff:
a filtering VPN/proxy, a dedicated locked-down test machine, or a filter-simulation
service. Confirm it renders **fully styled** (no stripped fonts/CSS/JS) and is not blocked.

Record: `corporateAccessibility.corporateVerified = true` and
`lastVerifiedAt = <timestamp>`.

## Step 7: Write hardening record + caveat (M7)

Append a hardening record to the deploy log (or the profile `history[]`) noting which of
M1–M7 were applied, the categorization submission dates, and the verification result.

Generate/point to the client-facing best-effort caveat: the proposal paragraph and SOW
one-liner live in `small-business-legal-advisor` → the service-agreement template
(Corporate Network Accessibility clause). Include the caveat in the proposal/SOW.
</process>

<verification>
Assert the full header set + HTTPS from the custom domain (same check post-deploy-health runs):

```bash
URL=$(jq -r '.verification.url' .deployment-profile.json)
curl -sS -D - -o /dev/null "$URL" | grep -iE \
  'x-frame-options|x-content-type-options|referrer-policy|strict-transport-security|permissions-policy'
```

All five headers present + `https://` custom domain = hardening verified.
</verification>

<success_criteria>
A site is corporate-network hardened when all are true and recorded in the profile:
- [ ] AC1 — Presented URL is a custom domain (no shared `*.netlify.app`-class URL).
- [ ] AC2 — Live response returns the full security-header set.
- [ ] AC3 — No external resource hosts except an approved allowlist; fonts self-hosted.
- [ ] AC4 — Served over valid HTTPS with HSTS.
- [ ] AC5 — Domain submitted for categorization; dates/links logged.
- [ ] AC6 — Verified rendering correctly from a corporate-like environment; result logged.
- [ ] AC7 — Hardening record + no-guarantee caveat written to the deploy log and proposal/SOW.
</success_criteria>
