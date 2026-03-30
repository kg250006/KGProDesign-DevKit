# KG ProDesign — Color System

Extracted from `templates/kgprodesign-style-guide-2026.html`. Use `--kgp-*` CSS custom properties in all branded outputs.

<theme_overview>

## Themes

| Theme | Description | Use When |
|-------|-------------|----------|
| **Urban Gray Pearl** (default) | Slate gray palette with blue accent | Most applications, professional/corporate |
| **Still Night Pearl** | Indigo palette with purple accent | Creative/premium applications, alternative branding |

Each theme has **light** and **dark** mode variants.

Set theme: `<html data-theme="urban-gray" data-mode="light">`

</theme_overview>

<urban_gray_light>

## Urban Gray Pearl — Light Mode (Default)

```css
/* Primary scale (slate grays) */
--kgp-primary-50: #F8FAFC;
--kgp-primary-100: #F1F5F9;
--kgp-primary-200: #E2E8F0;
--kgp-primary-300: #CBD5E1;
--kgp-primary-400: #94A3B8;
--kgp-primary-500: #64748B;
--kgp-primary-600: #475569;
--kgp-primary-700: #334155;
--kgp-primary-800: #1E293B;
--kgp-primary-900: #0F172A;

/* Accent (blue) */
--kgp-accent: #3B82F6;
--kgp-accent-light: #DBEAFE;
--kgp-accent-dark: #1D4ED8;
--kgp-accent-hover: #2563EB;

/* Backgrounds */
--kgp-bg-base: #FFFFFF;
--kgp-bg-surface: #FAFAFA;
--kgp-bg-elevated: #F4F4F5;
--kgp-bg-muted: #E4E4E7;

/* Text */
--kgp-text-primary: #18181B;
--kgp-text-secondary: #52525B;
--kgp-text-muted: #A1A1AA;
--kgp-text-on-accent: #FFFFFF;

/* Borders */
--kgp-border-light: #E5E7EB;
--kgp-border-medium: #D4D4D8;
--kgp-border-focus: #3B82F6;

/* Semantic */
--kgp-success: #22C55E;
--kgp-warning: #F59E0B;
--kgp-error: #EF4444;
--kgp-info: #3B82F6;
```

</urban_gray_light>

<urban_gray_dark>

## Urban Gray Pearl — Dark Mode

```css
/* Accent (lighter blue for dark bg) */
--kgp-accent: #60A5FA;
--kgp-accent-light: #1E3A5F;
--kgp-accent-dark: #93C5FD;
--kgp-accent-hover: #3B82F6;

/* Backgrounds */
--kgp-bg-base: #09090B;
--kgp-bg-surface: #18181B;
--kgp-bg-elevated: #27272A;
--kgp-bg-muted: #3F3F46;

/* Text */
--kgp-text-primary: #FAFAFA;
--kgp-text-secondary: #D4D4D8;
--kgp-text-muted: #71717A;

/* Borders */
--kgp-border-light: #27272A;
--kgp-border-medium: #3F3F46;
--kgp-border-focus: #60A5FA;
```

Set with: `<html data-theme="urban-gray" data-mode="dark">`

</urban_gray_dark>

<still_night_light>

## Still Night Pearl — Light Mode

```css
/* Primary scale (indigo) */
--kgp-primary-50: #EEF2FF;
--kgp-primary-100: #E0E7FF;
--kgp-primary-200: #C7D2FE;
--kgp-primary-300: #A5B4FC;
--kgp-primary-400: #818CF8;
--kgp-primary-500: #6366F1;
--kgp-primary-600: #4F46E5;
--kgp-primary-700: #4338CA;
--kgp-primary-800: #3730A3;
--kgp-primary-900: #312E81;

/* Accent (indigo) */
--kgp-accent: #4F46E5;
--kgp-accent-light: #EEF2FF;
--kgp-accent-dark: #3730A3;
--kgp-accent-hover: #4338CA;

/* Backgrounds */
--kgp-bg-base: #FFFFFF;
--kgp-bg-surface: #FAFAFF;
--kgp-bg-elevated: #EEF2FF;
--kgp-bg-muted: #E0E7FF;

/* Text */
--kgp-text-primary: #1E1B4B;
--kgp-text-secondary: #4B5563;
--kgp-text-muted: #9CA3AF;
```

Set with: `<html data-theme="still-night" data-mode="light">`

</still_night_light>

<still_night_dark>

## Still Night Pearl — Dark Mode

```css
/* Accent (lighter indigo for dark bg) */
--kgp-accent: #818CF8;
--kgp-accent-light: #312E81;
--kgp-accent-dark: #A5B4FC;
--kgp-accent-hover: #6366F1;

/* Backgrounds */
--kgp-bg-base: #0F0E1A;
--kgp-bg-surface: #1A1830;
--kgp-bg-elevated: #252347;
--kgp-bg-muted: #312E81;

/* Text */
--kgp-text-primary: #EEF2FF;
--kgp-text-secondary: #C7D2FE;
--kgp-text-muted: #6366F1;
```

Set with: `<html data-theme="still-night" data-mode="dark">`

</still_night_dark>

<shared_tokens>

## Shared Tokens (All Themes)

```css
/* Shadows */
--kgp-shadow-sm: 0 1px 2px 0 rgba(0, 0, 0, 0.05);
--kgp-shadow-md: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
--kgp-shadow-lg: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05);
--kgp-shadow-xl: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);

/* Spacing */
--kgp-space-xs: 4px;   --kgp-space-sm: 8px;   --kgp-space-md: 12px;
--kgp-space-lg: 16px;  --kgp-space-xl: 24px;  --kgp-space-2xl: 32px;
--kgp-space-3xl: 48px; --kgp-space-4xl: 64px;

/* Border Radius */
--kgp-radius-sm: 4px;   --kgp-radius-md: 8px;   --kgp-radius-lg: 12px;
--kgp-radius-xl: 16px;  --kgp-radius-2xl: 24px; --kgp-radius-full: 9999px;

/* Component Sizes */
--kgp-button-height: 44px;
--kgp-input-height: 48px;
--kgp-icon-size: 24px;
--kgp-icon-size-lg: 36px;
--kgp-appbar-height: 56px;
--kgp-card-padding: 20px;

/* Transitions */
--kgp-transition-fast: 150ms ease-in-out;
--kgp-transition-base: 250ms ease-in-out;
--kgp-transition-slow: 350ms ease-in-out;

/* Z-Index */
--kgp-z-dropdown: 1000;  --kgp-z-sticky: 1020;
--kgp-z-fixed: 1030;     --kgp-z-modal-backdrop: 1040;
--kgp-z-modal: 1050;     --kgp-z-tooltip: 1070;
```

</shared_tokens>

<google_fonts>

## Font Import

```html
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Sora:wght@300;400;500;600;700&display=swap" rel="stylesheet">
```

</google_fonts>
