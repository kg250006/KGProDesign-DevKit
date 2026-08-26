<required_reading>
Read references/corporate-accessibility.md for the root causes, header set, and vendor list.
This workflow is the ORCHESTRATOR for the Corporate Hardening Pass — it routes through five
stage workflows. Run it before handing a new site to the client.
</required_reading>

<overview>
## Corporate Hardening Pass (orchestrator)

Makes a site corporate-network-hardened by default: custom domain, security headers,
self-contained resources, HTTPS/HSTS, filter categorization, corporate-like verification,
and a documented best-effort caveat. It runs five stages in order.

**Idempotent (F10):** re-running on an already-hardened site reports **"compliant — no
changes"** and makes no edits. **No auto-deploy (F11):** the pass stages changes and lists
artifacts to ship; deployment is a separate, explicit operator action.

**This is a mitigation, not a warranty** — corporate filters are outside our control
(see references/corporate-accessibility.md → what_we_do_not_control). It is a legitimacy /
reputation pass, never filter evasion (NF3).
</overview>

<process>
## The five stages — run in order

| Stage | Workflow | Does |
|-------|----------|------|
| **A — Assess** | `workflows/hardening-assess.md` | Detect stack/host; score M1–M7 from live inspection; emit gap report. Read-only. |
| **B — Remediate** | `workflows/hardening-remediate.md` | Approval-gated, idempotent fixes: headers (M2), self-hosted render-path assets (M3), HSTS (M4). Stages diffs; never deploys. |
| **C — Reputation** | `workflows/hardening-reputation.md` | Tiered vendor lookup + submission (M5); human-gate pause at captcha/login; write vendor ledger. |
| **D — Verify** | `workflows/hardening-verify-record.md` (Stage D) | Re-assert headers/TLS from the custom domain; corporate-like render (M6). |
| **E — Record** | `workflows/hardening-verify-record.md` (Stage E) | Compliance record (M1–M7 + ledger + result) + best-effort caveat for the SOW (M7). |

**Flow:**
1. Run Stage A. If it reports "compliant — no changes," stop — the site is already hardened.
2. For every mitigation A marked `fail`, run Stage B (approval-gated).
3. Run Stage C for vendor categorization (M5).
4. After the operator deploys the staged changes, run Stages D + E (verify + record).

Each stage reads/writes `.deployment-profile.json` → `corporateAccessibility` (the shared
hardening-state block), so stages are resumable and the whole pass is idempotent.
</process>

<success_criteria>
The Corporate Hardening Pass is complete when all of these are true and recorded in the
profile's `corporateAccessibility` block:

- [ ] AC1 — Presented URL is a custom domain (no shared `*.netlify.app`-class URL).
- [ ] AC2 — Live response returns the full security-header set.
- [ ] AC3 — No external resource hosts except an approved allowlist; fonts self-hosted.
- [ ] AC4 — Served over valid HTTPS with HSTS.
- [ ] AC5 — Domain submitted for categorization; vendor ledger has a terminal status per Tier-1 vendor.
- [ ] AC6 — Verified rendering correctly from a corporate-like environment; result logged.
- [ ] AC7 — Hardening record + no-guarantee caveat written to the deploy log and proposal/SOW.

Plus: the pass invoked no deploy command (F11), and re-running reports "compliant" with no
edits (F10).
</success_criteria>
