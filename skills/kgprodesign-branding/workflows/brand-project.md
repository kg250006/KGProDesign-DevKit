# Workflow: Brand a Project / Repository

<required_reading>

Read these reference files NOW:
1. `references/company-info.md` — company data, copyright, attribution
2. `references/logo-assets.md` — logo selection for README badges
3. `references/brand-voice.md` — attribution text variants

</required_reading>

<process>

## Step 1: Determine Scope

Ask the user what project branding is needed:

1. **README branding** — "Built by" section, badges, footer
2. **GitHub repo setup** — description, topics, about section
3. **LICENSE file** — correct entity name
4. **Source code headers** — copyright comment in files
5. **All of the above**

## Step 2: Generate Branded Output

### README Branding

Use `templates/readme-badge.md` to generate a branding block. Standard placement is at the bottom of the README.

Key elements:
- "Built by KG ProDesign LLC" attribution
- Link to kgprodesign.com
- Copyright notice
- Optional: logo image (use `KGProDesign_LOGO.png` — README backgrounds are typically light)

### GitHub Repository Setup

Suggest these settings:
- **Description:** `{Project description} — Built by KG ProDesign LLC`
- **Website:** `https://kgprodesign.com`
- **Topics:** Include `kgprodesign` as a topic

### LICENSE File

Use the copyright line: `Copyright (c) {CURRENT_YEAR} KG ProDesign LLC`

### Source Code Headers

Use `templates/copyright-notice.md` to generate the correct comment format for the project's language.

## Step 3: Deliver

Present the branded content as copy-paste-ready text/code.

</process>

<success_criteria>

- Attribution uses correct variant from `references/brand-voice.md`
- Copyright line uses `KG ProDesign LLC` with correct year format
- README branding is positioned appropriately
- LICENSE file uses correct entity name
- Source code headers match the project's comment style

</success_criteria>
