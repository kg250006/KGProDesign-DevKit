<required_reading>
Reuse the security-header + HTTPS assertion from workflows/post-deploy-health.md (Step 4.5).
The client-facing caveat text lives in small-business-legal-advisor → service-agreement
template §6.4 Corporate Network Accessibility + the <proposal_language> snippet — pull it,
do not rewrite it. This is Stages D+E of the Corporate Hardening Pass.
</required_reading>

<overview>
## Stage D — VERIFY, Stage E — RECORD

Re-assert the hardening from the CUSTOM domain, confirm a corporate-like render, then write
a durable compliance record and emit the best-effort caveat for the deploy log and
proposal/SOW. Run after the remediated build has been deployed by the operator.
</overview>

<process>
## Step 1: Re-assert headers + HTTPS/HSTS from the custom domain (M4/M2 → F8/AC4.1)

Use the same assertion post-deploy-health.md Step 4.5 runs, against the custom domain:

```bash
URL=$(jq -r '.verification.url' .deployment-profile.json)
curl -sS -D - -o /dev/null "$URL" | grep -iE \
  'x-frame-options|x-content-type-options|referrer-policy|strict-transport-security|permissions-policy'
```

All five headers present + `https://` custom domain = verification pass. If any is missing,
the site is not hardened — return to Stage B (Remediate) before recording a pass.

## Step 2: Corporate-like render check (M6 / F8 / AC4.2)

Load the live site through a corporate-like environment — a filtering VPN/proxy, a
locked-down test machine, or a filter-simulation service — and confirm it renders **fully
styled and unblocked**.

**EC4.1 — no corporate-like environment available:** record
`corporateAccessibility.corporateVerified = false` and `mitigations.M6.verdict = pending`.
Do NOT mark the pass fully complete; surface M6 as the outstanding item.

On success: `corporateVerified = true`, `mitigations.M6.verdict = pass`,
`lastVerifiedAt = <timestamp>`.

## Step 3: Write the compliance record (M7 / F9 / AC4.3)

Write a durable hardening record (into the deploy log and/or the profile `history[]`) listing:
- Which of M1–M7 were applied (from `corporateAccessibility.mitigations`).
- The full `vendorLedger` (vendor, status, date, reference).
- The verification result (headers + corporate-like render).

## Step 4: Emit the best-effort caveat (M7 / F9)

Pull the client-facing caveat verbatim from `small-business-legal-advisor` →
service-agreement template §6.4 (and the `<proposal_language>` proposal paragraph / SOW
one-liner). Include it in the deploy record and hand it to the operator for the proposal/SOW.
Do not author new caveat wording — the legal skill is the source of truth.

## Step 5: Finalize overall status (F10)

```bash
# overallStatus: compliant (all P0 pass) | remediated | blocked | pending-manual
jq '.corporateAccessibility.overallStatus = "compliant"
    | .corporateAccessibility.lastVerifiedAt = "2026-08-25"' \
   .deployment-profile.json > .tmp && mv .tmp .deployment-profile.json
```

`overallStatus` must NOT be "compliant" while any P0 mitigation is failing or M6 is pending.
</process>

<success_criteria>
- [ ] Header/HSTS assertion targets the custom domain, reusing the post-deploy-health check (AC4.1).
- [ ] Missing corporate-like environment records M6 pending, not pass (EC4.1).
- [ ] Durable compliance record lists M1–M7 applied + vendor ledger + verification result (AC4.3).
- [ ] Best-effort caveat pulled verbatim from legal §6.4 (not rewritten) and included in the record/SOW (F9).
- [ ] overallStatus reflects true state; never "compliant" with a failing P0 or pending M6 (F10).
</success_criteria>
