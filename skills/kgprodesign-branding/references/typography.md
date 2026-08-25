# KG ProDesign — Typography System

<font_stack>

## Font Families

```css
--kgp-font-family: 'Sora', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
--kgp-font-mono: 'SF Mono', Monaco, 'Cascadia Code', 'Roboto Mono', Consolas, monospace;
```

**Google Fonts import:**
```html
<link href="https://fonts.googleapis.com/css2?family=Sora:wght@300;400;500;600;700&display=swap" rel="stylesheet">
```

**CSS import alternative:**
```css
@import url('https://fonts.googleapis.com/css2?family=Sora:wght@300;400;500;600;700&display=swap');
```

The Google Fonts `<link>` above is the **convenience default** for internal tools and
quick prototypes. For any client-facing production site, use self-hosting (below).

</font_stack>

<self_hosting>

## Self-Hosting Sora (required for production / corporate-network-hardened builds)

The Google Fonts CDN is a **third-party external resource**. Strict corporate/enterprise
web filters strip external sub-resources, which makes an otherwise-finished site render
**unstyled** on a client's work computer. Self-hosting keeps the font first-party so
there is nothing external for a filter to block.

This is mitigation **M3** in `deployment-expert` →
`references/corporate-accessibility.md`. Self-host fonts on every production/client site.

### 1. Download the Sora weights
Get the `woff2` files for the weights in use (300, 400, 500, 600, 700) — from the
[Sora repo](https://github.com/be5invis/Sora) or `google-webfonts-helper`. Place them in
the project, e.g. `public/fonts/` (static hosts) or `/fonts/` (served at the web root).

### 2. Declare `@font-face` (self-hosted)
Replace the CDN `<link>`/`@import` with local `@font-face` rules. Keep the same
`--kgp-font-family` stack — only the source changes.

```css
/* Repeat one block per weight; woff2 only is fine for modern browsers */
@font-face {
  font-family: 'Sora';
  font-style: normal;
  font-weight: 300;
  font-display: swap;               /* avoids invisible text while loading */
  src: url('/fonts/sora-300.woff2') format('woff2');
}
@font-face {
  font-family: 'Sora';
  font-style: normal;
  font-weight: 400;
  font-display: swap;
  src: url('/fonts/sora-400.woff2') format('woff2');
}
/* ...repeat for 500, 600, 700... */

:root {
  --kgp-font-family: 'Sora', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
}
```

### 3. Preload the critical weight (optional, for LCP)
```html
<link rel="preload" href="/fonts/sora-600.woff2" as="font" type="font/woff2" crossorigin>
```

### Notes
- **Do not** load both the CDN `<link>` and self-hosted `@font-face` — pick one. Production = self-hosted.
- Serve fonts from the **same custom domain** as the site (not a separate CDN host) so a filter sees a single first-party origin.
- Apply the same "self-host / bundle" principle to any other external resource on the critical render path (icon fonts, CDN CSS/JS).

</self_hosting>

<type_scale>

## Type Scale

| Token | Size | Use For |
|-------|------|---------|
| `--kgp-text-xs` | 12px | Captions, labels, fine print |
| `--kgp-text-sm` | 14px | Secondary text, metadata, nav items |
| `--kgp-text-base` | 16px | Body text (default) |
| `--kgp-text-lg` | 18px | Lead paragraphs, subtitles |
| `--kgp-text-xl` | 20px | Section headings (h4) |
| `--kgp-text-2xl` | 24px | Page section headings (h3) |
| `--kgp-text-3xl` | 30px | Page headings (h2) |
| `--kgp-text-4xl` | 36px | Hero headings (h1) |

</type_scale>

<font_weights>

## Font Weights

| Token | Value | Use For |
|-------|-------|---------|
| `--kgp-font-light` | 300 | Decorative, large headings |
| `--kgp-font-regular` | 400 | Body text (default) |
| `--kgp-font-medium` | 500 | Emphasis, navigation, labels |
| `--kgp-font-semibold` | 600 | Subheadings, buttons |
| `--kgp-font-bold` | 700 | Headings, strong emphasis |

</font_weights>

<line_heights>

## Line Heights

| Token | Value | Use For |
|-------|-------|---------|
| `--kgp-leading-tight` | 1.25 | Headings, single-line elements |
| `--kgp-leading-normal` | 1.5 | Body text (default) |
| `--kgp-leading-relaxed` | 1.75 | Long-form reading, prose |

</line_heights>

<usage_rules>

## Usage Rules

1. **Body text:** `font-size: var(--kgp-text-base)`, `font-weight: var(--kgp-font-regular)`, `line-height: var(--kgp-leading-normal)`
2. **Headings:** Use `--kgp-font-semibold` or `--kgp-font-bold`, `line-height: var(--kgp-leading-tight)`
3. **Navigation:** `font-size: var(--kgp-text-sm)`, `font-weight: var(--kgp-font-medium)`
4. **Buttons:** `font-size: var(--kgp-text-sm)`, `font-weight: var(--kgp-font-semibold)`
5. **Code:** Use `--kgp-font-mono` for inline code, terminal output, data displays
6. **Captions/labels:** `font-size: var(--kgp-text-xs)`, `font-weight: var(--kgp-font-medium)`, `text-transform: uppercase` optional

</usage_rules>
