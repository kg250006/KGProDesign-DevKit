# KG ProDesign — Logo Assets & Selection Logic

> **Rebranded 2026-11-27.** The identity is now the **KGP hexagon shield** with **KG ProDesign**
> lettering in Anton (all caps), in black / white / maroon `#8C2828` (`#6E1F1F` in print). The red-slash script logo
> (`KGProDesign_LOGO.png`, `KGProDesign_wht.png`, `favicon.jpg`) is **retired**. Those files are kept in
> `templates/legacy/` for history only. Never use them in new work.

<inventory>

## Logo Inventory

All files are in `${CLAUDE_PLUGIN_ROOT}/templates/brand-2026/`. **SVG is the master format.** Every version has an SVG, so use the SVG wherever the target supports it, and the PNGs elsewhere.

"**dark**" means made **for dark backgrounds** (white lettering). "**light**" means for light backgrounds (black lettering).

| Version | Files | What it is |
|---|---|---|
| **Shield (full color)** | `mark/kgp-mark-color.svg`, `-1024.png` | Maroon rim, white ring, black field, white KGP. It carries its own black field, so it works on **any** background |
| **Shield (one color)** | `mark/kgp-mark-mono-{white,black,maroon}.svg`, `-1024.png` | Solid shield with the letters knocked out, for print, engraving, embroidery and stamps |
| **Horizontal lockup** | `lockup-horizontal/kgp-lockup-h-{dark,light}.svg`, `-64.png`, `-64@2x.png`; `kgp-lockup-h-on-{black,white}.png` | Shield + "KG ProDesign" on one line, for nav bars and headers |
| **Stacked lockup** | `lockup-stacked/kgp-lockup-stacked-{dark,light}.svg`, `-512.png` | Shield above the name, for about pages, splash screens and documents |
| **Lockup + tagline** | `lockup-tagline/kgp-lockup-tagline-{dark,light}.svg`, `-128/256/512.png` | Lockup with the name underlined in maroon and the tagline below, for banners, decks and email headers |
| **Wordmark** | `wordmark/kgp-wordmark-{dark,light}.svg`, `-128.png` | The lettering only |
| **Square** | `square/kgp-square-{black,white}.svg`, `-1024.png`, `-400.png` | Shield centered with padding, for avatars and app-icon sources |
| **App / PWA icons** | `square/apple-touch-icon.png` (180), `icon-192.png`, `icon-512.png` | On black |
| **Favicon** | `favicon/favicon.ico` (16/32/48), `favicon.svg`, `favicon-{16,32,48}.png` | Transparent background. 16/32px use the small-size shield (thick rim, no ring), 48px the full shield |
| **Share card** | `social/kgp-og-image-1200x630.png` | Open Graph / link preview |
| **Profile picture** | `social/kgp-profile-800.png` | Padded for circular crops |
| **Rules** | `BRAND.md`, `palette.json` | Clear space, minimum sizes, colors, don'ts |

The lettering is **Anton**, set in all caps as **KG PRODESIGN** with slightly open spacing. The outlines are built into the files, so no font install is needed.

</inventory>

<copy_to_project>

## Copying Logos to Your Project

**Always copy, and never reference the plugin path in production code.** The plugin path changes between versions and machines.

```bash
B="${CLAUDE_PLUGIN_ROOT}/templates/brand-2026"

# Web project
mkdir -p ./public/images
cp "$B/lockup-horizontal/kgp-lockup-h-dark.svg" "$B/lockup-horizontal/kgp-lockup-h-light.svg" ./public/images/
cp "$B/mark/kgp-mark-color.svg" ./public/images/
cp "$B/favicon/favicon.ico" "$B/favicon/favicon.svg" ./public/
cp "$B/square/apple-touch-icon.png" "$B/square/icon-192.png" "$B/square/icon-512.png" ./public/
cp "$B/social/kgp-og-image-1200x630.png" ./public/og-image.png

# iOS / macOS app icon source (1024x1024)
cp "$B/square/kgp-square-black-1024.png" ./AppIcon-1024.png
```

```html
<link rel="icon" href="/favicon.ico" sizes="any">
<link rel="icon" href="/favicon.svg" type="image/svg+xml">
<link rel="apple-touch-icon" href="/apple-touch-icon.png">
<meta property="og:image" content="https://YOUR-DOMAIN/og-image.png">
```

