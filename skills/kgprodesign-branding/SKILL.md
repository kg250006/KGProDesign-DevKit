---
name: kgprodesign-branding
description: "Single source of truth for KG ProDesign LLC branding. Logos, colors, contact info, legal text, and branded output for websites, apps, projects, and communications. Use when branding any product created/designed/owned by KG ProDesign."
---

<essential_principles>

### 1. Single Source of Truth

All company information lives in `references/company-info.md`. Never hard-code company data — always pull from that file. If another skill or workflow needs brand data, point them to this skill's references.

### 2. Logo Selection Logic

**Rebranded 2026-11-27:** the KGP hexagon shield + "KG PRODESIGN" in Anton, black / white / maroon `#8C2828`. All files are in `${CLAUDE_PLUGIN_ROOT}/templates/brand-2026/` (SVG master + PNGs). The old red-slash logo in `templates/legacy/` is retired, so never use it.

Choose the variant from the destination:

- **Dark background** → `lockup-horizontal/kgp-lockup-h-dark.svg` (white lettering)
- **Light background** → `lockup-horizontal/kgp-lockup-h-light.svg` (black lettering)
- **Square / icon** (favicon, app icon, avatar) → `favicon/`, `square/`, `social/kgp-profile-800.png`
- **A client's site KG ProDesign built** → the **footer credit stamp** only (`templates/footer-html.md`). The label is "Dev & Hosted By" if KG ProDesign hosts the site, or "Developed By" if not. Ask if hosting is unknown.

Never guess at a variant. If the background or hosting is ambiguous, ask the user. The full decision tree is in `references/logo-assets.md`.

**Always copy logos into the target project** from `${CLAUDE_PLUGIN_ROOT}/templates/brand-2026/`. Never reference the plugin path in generated code — the plugin path may change between versions or machines. See `references/logo-assets.md` for copy commands.

### 3. Style Guide Compliance

All branded outputs must reference the KG ProDesign 2026 design system:
- Use `--kgp-*` CSS custom properties for colors, spacing, typography
- Primary font: Sora (Google Fonts), fallback: system sans-serif
- Primary theme: Urban Gray Pearl (default), Still Night Pearl (secondary)
- Reference: `templates/kgprodesign-style-guide-2026.html`

### 4. Dynamic Copyright

Always use: `© {CURRENT_YEAR} KG ProDesign LLC`

Use the current year dynamically (`new Date().getFullYear()` in JS, `date('Y')` in PHP, etc.).

### 5. Asset Gap Awareness

When a logo variant, icon size, or asset is needed but does not exist, flag it clearly to the user with exact specs for what needs to be created. Never silently substitute an incorrect variant. Check `references/logo-assets.md` for the missing assets checklist.

</essential_principles>

<intake>

What would you like to brand?

1. **Website** — footer, header, contact page, about page
2. **Project / Repository** — README, GitHub repo, open-source branding
3. **App** — splash screen, about dialog, app icon
4. **Communications** — email signature, social media, marketing materials
5. **Legal text** — copyright notice, license header, terms
6. **Print / handouts** — business card, 4x6 flyer, printer files, phone-ready PNGs
7. **Just give me the brand info** — logo files, colors, contact info, all data

**Wait for response before proceeding.**

</intake>

<routing>

| Response | Keywords | Workflow |
|----------|----------|----------|
| 1 | "website", "footer", "header", "contact page", "about page", "web" | `workflows/brand-website.md` |
| 2 | "project", "repo", "readme", "github", "open source", "badge" | `workflows/brand-project.md` |
| 3 | "app", "splash", "about dialog", "icon", "ios", "macos", "swift" | `workflows/brand-app.md` |
| 4 | "email", "signature", "social", "marketing", "banner", "post template" | `workflows/brand-communications.md` |
| 5 | "copyright", "license", "legal", "terms", "privacy" | `workflows/brand-legal.md` |
| 6 | "business card", "flyer", "print", "handout", "printer", "bleed", "QR" | `workflows/brand-print.md` |
| 7 | "info", "data", "brand info", "all", "dump", "logo", "colors" | Read references directly (no workflow) |

**For option 7:** Read `references/company-info.md`, `references/logo-assets.md`, and `references/color-system.md`, then present a complete brand summary to the user.

