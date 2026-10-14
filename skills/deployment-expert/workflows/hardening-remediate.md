<required_reading>
Read references/corporate-accessibility.md (header set + M2/M3 guidance) and the font
self-hosting recipe in the kgprodesign-branding skill → references/typography.md
(<self_hosting> section). Use templates/security-headers.*.template for the headers.
This is Stage B of the Corporate Hardening Pass. Run only for mitigations Stage A marked fail.
</required_reading>

<overview>
## Stage B — REMEDIATE (approval-gated, idempotent, staged — never deployed)

Apply the automatable code/config fixes: hardened security headers (M2), render-path
resource internalization incl. self-hosted fonts (M3), and HSTS strengthening (M4-config).
**Requires explicit operator approval before editing any file (NF2).** Every change is a
reviewable diff. **This stage never deploys (F11)** — it stages changes and lists the
artifacts the operator must ship separately. Re-runs make no duplicate edits (F10).
</overview>

<process>
## Step 0: Get operator approval (NF2)

Present the gap report's list of failing automatable mitigations and the exact files that
will change. **Wait for explicit approval before any edit.** Do not proceed on assumption.

## Step 1: Apply security headers idempotently (M2 / F4)

Use the template for the detected header mechanism:
- Netlify → `templates/security-headers.netlify.template` (`_headers` or `netlify.toml` block)
- nginx / NPM (Azure VM, GitHub-production) → `templates/security-headers.nginx.template`
- Apache / static host → the same header set via `.htaccess`
- KGP Host (`kgp.toml`) → the platform already sends the set except `X-XSS-Protection`. Add missing headers to
  `kgp.toml` `[headers]` only. Never write `.htaccess`, and never put `preload` in `Strict-Transport-Security`:
  KGP Host refuses it with exit 7. Deploy afterwards with the `kgp-hosting` skill.

**Idempotency (F10):** before adding, check whether each header is already present. If the
full set exists, make no change and mark M2 already-satisfied. Never append duplicate
header blocks.

```bash
# Example idempotency guard for a _headers file
if [ -f _headers ] && grep -q 'Strict-Transport-Security' _headers; then
    echo "Headers already present — skipping (idempotent)"
else
    cat templates/security-headers.netlify.template >> _headers   # or apply the platform block
fi
```

Set `corporateAccessibility.securityHeadersApplied = true` and `mitigations.M2.verdict = pass`.

## Step 2: Internalize render-path resources & self-host fonts (M3 / F5)

1. From the Stage A scan, take each external host on the critical render path.
2. **Fonts:** follow the self-hosting recipe in `kgprodesign-branding` →
   `references/typography.md` (<self_hosting>): download the exact weights/axes in use,
   declare local `@font-face`, remove the CDN reference. For variable/icon fonts (e.g.
   Material Symbols), replicate the vendor base CSS so ligatures/icons render identically
   (EC2.3).
3. **Validate each downloaded asset by magic bytes / size** before use — a 404 HTML error
   page is not a font. Fail loudly and try an alternate source rather than shipping a
   corrupt file (EC2.2):
   ```bash
   # woff2 magic: starts with 'wOF2'
   head -c 4 fonts/sora-400.woff2 | grep -q 'wOF2' || echo "NOT a valid woff2 — refetch"
   ```
4. **Required non-styling third-parties** (payment iframe, CAPTCHA, analytics beacon) that
   cannot be self-hosted: keep them and add to `externalResourceAllowlist` WITH a reason
   (EC2.1/EC3). Only render-path styling/asset hosts must be internalized.
5. Re-run the Stage A scan: the built output must show **zero** render-path references to
   font/asset CDNs (AC2.2).

Set `corporateAccessibility.fontsSelfHosted = true` and `mitigations.M3.verdict = pass`.

## Step 3: Strengthen HSTS (M4)

Ensure the HSTS header carries the full directive set:
`Strict-Transport-Security: max-age=31536000; includeSubDomains; preload`. This is part of
the header template; confirm it is applied. Set `mitigations.M4.verdict = pass` when live.

## Step 4: Verify no visual regression (AC2.3)

Before/after comparison must show unchanged typefaces, icons, and appearance (same family
names, same glyphs). If the project has the ui-visual-testing skill available, run one
screenshot-critique iteration on a representative page. Record the result.

## Step 5: Stage — do NOT deploy (F11)

List the exact files/artifacts that changed and must be shipped by the operator:

```
Staged for deployment (ship manually — this pass does not deploy):
  - netlify.toml (or _headers)
  - fonts/*.woff2  (self-hosted)
  - <built output with CDN references removed>
```

Deployment remains a separate, explicit operator action (e.g. workflows/deploy.md).
</process>

<success_criteria>
- [ ] Operator approval obtained before any file edit (NF2/AC1.3).
- [ ] Security headers applied idempotently — re-run adds no duplicates (F4/F10).
- [ ] Post-build scan shows zero render-path references to font/asset CDNs (M3/AC2.2).
- [ ] Each downloaded asset validated as a real binary by magic bytes/size (EC2.2).
- [ ] Required third-parties kept on the allowlist with a recorded reason (EC2.1).
- [ ] No visual regression (AC2.3).
- [ ] No deploy invoked; staged artifacts listed for manual shipping (F11).
</success_criteria>
