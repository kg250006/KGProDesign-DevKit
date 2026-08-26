# Corporate-Network Hardening — Capability Knowledge

Reusable knowledge for authoring PRDs/PRPs that involve making a website render
correctly and pass through enterprise/corporate web filters. When a feature request
touches "site looks broken/unstyled/blocked on a work computer," new-domain reputation,
security headers, self-hosted assets, or filter categorization, draw on this reference
rather than re-deriving the domain.

<canonical_example>
## Canonical PRD (worked example)

`PRDs/PRD-corporate-network-hardening.md` (v1.0) is the reference-quality, portable PRD
for this capability — authored in this skill's own `templates/prd-template.md` format
(`<prd>` with `<executive-summary>`, `<user-stories>`, `<requirements>` F1–F11,
`<technical-design>` data-model + api-contracts, `<edge-cases>`, `<security-considerations>`,
`<release-strategy>`). Use it as the model when a new PRD needs the same rigor, and as the
source when generating the implementation PRP (see `workflows/prp-from-prd.md`).

A narrower, KG-specific companion exists: `PRDs/PRD-corporate-network-accessibility.md`,
already implemented across `deployment-expert`, `kgprodesign-branding`, and
`small-business-legal-advisor` (shipped v2.5.0). The portable PRD's appendix references
those artifacts as its building blocks.
</canonical_example>

<the_capability>
## What the capability is

A single idempotent pipeline — the "Corporate Hardening Pass" — runnable against any
project, in five stages. It never auto-deploys (deployment stays a separate operator action).

| Stage | Does |
|-------|------|
| **A — Assess** | Auto-detect stack (static/SPA/SSR) + host (Netlify/Vercel/nginx/Apache/Azure VM/FTP/GitHub-prod); audit domain type, live security headers, TLS/HSTS, and every external render-path resource; emit a scored M1–M7 gap report. |
| **B — Remediate** | Apply automatable fixes: hardened security headers, self-hosted fonts + bundled render-path resources, HSTS with full directives, safe CSP tightening. Stages diffs; requires operator approval; zero visual regression. |
| **C — Reputation onboarding** | Per Tier-1 vendor: auto-lookup current category; auto-submit where machine-reachable; PAUSE with a pre-filled checklist at captcha/login gates; mark customer-login-only vendors N/A-global (route via client IT). Write a vendor ledger. |
| **D — Verify** | Re-assert headers/TLS from the **custom domain**; confirm a corporate-like render (filtering proxy / locked-down machine / simulator). Fully-styled + unblocked = pass. |
| **E — Record** | Write a hardening record (which M1–M7 applied, vendor ledger, verification result) + emit the "best effort, not a warranty" caveat into the deploy log and proposal/SOW. |
</the_capability>

<mitigations>
## The seven mitigations (M1–M7)

Every hardening PRD/PRP must evaluate all seven, each with a pass / fail / manual verdict
derived from live inspection (never assumed):

- **M1 — Custom domain.** Presented URL is the client's own domain, not a shared free-host
  subdomain (`*.netlify.app`, `*.vercel.app`, `*.web.app`, `*.github.io`, `*.pages.dev`).
  A shared subdomain is a **loud BLOCKER**, not a soft warning — no header/asset work fixes it.
- **M2 — Hardened security headers.** `X-Frame-Options: DENY`, `X-Content-Type-Options: nosniff`,
  `X-XSS-Protection: 1; mode=block`, `Referrer-Policy: strict-origin-when-cross-origin`,
  `Strict-Transport-Security: max-age=31536000; includeSubDomains; preload`,
  `Permissions-Policy` locking camera/mic/geolocation. Applied idempotently.
- **M3 — Self-hosted render-path assets.** Fonts + any render-path CDN CSS/JS internalized
  and served first-party; external references removed; visual appearance unchanged;
  required non-styling third-parties (payment/CAPTCHA/analytics) kept on an allowlist WITH a reason.
- **M4 — Valid HTTPS + full HSTS.** HSTS present with `includeSubDomains` and `preload`;
  missing TLS surfaced as a prerequisite, not silently passed.
- **M5 — Vendor reputation categorization.** Tier-1 vendors looked up + submitted
  (suggested category: **Business / Professional Services**), captcha/login gates handled
  as human-gate pauses, all logged.
- **M6 — Corporate-like verification.** Load through a filtering proxy/VPN, locked-down
  machine, or simulator; record pass/fail/pending.
- **M7 — Record + caveat.** Durable hardening record + the verbatim no-guarantee caveat for
  the proposal/SOW.
</mitigations>

<vendor_tiering>
## Vendor roster is data, not code

Reputation vendors: Zscaler, Cisco Talos/Umbrella, Palo Alto, Forcepoint,
Symantec/Broadcom (BlueCoat), Netskope, DNSFilter, Fortinet (FortiGuard), Trend Micro.

- **Tier-1 (public):** publicly reachable lookup/submission, no login.
- **Tier-2 (gated):** captcha-bound or login-gated → human gate or client-IT routing.

Vendors migrate between tiers over time (e.g. Zscaler Site Review went customer-login-only).
Keep the roster — tier, submission URL, suggested category — as **editable data** so the
runbook survives form changes without a logic edit. A PRD/PRP for this capability must
model the vendor list this way (see the portable PRD's NF4 and `VendorSubmission` entity).
</vendor_tiering>

<authoring_guidance>
## When authoring a hardening PRD or PRP

- **Idempotency + state (F10):** persist a machine-readable hardening-state block per
  project (each mitigation's status, external-resource allowlist, vendor ledger, last
  verification timestamp). Re-runs change nothing and report "compliant." In this codebase
  the state block is the `corporateAccessibility` object in `.deployment-profile.json`
  (deployment-expert) — extend it, don't invent a parallel store.
- **No auto-deploy (F11):** the pass stages changes and lists artifacts to ship; it never
  runs a deploy command.
- **Legitimacy, not evasion (NF3):** honest categorization and real trust signals only —
  never cloak, fingerprint filters, or serve filtered clients different content. Flag any
  requirement that drifts toward evasion.
- **Reuse the shipped artifacts** rather than duplicating them:
  - header set + M1–M7 procedure → `deployment-expert/references/corporate-accessibility.md`,
    `workflows/corporate-accessibility-hardening.md`, `templates/security-headers.*.template`
  - font self-hosting recipe → `kgprodesign-branding/references/typography.md` (self-hosting section)
  - best-effort caveat → `small-business-legal-advisor` service-agreement §6.4 + proposal snippet
- **Build home (this codebase):** the runnable pipeline extends `deployment-expert`
  (Assess gap-report, Reputation vendor ledger, idempotent state, no-auto-deploy staging)
  rather than a new top-level skill.
</authoring_guidance>
