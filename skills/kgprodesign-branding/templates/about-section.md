# Template: About Section

Copy and customize. Replace `{LOGO_FILE}` with the correct variant for your background.

```html
<section style="
  padding: var(--kgp-space-4xl, 64px) var(--kgp-space-xl, 24px);
  font-family: var(--kgp-font-family, 'Sora', sans-serif);
  color: var(--kgp-text-primary, #18181B);
">
  <div style="max-width: 800px; margin: 0 auto; text-align: center;">

    <!-- Logo -->
    <img
      src="{LOGO_FILE}"
      alt="KG ProDesign"
      style="height: 60px; width: auto; margin-bottom: var(--kgp-space-xl, 24px);"
    />

    <!-- Company Name -->
    <h2 style="
      font-size: var(--kgp-text-3xl, 30px);
      font-weight: var(--kgp-font-bold, 700);
      margin-bottom: var(--kgp-space-lg, 16px);
    ">
      KG ProDesign LLC
    </h2>

    <!-- Description -->
    <p style="
      font-size: var(--kgp-text-lg, 18px);
      color: var(--kgp-text-secondary, #52525B);
      line-height: var(--kgp-leading-relaxed, 1.75);
      margin-bottom: var(--kgp-space-2xl, 32px);
    ">
      KG ProDesign LLC delivers custom software solutions, web applications, and digital product
      design for businesses of all sizes. Founded in 2005, we combine technical expertise with
      design-first thinking to build products that work beautifully and perform reliably.
    </p>

    <!-- Services -->
    <div style="
      display: flex;
      flex-wrap: wrap;
      justify-content: center;
      gap: var(--kgp-space-sm, 8px);
      margin-bottom: var(--kgp-space-2xl, 32px);
    ">
      <span style="padding: 6px 16px; background: var(--kgp-bg-elevated, #F4F4F5); border-radius: var(--kgp-radius-full, 9999px); font-size: var(--kgp-text-sm, 14px);">Custom Software</span>
      <span style="padding: 6px 16px; background: var(--kgp-bg-elevated, #F4F4F5); border-radius: var(--kgp-radius-full, 9999px); font-size: var(--kgp-text-sm, 14px);">Web Applications</span>
      <span style="padding: 6px 16px; background: var(--kgp-bg-elevated, #F4F4F5); border-radius: var(--kgp-radius-full, 9999px); font-size: var(--kgp-text-sm, 14px);">Mobile Apps</span>
      <span style="padding: 6px 16px; background: var(--kgp-bg-elevated, #F4F4F5); border-radius: var(--kgp-radius-full, 9999px); font-size: var(--kgp-text-sm, 14px);">Product Design</span>
      <span style="padding: 6px 16px; background: var(--kgp-bg-elevated, #F4F4F5); border-radius: var(--kgp-radius-full, 9999px); font-size: var(--kgp-text-sm, 14px);">Tech Consulting</span>
    </div>

    <!-- Contact CTA -->
    <a href="mailto:info@kgprodesign.com" style="
      display: inline-block;
      padding: 12px 32px;
      background: var(--kgp-accent, #3B82F6);
      color: #FFFFFF;
      text-decoration: none;
      border-radius: var(--kgp-radius-md, 8px);
      font-weight: var(--kgp-font-semibold, 600);
      font-size: var(--kgp-text-base, 16px);
    ">
      Get in Touch
    </a>

  </div>
</section>
```
