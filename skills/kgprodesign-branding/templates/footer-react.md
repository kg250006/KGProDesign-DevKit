# Template: React Footer Components

The rule is the same as `footer-html.md`. **Client sites** get the `KgpCreditStamp` in their own footer. **KGP-owned products** get the full `KgpFooter`.

## A. `KgpCreditStamp` (client sites)

Copy `${CLAUDE_PLUGIN_ROOT}/templates/brand-2026/mark/kgp-mark-color.svg` into the project's assets.

Set `hosted`:
- `true` when **KG ProDesign hosts** the site. The label reads "Dev & Hosted By".
- `false` when the site is **hosted elsewhere**. The label reads "Developed By".

If you don't know who hosts it, ask.

```tsx
import React from 'react';
import shield from '@/assets/kgp-mark-color.svg';

export function KgpCreditStamp({ hosted }: { hosted: boolean }) {
  return (
    <a
      href="https://kgprodesign.com"
      className="kgp-stamp"
      style={{ display: 'inline-flex', alignItems: 'center', gap: 10, textDecoration: 'none', color: 'inherit' }}
    >
      <img src={shield} alt="" width={25} height={28} />
      <span style={{ display: 'grid', gap: 4 }}>
        <span
          className="kgp-stamp__lbl"
          style={{
            font: '500 8.5px/1 ui-monospace, Menlo, monospace',
            letterSpacing: '.16em',
            textTransform: 'uppercase',
            opacity: 0.7,
          }}
        >
          {hosted ? 'Dev & Hosted By' : 'Developed By'}
        </span>
        <span style={{ font: '500 12px/1.1 Inter, system-ui, sans-serif', letterSpacing: '.02em' }}>
          KG ProDesign
        </span>
      </span>
    </a>
  );
}
```

Add the hover and focus states in the project's CSS:

```css
.kgp-stamp:hover .kgp-stamp__lbl { opacity: 1; }
.kgp-stamp:focus-visible { outline: 2px solid #A33A3A; outline-offset: 3px; }
```

Usage, in the client footer's bottom bar:

```tsx
<div style={{ display: 'flex', flexWrap: 'wrap', alignItems: 'center', justifyContent: 'space-between', gap: 14 }}>
  <span>&copy; {new Date().getFullYear()} {clientName}. All rights reserved.</span>
  <KgpCreditStamp hosted={true} />
</div>
```

## B. `KgpFooter` (KGP-owned products)

Import the lockup that suits the footer's background:
- **Dark footer:** `kgp-lockup-h-dark.svg`
- **Light footer:** `kgp-lockup-h-light.svg`

Both are in `${CLAUDE_PLUGIN_ROOT}/templates/brand-2026/lockup-horizontal/`.

```tsx
import React from 'react';
import logo from '@/assets/kgp-lockup-h-dark.svg';

export function KgpFooter() {
  const year = new Date().getFullYear();
  const link = { color: 'var(--kgp-accent, #E07070)', textDecoration: 'none' };

  return (
    <footer
      style={{
        backgroundColor: 'var(--kgp-primary-900, #0F172A)',
        color: 'var(--kgp-text-secondary, #D4D4D8)',
        padding: '48px 24px',
        fontFamily: "var(--kgp-font-family, 'Sora', sans-serif)",
        fontSize: '14px',
        lineHeight: 1.5,
      }}
    >
      <div style={{ maxWidth: 1200, margin: '0 auto', display: 'flex', flexWrap: 'wrap', justifyContent: 'space-between', alignItems: 'center', gap: 24 }}>
        <a href="https://kgprodesign.com" style={{ display: 'inline-flex' }}>
          <img src={logo} alt="KG ProDesign" style={{ height: 40, width: 'auto' }} />
        </a>
        <div style={{ display: 'flex', gap: 24, flexWrap: 'wrap' }}>
          <a href="mailto:info@kgprodesign.com" style={link}>info@kgprodesign.com</a>
          <a href="tel:+14079007724" style={link}>(407) 900-7724</a>
          <a href="https://kgprodesign.com" style={link}>kgprodesign.com</a>
        </div>
        <div style={{ width: '100%', textAlign: 'center', paddingTop: 24, borderTop: '1px solid var(--kgp-border-light, #27272A)' }}>
          <p style={{ margin: 0, color: 'var(--kgp-text-muted, #71717A)' }}>
            &copy; {year} KG ProDesign LLC. All rights reserved.
          </p>
        </div>
      </div>
    </footer>
  );
}
```

For Next.js, swap `<img>` for `<Image>` and add `width` and `height` props.
