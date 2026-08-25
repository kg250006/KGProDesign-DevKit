# PRD: Corporate Network Accessibility Hardening

**Status:** Proposed
**Owner:** KG ProDesign
**Target Plugin:** KGProDesign-DevKit (KGP Plugin)
**Primary Skill to Enhance:** `deployment-expert`
**Supporting Skills:** `software-architect` (PRP/scope language), `regression-testing` / `ui-visual-testing` (verification), `kgprodesign-branding` (font self-hosting)
**Created:** 2026-08-24
**Version:** 1.0

---

## 1. Summary

New websites we build can render perfectly on a personal/consumer network yet appear
**broken, unstyled, or blocked** on a corporate/enterprise network. This is not a bug in
our code and not malware — it is how enterprise web filters and proxies treat brand-new
domains and certain hosting configurations. Because our clients' boards, corporate donors,
grant offices, and B2B customers frequently review our sites **from locked-down work
computers**, this issue can undermine confidence in an otherwise finished, high-quality site.

This PRD defines the problem in full, the mitigations we can control, the limits of what
we can guarantee, and the concrete enhancements required in the `deployment-expert` skill
so that **every new site the KGP Plugin generates is corporate-network-hardened by default
and verified before launch.**

---

## 2. Problem Statement

### 2.1 The observed symptom

A client attempted to review our example sites from his **corporate work computer** and
reported that the sites were "quarantined" and would not display as designed. The **same
sites rendered correctly on his personal computer.** Typical manifestations:

- Page loads but appears **unstyled** (fonts/CSS/JS stripped).
- Site is **fully blocked** with a corporate "access denied / uncategorized" interstitial.
- Images, embedded media, or web fonts fail to load while HTML text shows.

### 2.2 Root causes (diagnosed)

This is a **network/hosting-reputation problem**, not a content or design defect. Three
independent contributing causes:

1. **Uncategorized / new-domain reputation.**
   Enterprise web filters (Zscaler, Cisco Umbrella / Talos, Palo Alto, Forcepoint,
   Sophos, Symantec/Broadcom, Netskope, DNSFilter, etc.) assign every domain a category.
   A brand-new domain they have never seen defaults to **"uncategorized."** Many corporate
   policies **block or degrade uncategorized sites** on principle. When degraded rather
   than fully blocked, the HTML passes but **sub-resources are stripped**, producing the
   "loads but unstyled" symptom.

2. **Shared-host / free-subdomain distrust.**
   Sites served from shared free-hosting namespaces (e.g. `*.netlify.app`,
   `*.vercel.app`, `*.web.app`, `*.github.io`) are frequently **blocked wholesale**
   because those shared namespaces are abused by spammers and phishers. The individual
   site's content is irrelevant — the filter distrusts the parent namespace.

3. **Missing / weak security posture.**
   Sites lacking a standard security-header set, valid TLS/HSTS, or that pull many
   third-party external resources can **score lower** in reputation engines and give
   strict filters more surface to strip or flag.

### 2.3 Why this matters (business impact)

- **Perception of quality:** A broken-looking site on a decision-maker's work computer
  reads as "unfinished" even when it is complete and correct.
- **Audience is corporate by nature:** Nonprofit boards, corporate/foundation donors,
  grant reviewers, and B2B buyers overwhelmingly browse from managed corporate networks.
- **Late discovery is expensive:** Found after launch, it becomes an emergency; addressed
  during build, it is a routine checklist.

### 2.4 What we do NOT control (must be stated in every client-facing output)

Corporate proxies and web filters are configured and operated by the **client's or
visitor's own IT department and third-party filtering vendors** — entirely outside our
control. Every organization configures its filters differently, and some block by policy
in ways **no website configuration can override.** We therefore commit to **best efforts /
best practices** to maximize compatibility, but **we cannot guarantee** that any specific
corporate network, proxy, or filter will permit or fully render the site. This is a
**mitigation, not a warranty.**

---

## 3. Goals & Non-Goals

### 3.1 Goals

- **G1.** Make corporate-network hardening a **default, standard step** in every new-site
  build the KGP Plugin produces — not an ad-hoc afterthought.
- **G2.** Enhance the `deployment-expert` skill to **apply, verify, and document** the
  mitigations automatically as part of deploy/verify.