</copy_to_project>

<selection_logic>

## Logo Selection Decision Tree

```
Is it a KGP-owned product or page (header, nav, about page)?
  ├── Dark background  → lockup-horizontal/kgp-lockup-h-dark.svg
  ├── Light background → lockup-horizontal/kgp-lockup-h-light.svg
  ├── Centered / hero  → lockup-stacked/kgp-lockup-stacked-{dark,light}.svg
  └── Tiny space, busy or photo background → mark/kgp-mark-color.svg (it carries its own black field)

Is it a CLIENT site KG ProDesign built? → Use the FOOTER CREDIT STAMP (templates/footer-html.md),
  never a full logo. The label depends on hosting:
  ├── KG ProDesign hosts it → "Dev & Hosted By"
  └── Hosted elsewhere      → "Developed By"
  Unsure who hosts it? ASK. Never guess.

Is it a SQUARE / ICON? (favicon, app icon, avatar)
  ├── Browser favicon → favicon/favicon.ico + favicon.svg
  ├── App icon        → square/kgp-square-black-1024.png
  └── Social avatar   → social/kgp-profile-800.png

One-color reproduction (print, engraving, embroidery)? → mark/kgp-mark-mono-{black,white,maroon}.svg

Background is neither clearly dark nor light? → ASK THE USER. Never guess.
```

### Quick Reference

| Destination | File |
|-------------|------|
| Dark site header / nav | `lockup-horizontal/kgp-lockup-h-dark.svg` |
| Light site header / nav | `lockup-horizontal/kgp-lockup-h-light.svg` |
| About page / splash | `lockup-stacked/kgp-lockup-stacked-{dark,light}.svg` |
| Client-site footer credit | Footer stamp: shield SVG + "KG ProDesign" as **text** (see `templates/footer-html.md`) |
| Browser favicon | `favicon/favicon.ico` + `favicon/favicon.svg` |
| iOS / macOS app icon | `square/kgp-square-black-1024.png` |
| Social avatar | `social/kgp-profile-800.png` |
| Open Graph / share card | `social/kgp-og-image-1200x630.png` |
| Email signature | `lockup-horizontal/kgp-lockup-h-light-64@2x.png` (hosted URL, displayed at 200px wide) |
| README badge | `lockup-horizontal/kgp-lockup-h-light-64@2x.png` (hosted URL) |

</selection_logic>

<brand_colors>

## Logo Colors

| Token | Hex | Role |
|---|---|---|
| Black | `#000000` | Shield field, primary background |
| White | `#FFFFFF` | Letters and ring |
| **Maroon** | `#8C2828` | **Screen brand red.** The shield rim, underline bars and accents. 2.4:1 on black, so never use it for text on dark |
| Maroon print | `#6E1F1F` | The same red for print and paper |
| Maroon light | `#A33A3A` | Maroon text on dark backgrounds (3.2:1 on black, so large text only) |

</brand_colors>

<clear_zone>

## Clear Zone & Minimum Size

- **Clear zone:** leave at least the width of the P's stem (about 7.5% of the shield's height) on every side.
- **Minimum:** shield 32px, horizontal lockup 32px tall, wordmark letters 12px tall. The 16 and 32px favicons use a small-size shield with a thick rim and no white ring, so they stay red and crisp. From 48px up, use the full shield.
- **Don't:**
  - stretch, rotate or recolor the shield's layers
  - add effects
  - put the full-color shield on a busy photo without a dark plate
  - set the logo name in another font or retype it by hand. Use the wordmark and lockup files. Plain-text "KG ProDesign" in running text or the footer credit is fine

</clear_zone>

<missing_assets>

## Asset Status

Everything on the 2025 missing-assets list now exists: SVG versions of every logo, an SVG favicon, the OG image, PWA icons at 192 and 512, an email-size lockup, and a confirmed brand red (`#8C2828` on screen, `#6E1F1F` in print).

Still open: **hosted public URLs** for the email signature and README logos. Upload `kgp-lockup-h-light-64@2x.png` to kgprodesign.com and record the URL here.

</missing_assets>
