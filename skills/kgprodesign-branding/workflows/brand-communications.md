# Workflow: Brand Communications

<required_reading>

Read these reference files NOW:
1. `references/company-info.md` — contact info, descriptions
2. `references/logo-assets.md` — logo selection for email/social
3. `references/brand-voice.md` — tone, descriptions, attribution

</required_reading>

<process>

## Step 1: Determine Type

Ask the user what communication needs branding:

1. **Email signature** — professional HTML signature
2. **Social media profile** — bio, avatar, cover image
3. **Business card** — layout guidance
4. **Marketing materials** — brand consistency check

## Step 2: Generate Branded Output

### Email Signature

Use `templates/email-signature-html.md`. Ask the user for:
- **Name** — person's full name
- **Title** — job title/role
- **Email** — person's email address (or default to info@kgprodesign.com)
- **Background** — light or dark email client theme (for logo selection)

Copy the logo from the plugin for hosting:
```bash
cp "${CLAUDE_PLUGIN_ROOT}/templates/{SELECTED_LOGO}" ./{staging-dir}/
```

Key rules for email signatures:
- Use **inline CSS only** (email clients strip `<style>` tags)
- Use `<table>` layout (email clients don't support flexbox/grid)
- Logo must be hosted at a public URL or embedded as base64 (copy from plugin, then upload)
- Keep total width under 600px
- Font fallback: Arial, Helvetica (Sora won't render in most email clients)

### Social Media Profile

Provide:
- **Bio:** Use the one-line description from `references/brand-voice.md`
- **Profile picture:** Copy `${CLAUDE_PLUGIN_ROOT}/templates/KGProDesign_logo_square.png` (square format) if available, or `favicon.jpg`
- **Website link:** https://kgprodesign.com
- **Cover image:** FLAG MISSING — needs `KGProDesign_og.png` or similar

### Business Card

Provide layout guidance:
- **Front:** Logo (horizontal variant) + company name
- **Back:** Name, title, phone (407-900-7724), email, website
- **Font:** Sora (or closest available print font)
- **Colors:** Use Urban Gray Pearl palette

### Marketing Materials

Check provided materials against:
- Correct logo variant for background
- Consistent color palette (Urban Gray Pearl or Still Night Pearl)
- Sora font family
- Correct contact information
- Correct copyright/legal text

## Step 3: Deliver

Present the branded output. For email signatures, provide copy-paste HTML.

</process>

<success_criteria>

- Email signature uses inline CSS and table layout
- Correct logo variant for the context
- Contact info matches canonical source
- Brand voice is consistent with guidelines
- Social media bio uses approved company description

</success_criteria>
