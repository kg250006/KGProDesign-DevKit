# Workflow: Brand a Website

<required_reading>

Read these reference files NOW:
1. `references/company-info.md` — contact info, copyright, attribution text
2. `references/logo-assets.md` — logo selection logic
3. `references/color-system.md` — CSS custom properties
4. `references/typography.md` — font system

</required_reading>

<process>

## Step 1: Determine Scope

Ask the user what part of the website needs branding:

1. **Footer** — copyright, attribution, logo, contact links
2. **Header / Navigation** — logo placement in site header
3. **Contact page** — full contact information section
4. **About page** — company description, logo, services
5. **Full site** — all of the above

## Step 2: Detect Tech Stack

Ask (or detect from the project) what framework is being used:
- Plain HTML/CSS
- React / Next.js
- Astro
- Vue / Nuxt
- Other (ask for specifics)

## Step 3: Determine Background Context & Copy Logo

For logo placement, determine the background color of the destination:
- **Dark footer/header** → `KGProDesign_wht.png`
- **Light footer/header** → `KGProDesign_LOGO.png`
- If unknown, check the site's CSS or ask the user

**Copy the selected logo into the project** using the plugin path:
```bash
# Determine the project's image directory (public/images/, src/assets/, etc.)
cp "${CLAUDE_PLUGIN_ROOT}/templates/{SELECTED_LOGO}" ./{project-image-dir}/
```

Also copy the favicon if needed:
```bash
cp "${CLAUDE_PLUGIN_ROOT}/templates/favicon.jpg" ./public/
```

Never reference the plugin path in the generated code — always use the project-local copy.

## Step 4: Generate Branded Output

Based on scope and tech stack, use the appropriate template:

| Scope | Template |
|-------|----------|
| Footer (HTML) | `templates/footer-html.md` |
| Footer (React) | `templates/footer-react.md` |
| Contact section | `templates/contact-section.md` |
| About section | `templates/about-section.md` |

Fill the template with data from `references/company-info.md`:
- Company name: KG ProDesign LLC
- Phone: 407-900-7724
- Email: info@kgprodesign.com
- Website: kgprodesign.com
- Copyright: `© {CURRENT_YEAR} KG ProDesign LLC`
- Attribution: "Developed by KG ProDesign"

## Step 5: Include Style Guide Assets

Ensure the output includes:
- Google Fonts link for Sora (if not already in the project)
- `--kgp-*` CSS custom properties (if the project uses the KGP design system)
- Proper logo `<img>` tag with alt text: `alt="KG ProDesign"`

## Step 6: Deliver and Verify

Present the copy-paste-ready code to the user. Verify:
- Correct logo variant for the background
- Dynamic copyright year
- All contact info matches `references/company-info.md`
- Accessible (alt text, semantic HTML, contrast ratios)

</process>

<success_criteria>

- Correct logo variant selected for background context
- Company info matches canonical source
- Copyright uses dynamic year format
- Code is copy-paste ready for the detected tech stack
- Sora font referenced or included
- Semantic HTML with proper accessibility attributes

</success_criteria>
