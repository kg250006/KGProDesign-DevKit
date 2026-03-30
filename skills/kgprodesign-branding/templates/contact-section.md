# Template: Contact Section

Copy and customize for your contact page.

```html
<section style="
  padding: var(--kgp-space-4xl, 64px) var(--kgp-space-xl, 24px);
  font-family: var(--kgp-font-family, 'Sora', sans-serif);
  color: var(--kgp-text-primary, #18181B);
">
  <div style="max-width: 800px; margin: 0 auto;">

    <h2 style="
      font-size: var(--kgp-text-3xl, 30px);
      font-weight: var(--kgp-font-bold, 700);
      margin-bottom: var(--kgp-space-xl, 24px);
    ">
      Get in Touch
    </h2>

    <p style="
      font-size: var(--kgp-text-lg, 18px);
      color: var(--kgp-text-secondary, #52525B);
      margin-bottom: var(--kgp-space-2xl, 32px);
    ">
      Have a project in mind? We'd love to hear from you.
    </p>

    <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 24px;">

      <!-- Phone -->
      <div style="
        padding: var(--kgp-card-padding, 20px);
        border: 1px solid var(--kgp-border-light, #E5E7EB);
        border-radius: var(--kgp-radius-lg, 12px);
      ">
        <h3 style="font-size: var(--kgp-text-base, 16px); font-weight: var(--kgp-font-semibold, 600); margin-bottom: 8px;">Phone</h3>
        <a href="tel:+14079007724" style="color: var(--kgp-accent, #3B82F6); text-decoration: none; font-size: var(--kgp-text-lg, 18px);">
          (407) 900-7724
        </a>
      </div>

      <!-- Email -->
      <div style="
        padding: var(--kgp-card-padding, 20px);
        border: 1px solid var(--kgp-border-light, #E5E7EB);
        border-radius: var(--kgp-radius-lg, 12px);
      ">
        <h3 style="font-size: var(--kgp-text-base, 16px); font-weight: var(--kgp-font-semibold, 600); margin-bottom: 8px;">Email</h3>
        <a href="mailto:info@kgprodesign.com" style="color: var(--kgp-accent, #3B82F6); text-decoration: none;">
          info@kgprodesign.com
        </a>
        <br/>
        <a href="mailto:KG@KGProDesign.com" style="color: var(--kgp-text-muted, #A1A1AA); text-decoration: none; font-size: var(--kgp-text-sm, 14px);">
          KG@KGProDesign.com (Admin)
        </a>
      </div>

      <!-- Website -->
      <div style="
        padding: var(--kgp-card-padding, 20px);
        border: 1px solid var(--kgp-border-light, #E5E7EB);
        border-radius: var(--kgp-radius-lg, 12px);
      ">
        <h3 style="font-size: var(--kgp-text-base, 16px); font-weight: var(--kgp-font-semibold, 600); margin-bottom: 8px;">Website</h3>
        <a href="https://kgprodesign.com" style="color: var(--kgp-accent, #3B82F6); text-decoration: none;">
          kgprodesign.com
        </a>
      </div>

    </div>

  </div>
</section>
```