**After reading the workflow, follow it exactly.**

</routing>

<quick_reference>

## KG ProDesign — Quick Reference

**Company:** KG ProDesign LLC (always "LLC" on formal and printed materials)
**Founder:** Kenrick "KG" Goldson
**Tagline:** Ideas Into Intelligent Solutions
**Featured services:** Web Design · Web Hosting on SitePage.app · Web Consulting · AI Dev Tools
**Founded:** 2005
**Phone:** 407-900-7724
**Email (general):** info@kgprodesign.com
**Email (admin):** KG@KGProDesign.com
**Website:** kgprodesign.com
**Contact page:** https://kgprodesign.com/contact/
**Instagram:** @KGProDesign (https://www.instagram.com/kgprodesign/)
**GitHub (org):** https://github.com/kgprodesign
**Handout phone:** 321-427-6753 (business card and flyer only)
**GitHub:** https://github.com/kg250006/KGProDesign-DevKit

**Logo files** (in `${CLAUDE_PLUGIN_ROOT}/templates/brand-2026/`):
| File | Use On |
|------|--------|
| `lockup-horizontal/kgp-lockup-h-light.svg` | Light backgrounds (nav, header) |
| `lockup-horizontal/kgp-lockup-h-dark.svg` | Dark backgrounds (nav, header) |
| `lockup-tagline/kgp-lockup-tagline-{dark,light}.svg` | Logo + tagline (banners, decks, email headers) |
| `mark/kgp-mark-color.svg` | The shield alone, on any background |
| `favicon/favicon.ico` + `favicon.svg` | Favicons |
| `social/` | Profile picture, OG image, YouTube / X / Facebook / LinkedIn banners |
| `templates/post-template{,-white}.png` | 4:5 social post layout guides |
| `print/` | Business card + 4x6 flyer (printer PDFs, crop-mark PDFs, `share/` PNGs) |
| `brand-guide.html` | The full visual brand guide (open it in a browser) |
| `fonts/` | Anton + Inter (OFL) for brand graphics |

To copy a logo into the current project:
```bash
cp "${CLAUDE_PLUGIN_ROOT}/templates/brand-2026/lockup-horizontal/kgp-lockup-h-light.svg" ./public/images/
```

**Copyright:** `© {CURRENT_YEAR} KG ProDesign LLC`

**Brand colors (identity):** black `#000000`, white `#FFFFFF`, maroon `#8C2828` (`#6E1F1F` in print)
**Logo lettering:** Anton, all caps (built into the logo files; never retype it)
**Web UI font:** Sora (Google Fonts)
**Web UI theme:** Urban Gray Pearl with the **maroon accent** (`#8C2828` light mode, `#E07070` dark mode). Decided 2026-11-27; see `references/color-system.md`

</quick_reference>

<reference_index>

## Domain Knowledge

All in `references/`:
- **company-info.md** — Canonical company data (contact, legal entity, descriptions)
- **logo-assets.md** — Logo inventory, selection decision tree, missing assets checklist
- **color-system.md** — CSS custom properties extracted from the 2026 style guide
- **typography.md** — Sora font system, type scale, weight usage
- **brand-voice.md** — Tone, attribution text variants, company descriptions

</reference_index>

<workflows_index>

## Workflows

All in `workflows/`:

| Workflow | Purpose |
|----------|---------|
| brand-website.md | Footer, header, contact page, about page branding |
| brand-project.md | README, GitHub repo, open-source project branding |
| brand-app.md | Splash screens, about dialogs, app icons (iOS/macOS) |
| brand-communications.md | Email signatures, social media, marketing materials |
| brand-print.md | Business card, 4x6 flyer, printer files and specs, reprints |
| brand-legal.md | Copyright notices, license headers, legal text |

</workflows_index>

<success_criteria>

A well-branded output:
- Uses the correct 2026 shield logo variant for the background context (never the retired red-slash logo)
- Contains accurate company info pulled from `references/company-info.md`
- Uses dynamic copyright year format (`© {CURRENT_YEAR} KG ProDesign LLC`)
- References `--kgp-*` CSS variables where applicable
- Uses Sora font family
- Uses the footer credit stamp (with the right hosting label) on client sites
- Flags any missing assets needed rather than substituting
- Produces copy-paste-ready code for the target platform

</success_criteria>
