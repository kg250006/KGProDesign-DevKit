# Reputation Vendor Roster (data)

The filter-vendor roster for corporate-hardening Stage C (reputation onboarding).
This file is **data, not logic** — `workflows/hardening-reputation.md` reads it. To add,
remove, or re-tier a vendor, edit the table below; no workflow change is required (NF4).

<tiers>

## Tier definitions

- **tier-1-public** — publicly reachable category lookup and/or submission form, no login.
  The pass drives these automatically where machine-reachable, or presents a pre-filled
  human-gate checklist where captcha-bound.
- **tier-2-gated** — submission is login-gated or customer-only. Marked N/A-global for a
  generic run; route via the affected **client's own IT** if that client is blocked. Never
  counted as a failure.

**Suggested category** for all submissions: **Business/Professional Services** (match the
site's actual purpose — Nonprofit/Charity where applicable).

</tiers>

<roster>

## Vendors

| vendor | tier | lookup | submission | suggestedCategory | notes |
|--------|------|--------|------------|-------------------|-------|
| zscaler | tier-2-gated | Zscaler Site Review | Zscaler Site Review (customer login) | Business/Professional Services | Site Review went **customer-login-only** — route via client IT when a Zscaler-filtered client is blocked. |
| cisco | tier-1-public | Talos Reputation Center (talosintelligence.com) | Talos reputation dispute + Umbrella domain categorization | Business/Professional Services | Two surfaces: Talos (reputation) and Umbrella (category). |
| paloAlto | tier-1-public | Palo Alto "Test A Site" (urlfiltering.paloaltonetworks.com) | Test A Site → "Request Change" | Business/Professional Services | Public lookup + change request. |
| forcepoint | tier-1-public | Forcepoint CSI (csi.forcepoint.com) | Forcepoint URL category submission | Business/Professional Services | Public form. |
| symantec | tier-1-public | Symantec/Broadcom Site Review (sitereview.bluecoat.com) | Site Review "Check/Submit" | Business/Professional Services | BlueCoat WebPulse; captcha-bound → human gate. |
| netskope | tier-2-gated | — | Netskope URL category (support portal) | Business/Professional Services | Support/portal-gated for most; treat as tier-2 unless a public form is confirmed. |
| dnsfilter | tier-1-public | DNSFilter domain lookup | DNSFilter categorization / review request | Business/Professional Services | Public review request. |
| fortinet | tier-1-public | FortiGuard Web Filter lookup (fortiguard.com/webfilter) | FortiGuard "Submit a URL for review" | Business/Professional Services | Public lookup + submission. |
| trendMicro | tier-1-public | Trend Micro Site Safety Center (global.sitesafety.trendmicro.com) | Site Safety "Give Feedback / recategorize" | Business/Professional Services | Public; captcha-bound → human gate. |

</roster>

<maintenance>

## Re-tiering a vendor (NF4)

Vendors move their forms behind logins over time. When that happens during a run, the
reputation workflow reclassifies the vendor for that run and logs it — but the durable
fix is a one-line edit here:

1. Change the vendor's `tier` cell to `tier-2-gated` (or back to `tier-1-public`).
2. Update the `submission`/`notes` cells to reflect the new access path.
3. No change to `workflows/hardening-reputation.md` is needed — it reads this table.

Adding a vendor = adding a row. Removing = deleting a row. The vendor `key` (first column,
e.g. `zscaler`) is what appears in the profile `vendorLedger[].vendor`.

</maintenance>
