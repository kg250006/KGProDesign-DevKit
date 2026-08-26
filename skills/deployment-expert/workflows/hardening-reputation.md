<required_reading>
Read references/reputation-vendors.md — the vendor roster (data). This workflow reads that
table; it does not hardcode vendors (NF4). This is Stage C of the Corporate Hardening Pass.
Submissions use the CUSTOM domain (M1 must pass first).
</required_reading>

<overview>
## Stage C — REPUTATION ONBOARDING (semi-automated, human-gated)

Clean up the "uncategorized new-domain" default (root cause #1) by looking up and
submitting the domain to reputation vendors — automatically where a public surface exists,
and via a pre-filled human-gate checklist where captcha/login-bound. Results are written to
`corporateAccessibility.vendorLedger` with dates and references.

**This is a legitimacy pass, not evasion (NF3):** submit the site's TRUE category and
purpose. Never cloak, fingerprint filters, or serve filters different content.
</overview>

<process>
## Step 1: Load the roster (data, not code)

Read `references/reputation-vendors.md`. For each vendor row you get: key, tier, lookup URL,
submission URL, suggested category, notes. Suggested category defaults to
**Business/Professional Services** (match the site's actual purpose).

## Step 2: Per Tier-1 (public) vendor — look up, then submit

For each `tier-1-public` vendor:
1. Drive/guide the public category **lookup**; record `currentCategory` in the ledger.
2. If the current category is missing/"uncategorized"/wrong AND the submission is
   machine-reachable → submit the suggested category and log the confirmation.
3. If the submission is **captcha-bound** → go to the human gate (Step 3).

## Step 3: Human gate for captcha/login-gated submissions (AC3.3 / NF5)

PAUSE and present the operator a pre-filled, copy-paste-ready checklist:

```
Manual submission required — <vendor>:
  Domain:            https://<custom-domain>
  Suggested category: Business/Professional Services
  Submit here:       <submission URL from roster>
  After submitting, paste the confirmation/reference to log it.
```

Record the operator-supplied confirmation to the ledger, then resume with the next vendor.

**Unattended mode (EC3.2):** if running headless, do NOT block on the gate. Complete all
automatable lookups/submissions, then emit a **deferred manual-action checklist** listing
every gated vendor and exit cleanly.

## Step 4: Tier-2 (gated) and login-only vendors

- `tier-2-gated` vendors → mark ledger `status = client-IT` with a note to route through the
  affected client's own IT if that client is blocked. **Not a failure** (AC3.4).
- **EC3.1 — a Tier-1 form moved behind a login since the roster was authored:** detect the
  gate, reclassify the vendor Tier-1→Tier-2 for this run, log the reclassification, fall
  back to the human-gate / client-IT path. Do not stall. The durable fix is a one-line edit
  in references/reputation-vendors.md.

## Step 5: Write the vendor ledger (F7 / F10)

Every vendor must reach a terminal status in
`corporateAccessibility.vendorLedger`: **clean | submitted | manual-done | client-IT | skipped**.
Record `submittedAt` (date) and `reference` (confirmation/link) for each submission.

```bash
# Illustrative ledger update
jq '(.corporateAccessibility.vendorLedger[] | select(.vendor=="fortinet"))
      |= (.status="submitted" | .submittedAt="2026-08-25" | .reference="<link>")' \
   .deployment-profile.json > .tmp && mv .tmp .deployment-profile.json
```

Set `mitigations.M5.verdict` = pass when every Tier-1 vendor is clean/submitted/manual-done
(client-IT and skipped do not block).
</process>

<success_criteria>
- [ ] Roster read from references/reputation-vendors.md (data), not hardcoded (NF4).
- [ ] Each Tier-1 vendor reaches a terminal ledger status: clean | submitted | manual-done | client-IT (F7).
- [ ] Captcha/login gates trigger a human-gate pause with a pre-filled checklist (AC3.3/NF5).
- [ ] Unattended mode emits a deferred checklist and exits rather than blocking (EC3.2).
- [ ] Login-only vendors (Zscaler) marked client-IT, not failed (AC3.4).
- [ ] Ledger records date + reference for every submission (F7).
- [ ] Honest categorization only — no evasion (NF3).
</success_criteria>
