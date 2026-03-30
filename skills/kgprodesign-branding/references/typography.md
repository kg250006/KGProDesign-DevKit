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

</font_stack>

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
