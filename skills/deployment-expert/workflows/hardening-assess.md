<required_reading>
Read references/corporate-accessibility.md for the root causes and the security-header set
(do not re-document them here). Read references/reputation-vendors.md for the vendor roster.
This is Stage A of the Corporate Hardening Pass — orchestrated by
workflows/corporate-accessibility-hardening.md.
</required_reading>

<overview>
## Stage A — ASSESS (read-only)

Detect the stack and hosting, audit all seven mitigations against live/actual state, and
emit a scored M1–M7 gap report. **This stage never edits the project.** Its verdicts drive
Stage B (Remediate). Idempotent: re-running on a hardened site reports "compliant."
</overview>

<process>
## Step 1: Detect stack, host, and header mechanism

Run the probe (reuses scripts/detect-platform.sh):

```bash
bash scripts/assess-hardening.sh "$(jq -r '.verification.url // empty' .deployment-profile.json)" .
```

It prints the detected **stack** (static/SPA/SSR), **host**, and **header mechanism**
BEFORE any verdict, plus the M1 domain check and the live M2/M4 header/HTTPS probe.

**Edge case EC1.1 — ambiguous detection:** if stack or host comes back `unknown`, or two
hosting mechanisms are present (e.g. both a platform config and a proxy vhost), PAUSE and
ask the operator to confirm from a short menu. Never guess silently.

## Step 2: Score M1–M7

Assign each mitigation a verdict of **pass / fail / manual-required / not-applicable**,
derived from live inspection — never assumed:

| M | Check | Source |
|---|-------|--------|
| M1 | Presented URL is a custom domain, not a shared subdomain | probe output (BLOCKER if shared) |
| M2 | Full security-header set present on live response | probe output |
| M3 | No external hosts on the critical render path; fonts self-hosted | scan built output (Step 3) |
| M4 | Valid HTTPS + full HSTS directives | probe output |
| M5 | Vendor categorization submitted/clean | read profile `corporateAccessibility.vendorLedger` |
| M6 | Corporate-like render verified | read profile `corporateAccessibility.corporateVerified` |
| M7 | Hardening record + caveat written | check deploy log / record presence |

## Step 3: Scan built output for render-path external hosts (M3 input)

```bash
BUILD_DIR=$(jq -r '.build.output // "dist"' .deployment-profile.json)
grep -rhoE 'https?://[a-zA-Z0-9.-]+' "$BUILD_DIR" 2>/dev/null \
  | sed -E 's#https?://([^/]+).*#\1#' | sort -u
```

Compare against `corporateAccessibility.externalResourceAllowlist`. Any font/asset CDN on
the render path that is not allowlisted → M3 = fail. Editorial hyperlinks in content
(not render-path resources) do not count (EC of the PRD).

## Step 4: Write verdicts to the state block (idempotency, F10)

Record each verdict and the detection results into
`.deployment-profile.json` → `corporateAccessibility`:

```bash
# Illustrative — set mitigations.M#.verdict, detectedStack, detectedHost, lastRunAt.
jq '.corporateAccessibility.detectedStack = "static"
    | .corporateAccessibility.detectedHost = "netlify"
    | .corporateAccessibility.mitigations.M1.verdict = "pass"' \
   .deployment-profile.json > .tmp && mv .tmp .deployment-profile.json
```

**EC1.2 — already hardened:** if every P0 mitigation already passes, report
**"compliant — no changes"**, refresh `lastRunAt`, and skip Stage B. Otherwise emit the gap
report and proceed.

## Step 5: Emit the gap report

```
## Corporate Hardening — Gap Report
Stack: <stack> | Host: <host> | Header mechanism: <mechanism>

M1 Custom domain ............ <pass|BLOCKER|manual>
M2 Security headers ......... <pass|fail>   (missing: <list>)
M3 Render-path assets ....... <pass|fail>   (external hosts: <list>)
M4 HTTPS + HSTS ............. <pass|fail>
M5 Vendor categorization .... <pass|fail|manual>
M6 Corporate-like verify .... <pass|pending>
M7 Record + caveat .......... <pass|fail>

Blockers: <M1 shared-subdomain, if any>
Next: Stage B (Remediate) for every fail; Stage C (Reputation) for M5.
```
</process>

<success_criteria>
- [ ] Detected stack + host + header mechanism reported before any verdict (F1/AC1.1).
- [ ] A verdict emitted for each of M1–M7 from live inspection (F2/AC1.2).
- [ ] Shared-subdomain presented URL surfaces as a loud BLOCKER (F3).
- [ ] Ambiguous detection triggers an operator confirmation menu, not a guess (EC1.1).
- [ ] Already-hardened site reports "compliant — no changes" (EC1.2).
- [ ] No project files edited (read-only stage).
</success_criteria>