- **G3.** Provide **client-facing language** (proposal + SOW) that sets best-effort /
  no-guarantee expectations in writing.
- **G4.** Provide a **verifiable acceptance checklist** so we can prove the mitigations
  were applied on any given site.

### 3.2 Non-Goals

- **NG1.** Guaranteeing access on any specific corporate network (impossible — see 2.4).
- **NG2.** Bypassing, evading, or defeating any legitimate corporate security control.
- **NG3.** Changing the visual design of sites (this is infrastructure/config only).

---

## 4. Recommended Mitigations (What We Control)

These are the "best-bet" actions. All are within our control and become the enhancement's
implementation surface.

| # | Mitigation | Why it helps | Enforced at |
|---|-----------|--------------|-------------|
| M1 | **Deploy on the client's own custom domain** — never ship a `*.netlify.app`/shared subdomain as the presented URL. | Removes shared-namespace distrust (cause #2). | Profile setup / deploy |
| M2 | **Ship a hardened security-header set** from day one (see 4.1). | Raises reputation-engine trust (cause #3); no external surface to strip. | Deploy (headers config) |
| M3 | **Self-host fonts; minimize/remove third-party external resources.** | A strict filter has nothing external to block/strip → no "unstyled" symptom (cause #1 fallout). | Build config |
| M4 | **Serve valid HTTPS/TLS + HSTS.** | Baseline trust; blocks downgrade. | Deploy |
| M5 | **Pre-submit the domain for categorization** to major filter vendors BEFORE launch. | Directly fixes "uncategorized" default (cause #1). | Pre-launch workflow |
| M6 | **Verify from a corporate-like environment** (VPN/proxy/second-machine) before handoff. | Catches the symptom before the client does. | Post-deploy health |
| M7 | **Document what was done + no-guarantee caveat** in the deploy record and client outputs. | Sets expectations; provides proof of best effort. | Deploy record + proposal/SOW |

### 4.1 Baseline security-header set (proven pattern)

Drop-in for Netlify (`netlify.toml`); adapt to `_headers`, nginx, or platform equivalents:

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

*(A Content-Security-Policy header further raises trust but must be tuned per-site to avoid
breaking legitimate resources; treat as optional/advanced, generated from the site's actual
resource inventory.)*

### 4.2 Filter-vendor categorization submission targets

Each offers a free "request categorization / site review" form. Suggested category:
**Business / Nonprofit / Charity** (match the site's actual purpose).

- Zscaler (Site Review)
- Cisco Talos / Umbrella (domain reputation & categorization)
- Palo Alto Networks (URL categorization / Test A Site)
- Forcepoint (URL category submission)
- Symantec / Broadcom BlueCoat (Site Review)
- Netskope, DNSFilter, Fortinet (FortiGuard), Trend Micro (Site Safety) — as applicable

---

## 5. Plugin Enhancement Specification (`deployment-expert`)

The `deployment-expert` skill currently handles platforms, profiles, env vars, and
post-deploy health but has **no security-header, categorization, or corporate-filter
handling.** Add the following.

### 5.1 New reference doc

**`skills/deployment-expert/references/corporate-accessibility.md`** — the knowledge base:
the three root causes, the mitigation table, the header set (per platform: Netlify `_headers`
/ `netlify.toml`, nginx, Azure VM, GitHub-production), the font self-hosting recipe, and the
vendor categorization link list + suggested categories.

### 5.2 New workflow

**`skills/deployment-expert/workflows/corporate-accessibility-hardening.md`** — an ordered,
runnable checklist the skill executes during a site build/deploy:

1. Confirm the presented URL is a **custom domain**, not a shared subdomain (M1). Warn loudly if not.
2. Apply the **baseline security headers** for the detected platform (M2).
3. Scan the built output for **external resource hosts**; flag anything beyond an approved
   allowlist; recommend self-hosting fonts/assets (M3).
4. Confirm **HTTPS + HSTS** are live (M4).
5. Emit the **vendor categorization submission list** with the domain + suggested category
   pre-filled (M5) and record submission date/links.
6. Trigger a **corporate-like accessibility check** (M6).
7. Write a **hardening record** into the deploy log + generate the client-facing caveat text (M7).

### 5.3 New template

**`skills/deployment-expert/templates/security-headers.*.template`** — per-platform header
files (Netlify `_headers` + `netlify.toml` block, nginx `server` snippet, etc.) generated
into new projects.

### 5.4 Deployment profile extension

Extend `.deployment-profile.json` (and `templates/deployment-profile.json`) with a
`corporateAccessibility` block:

```json
"corporateAccessibility": {
  "customDomainRequired": true,
  "securityHeadersApplied": false,
  "externalResourceAllowlist": [],
  "fontsSelfHosted": false,
  "categorizationSubmitted": { "zscaler": null, "cisco": null, "paloAlto": null,
                               "forcepoint": null, "symantec": null },
  "corporateVerified": false,
  "lastVerifiedAt": null
}
```

### 5.5 Post-deploy health check addition

Extend **`workflows/post-deploy-health.md`** to assert, via `curl`, that the security
headers are present on the live site and that the response is served over HTTPS from the
custom domain — failing the health check if headers are missing.

### 5.6 Integration hooks

- The **new-site / new-client flow** (e.g. `project:new-client`) should scaffold the
  headers template and initialize the `corporateAccessibility` profile block.
- `software-architect` should append the **best-effort / no-guarantee line item** to
  generated proposals/SOWs.

---

## 6. Acceptance Criteria (Verifiable Definition of Done)

A site is "corporate-network hardened" when **all** of the following are true and recorded:

- [ ] **AC1** — Presented URL is a **custom domain**; no shared `*.netlify.app`-class URL is handed to the client.
- [ ] **AC2** — Live response returns the **full security-header set** (verified via `curl -sS -D - -o /dev/null <url>` showing `X-Frame-Options`, `X-Content-Type-Options`, `Referrer-Policy`, `Strict-Transport-Security`, `Permissions-Policy`).
- [ ] **AC3** — Built output loads **no external resource hosts** except an explicitly approved allowlist; **fonts are self-hosted**.
- [ ] **AC4** — Site is served over **valid HTTPS with HSTS**.
- [ ] **AC5** — Domain **submitted for categorization** to the target vendors; submission dates/links logged in the profile.
- [ ] **AC6** — Site **verified rendering correctly from a corporate-like environment** (VPN/proxy/second machine); result logged.
- [ ] **AC7** — **Hardening record + no-guarantee caveat** written into the deploy log, and the caveat included in the proposal/SOW.

---

## 7. Client-Facing Deliverables (generated by the skill)

### 7.1 Proposal paragraph (non-technical)

> **Corporate Network Accessibility.** Some organizations run strict security filters on
> their work computers that can hide or block brand-new websites they haven't yet
> recognized — which can make a finished site look broken on an office computer even though
> it works perfectly everywhere else. We proactively build against this: your site will
> live on its own dedicated web address, ship with the security configuration corporate
> networks look for, keep its content self-contained, and be submitted to the major
> corporate filtering services for recognition before launch. **Please note:** these
> filters are controlled by each visitor's own IT department and are outside our control,
> so while we apply every best practice to maximize compatibility, we cannot guarantee how
> any specific corporate network chooses to treat any website.

### 7.2 SOW / scope one-liner

> *Corporate network accessibility hardening (custom domain, security headers, self-hosted
> assets, pre-launch filter categorization submission) is included on a best-efforts basis;
> KG ProDesign does not warrant access or rendering on any specific third-party corporate
> network, proxy, or web filter, as those systems are outside our control.*

---

## 8. Rollout

1. Author `references/corporate-accessibility.md` + header templates.
2. Add the `corporate-accessibility-hardening` workflow and profile block.
3. Wire header assertions into `post-deploy-health`.
4. Wire scaffolding into the new-client/new-site flow and proposal generation.
5. **Backfill** existing live client sites against the AC checklist (KimRose and any
   `*.netlify.app`-presented sites are highest priority).
6. Update `CHANGELOG.md` and the skill `description` to mention corporate-accessibility hardening.

---

## 9. Open Questions

- Do we standardize on a specific "corporate-like" verification method (paid VPN with
  known filtering, a dedicated locked-down test VM, or a filter-simulation service)?
- Should categorization submission be **automated** (scripted form posts / APIs where
  available) or remain a **guided manual checklist** with logged results?
- Do we want a per-site **CSP generator** (from the built resource inventory) as a phase-2
  enhancement, given CSP's higher trust value but higher breakage risk?
```