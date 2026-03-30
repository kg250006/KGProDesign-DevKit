# Template: React Footer Component

Copy and customize. Replace `{LOGO_IMPORT}` with the correct logo variant.

- **Dark footer** → `KGProDesign_wht.png`
- **Light footer** → `KGProDesign_LOGO.png`

```tsx
import React from 'react';

// Adjust the import path to where your logo files are stored
import logo from '@/assets/{LOGO_FILE}';

export function Footer() {
  const currentYear = new Date().getFullYear();

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
      <div
        style={{
          maxWidth: 1200,
          margin: '0 auto',
          display: 'flex',
          flexWrap: 'wrap',
          justifyContent: 'space-between',
          alignItems: 'center',
          gap: 24,
        }}
      >
        {/* Logo & Attribution */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          <img
            src={logo}
            alt="KG ProDesign"
            style={{ height: 40, width: 'auto' }}
          />
          <span style={{ color: 'var(--kgp-text-muted, #71717A)' }}>
            Developed by KG ProDesign
          </span>
        </div>

        {/* Contact Links */}
        <div style={{ display: 'flex', gap: 24, flexWrap: 'wrap' }}>
          <a
            href="mailto:info@kgprodesign.com"
            style={{ color: 'var(--kgp-accent, #60A5FA)', textDecoration: 'none' }}
          >
            info@kgprodesign.com
          </a>
          <a
            href="tel:+14079007724"
            style={{ color: 'var(--kgp-accent, #60A5FA)', textDecoration: 'none' }}
          >
            (407) 900-7724
          </a>
          <a
            href="https://kgprodesign.com"
            style={{ color: 'var(--kgp-accent, #60A5FA)', textDecoration: 'none' }}
          >
            kgprodesign.com
          </a>
        </div>

        {/* Copyright */}
        <div
          style={{
            width: '100%',
            textAlign: 'center',
            paddingTop: 24,
            borderTop: '1px solid var(--kgp-border-light, #27272A)',
          }}
        >
          <p style={{ margin: 0, color: 'var(--kgp-text-muted, #71717A)' }}>
            &copy; {currentYear} KG ProDesign LLC. All rights reserved.
          </p>
        </div>
      </div>
    </footer>
  );
}
```

For Next.js with Image component, replace `<img>` with `<Image>` and add `width`/`height` props.
