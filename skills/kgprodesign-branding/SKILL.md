---
name: kgprodesign-branding
description: "Single source of truth for KG ProDesign LLC branding. Logos, colors, contact info, legal text, and branded output for websites, apps, projects, and communications. Use when branding any product created/designed/owned by KG ProDesign."
---

<essential_principles>

### 1. Single Source of Truth

All company information lives in `references/company-info.md`. Never hard-code company data — always pull from that file. If another skill or workflow needs brand data, point them to this skill's references.

### 2. Logo Selection Logic

Choose the correct logo variant based on the destination background:

- **Dark background** (black, navy, dark gray, dark theme) → `KGProDesign_wht.png` (white outlined "ProDesign")
- **Light background** (white, cream, light gray, light theme) → `KGProDesign_LOGO.png` (black "ProDesign")
- **Square / icon context** (favicon, app icon, avatar) → `favicon.jpg` or the square logo
- **SVG needed** → Flag as missing asset; do not substitute a PNG where SVG is required

Never guess at a logo variant. If the background context is ambiguous, ask the user.

**Always copy logos into the target project** from `${CLAUDE_PLUGIN_ROOT}/templates/`. Never reference the plugin path in generated code — the plugin path may change between versions or machines. See `references/logo-assets.md` for copy commands.

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
6. **Just give me the brand info** — logo files, colors, contact info, all data

**Wait for response before proceeding.**

</intake>

<routing>

| Response | Keywords | Workflow |
|----------|----------|----------|
| 1 | "website", "footer", "header", "contact page", "about page", "web" | `workflows/brand-website.md` |
| 2 | "project", "repo", "readme", "github", "open source", "badge" | `workflows/brand-project.md` |
| 3 | "app", "splash", "about dialog", "icon", "ios", "macos", "swift" | `workflows/brand-app.md` |
| 4 | "email", "signature", "social", "marketing", "business card" | `workflows/brand-communications.md` |
| 5 | "copyright", "license", "legal", "terms", "privacy" | `workflows/brand-legal.md` |
| 6 | "info", "data", "brand info", "all", "dump", "logo", "colors" | Read references directly (no workflow) |

**For option 6:** Read `references/company-info.md`, `references/logo-assets.md`, and `references/color-system.md`, then present a complete brand summary to the user.

**After reading the workflow, follow it exactly.**

</routing>

<quick_reference>

## KG ProDesign — Quick Reference

**Company:** KG ProDesign LLC
**Founded:** 2005
**Phone:** 407-900-7724
**Email (general):** info@kgprodesign.com
**Email (admin):** KG@KGProDesign.com
**Website:** kgprodesign.com
**GitHub:** https://github.com/kg250006/KGProDesign-DevKit

**Logo files (in plugin directory):**
| File | Use On |
|------|--------|
| `${CLAUDE_PLUGIN_ROOT}/templates/KGProDesign_LOGO.png` | Light backgrounds |
| `${CLAUDE_PLUGIN_ROOT}/templates/KGProDesign_wht.png` | Dark backgrounds |
| `${CLAUDE_PLUGIN_ROOT}/templates/favicon.jpg` | Favicons, small icons |

To copy a logo into the current project:
```bash
cp "${CLAUDE_PLUGIN_ROOT}/templates/KGProDesign_LOGO.png" ./public/images/
```

**Copyright:** `© {CURRENT_YEAR} KG ProDesign LLC`

**Primary font:** Sora (Google Fonts)
**Primary theme:** Urban Gray Pearl
**Accent color:** `#3B82F6` (blue)

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
| brand-legal.md | Copyright notices, license headers, legal text |

</workflows_index>

<success_criteria>

A well-branded output:
- Uses the correct logo variant for the background context
- Contains accurate company info pulled from `references/company-info.md`
- Uses dynamic copyright year format (`© {CURRENT_YEAR} KG ProDesign LLC`)
- References `--kgp-*` CSS variables where applicable
- Uses Sora font family
- Flags any missing assets needed rather than substituting
- Produces copy-paste-ready code for the target platform

</success_criteria>
