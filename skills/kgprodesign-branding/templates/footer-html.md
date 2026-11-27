# Template: HTML Footer

There are two kinds of footer. Pick the one that matches whose site it is:

| Site | Use |
|---|---|
| A **client's** site that KG ProDesign built | **A. Footer credit stamp.** A small credit in the client's own footer. Never a full KGP logo |
| A **KGP-owned** product or page | **B. KGP footer.** The full footer with the horizontal lockup and KGP contact links |

---

## A. Footer credit stamp (client sites)

This is the approved stamp #1 from the 2026 brand guide: the shield, a small label, and "KG ProDesign" as **live text** (not an image). It links to kgprodesign.com and stays quiet so it never competes with the client's brand.

**Pick the label by hosting. If you don't know who hosts the site, ASK.**

| Hosting | `{CREDIT_LABEL}` |
|---|---|
| KG ProDesign hosts the site | `Dev &amp; Hosted By` |
| The client hosts it elsewhere | `Developed By` |

Copy `${CLAUDE_PLUGIN_ROOT}/templates/brand-2026/mark/kgp-mark-color.svg` into the project's images folder. It is the only file the stamp needs, and it works on dark and light footers alike.

```html
<a class="kgp-stamp" href="https://kgprodesign.com">
  <img src="/images/kgp-mark-color.svg" alt="" width="25" height="28">
  <span class="kgp-stamp__txt">
    <span class="kgp-stamp__lbl">{CREDIT_LABEL}</span>
    <span class="kgp-stamp__name">KG ProDesign</span>
  </span>
</a>

<style>
.kgp-stamp { display:inline-flex; align-items:center; gap:10px; text-decoration:none; color:inherit; }
.kgp-stamp__txt { display:grid; gap:4px; }
.kgp-stamp__lbl { font:500 8.5px/1 ui-monospace,Menlo,monospace; letter-spacing:.16em;
  text-transform:uppercase; opacity:.7; }
.kgp-stamp__name { font:500 12px/1.1 Inter,system-ui,sans-serif; letter-spacing:.02em; }
.kgp-stamp:hover .kgp-stamp__lbl { opacity:1; }
.kgp-stamp:focus-visible { outline:2px solid #A33A3A; outline-offset:3px; }
</style>
```

**Placement:** put the stamp in the footer's bottom bar, opposite the client's copyright line. On narrow screens let that bar wrap.

```html
<div style="display:flex; flex-wrap:wrap; align-items:center; justify-content:space-between; gap:14px;">
  <span>&copy; 2026 {CLIENT_NAME}. All rights reserved.</span>
  <!-- footer credit stamp here -->
</div>
```

The stamp inherits the footer's text color (`color: inherit`). On a dark footer the name renders light, and on a light footer it renders dark, with no variants to manage.

---

## B. KGP footer (KGP-owned products)

Replace `{LOGO_FILE}` with the lockup that suits the footer's background:

- **Dark footer** → `kgp-lockup-h-dark.svg` (white lettering)
- **Light footer** → `kgp-lockup-h-light.svg` (black lettering)

Copy the file from `${CLAUDE_PLUGIN_ROOT}/templates/brand-2026/lockup-horizontal/`. The colors come from the `--kgp-*` theme variables (see `references/color-system.md`).

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

    <!-- Logo -->
    <a href="https://kgprodesign.com" style="display: inline-flex;">
      <img src="{LOGO_FILE}" alt="KG ProDesign" style="height: 40px; width: auto;" />
    </a>

    <!-- Contact -->
    <div style="display: flex; gap: 24px; flex-wrap: wrap;">
      <a href="mailto:info@kgprodesign.com" style="color: var(--kgp-accent, #E07070); text-decoration: none;">
        info@kgprodesign.com
      </a>
      <a href="tel:+14079007724" style="color: var(--kgp-accent, #E07070); text-decoration: none;">
        (407) 900-7724
      </a>
      <a href="https://kgprodesign.com" style="color: var(--kgp-accent, #E07070); text-decoration: none;">
        kgprodesign.com
      </a>
    </div>

    <!-- Copyright -->
    <div style="width: 100%; text-align: center; padding-top: 24px; border-top: 1px solid var(--kgp-border-light, #27272A);">
      <p style="margin: 0; color: var(--kgp-text-muted, #71717A);">
        &copy; <span id="kgp-year">2026</span> KG ProDesign LLC. All rights reserved.
      </p>
      <script>document.getElementById('kgp-year').textContent = new Date().getFullYear();</script>
    </div>

  </div>
</footer>
```

On static sites without JavaScript, drop the `<script>` and keep the current year in the `<span>`.
