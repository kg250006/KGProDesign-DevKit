# Template: HTML Footer

Copy and customize. Replace `{LOGO_FILE}` with the correct variant based on your footer's background color.

- **Dark footer** → `KGProDesign_wht.png`
- **Light footer** → `KGProDesign_LOGO.png`

```html
<footer style="
  background-color: var(--kgp-primary-900, #0F172A);
  color: var(--kgp-text-secondary, #D4D4D8);
  padding: var(--kgp-space-3xl, 48px) var(--kgp-space-xl, 24px);
  font-family: var(--kgp-font-family, 'Sora', -apple-system, BlinkMacSystemFont, sans-serif);
  font-size: var(--kgp-text-sm, 14px);
  line-height: var(--kgp-leading-normal, 1.5);
">
  <div style="max-width: 1200px; margin: 0 auto; display: flex; flex-wrap: wrap; justify-content: space-between; align-items: center; gap: 24px;">

    <!-- Logo & Attribution -->
    <div style="display: flex; align-items: center; gap: 12px;">
      <img
        src="{LOGO_FILE}"
        alt="KG ProDesign"
        style="height: 40px; width: auto;"
      />
      <span style="color: var(--kgp-text-muted, #71717A);">
        Developed by KG ProDesign
      </span>
    </div>

    <!-- Contact -->
    <div style="display: flex; gap: 24px; flex-wrap: wrap;">
      <a href="mailto:info@kgprodesign.com" style="color: var(--kgp-accent, #60A5FA); text-decoration: none;">
        info@kgprodesign.com
      </a>
      <a href="tel:+14079007724" style="color: var(--kgp-accent, #60A5FA); text-decoration: none;">
        (407) 900-7724
      </a>
      <a href="https://kgprodesign.com" style="color: var(--kgp-accent, #60A5FA); text-decoration: none;">
        kgprodesign.com
      </a>
    </div>

    <!-- Copyright -->
    <div style="width: 100%; text-align: center; padding-top: 24px; border-top: 1px solid var(--kgp-border-light, #27272A);">
      <p style="margin: 0; color: var(--kgp-text-muted, #71717A);">
        &copy; <script>document.write(new Date().getFullYear())</script> KG ProDesign LLC. All rights reserved.
      </p>
    </div>

  </div>
</footer>
```

For static sites without JavaScript, replace the `<script>` tag with the current year.
