# KG ProDesign — Logo Assets & Selection Logic

<inventory>

## Logo Inventory

All logos live in the plugin's `templates/` directory. When working in another project, use `${CLAUDE_PLUGIN_ROOT}/templates/` to resolve the absolute path.

| File | Plugin Path | Dimensions | Description | Background |
|------|-------------|-----------|-------------|------------|
| **Horizontal (dark text)** | `${CLAUDE_PLUGIN_ROOT}/templates/KGProDesign_LOGO.png` | ~1100x400 | Red "KG" + **black** "ProDesign", transparent bg | For **light** backgrounds |
| **Horizontal (white text)** | `${CLAUDE_PLUGIN_ROOT}/templates/KGProDesign_wht.png` | ~993x309 | Red "KG" + **white outlined** "ProDesign", transparent bg | For **dark** backgrounds |
| **Square (dark bg)** | `${CLAUDE_PLUGIN_ROOT}/templates/KGProDesign_logo_square.png` (if copied) or external | 1024x1024 | Full logo on dark background with diamond accent | App icons, social avatars |
| **Favicon** | `${CLAUDE_PLUGIN_ROOT}/templates/favicon.jpg` | ~200x200 | Red "KG" lettermark crop | Browser favicons, small icons |

</inventory>

<copy_to_project>

## Copying Logos to Your Project

When branding a project outside the plugin directory, copy the needed logo files into the project's asset directory. Use `$CLAUDE_PLUGIN_ROOT` to locate the source files.

**Common patterns:**

```bash
# Web project (public/images/)
cp "${CLAUDE_PLUGIN_ROOT}/templates/KGProDesign_LOGO.png" ./public/images/
cp "${CLAUDE_PLUGIN_ROOT}/templates/KGProDesign_wht.png" ./public/images/
cp "${CLAUDE_PLUGIN_ROOT}/templates/favicon.jpg" ./public/

# React/Next.js (src/assets/ or public/)
cp "${CLAUDE_PLUGIN_ROOT}/templates/KGProDesign_LOGO.png" ./src/assets/
cp "${CLAUDE_PLUGIN_ROOT}/templates/KGProDesign_wht.png" ./src/assets/

# iOS/macOS (copy to Xcode asset catalog source)
cp "${CLAUDE_PLUGIN_ROOT}/templates/KGProDesign_LOGO.png" ./Assets.xcassets/KGProDesign.imageset/

# General (project root images/)
mkdir -p ./images
cp "${CLAUDE_PLUGIN_ROOT}/templates/KGProDesign_LOGO.png" ./images/
cp "${CLAUDE_PLUGIN_ROOT}/templates/KGProDesign_wht.png" ./images/
cp "${CLAUDE_PLUGIN_ROOT}/templates/favicon.jpg" ./images/
```

**Always copy — never reference the plugin path in production code.** The plugin path may change between versions or machines. Copy the files into the project so they are self-contained.

</copy_to_project>

<selection_logic>

## Logo Selection Decision Tree

```
Is the background DARK? (black, navy, dark gray, dark theme, #000-#444)
  ├── YES → Copy & use: KGProDesign_wht.png (white outlined text)
  └── NO → Is the background LIGHT? (white, cream, light gray, #CCC-#FFF)
       ├── YES → Copy & use: KGProDesign_LOGO.png (black text)
       └── UNSURE → ASK THE USER. Never guess.

Is the context a SQUARE/ICON? (favicon, app icon, profile picture, avatar)
  ├── YES, browser favicon → Copy & use: favicon.jpg
  ├── YES, app icon (iOS/macOS) → Copy & use: KGProDesign_logo_square.png
  └── YES, social media avatar → Copy & use: KGProDesign_logo_square.png

Source all files from: ${CLAUDE_PLUGIN_ROOT}/templates/
Always copy into the target project — never reference the plugin path in production.

Is SVG required? (scalable web logo, print)
  └── YES → FLAG AS MISSING. No SVG versions currently exist.
```

### Quick Reference

| Destination | Logo File |
|-------------|-----------|
| Dark website footer | `KGProDesign_wht.png` |
| Light website header | `KGProDesign_LOGO.png` |
| Dark sidebar / nav | `KGProDesign_wht.png` |
| White about page | `KGProDesign_LOGO.png` |
| Browser favicon | `favicon.jpg` |
| iOS app icon | `KGProDesign_logo_square.png` |
| Email signature (light bg) | `KGProDesign_LOGO.png` (scale to ~200px wide) |
| Email signature (dark bg) | `KGProDesign_wht.png` (scale to ~200px wide) |
| README badge | `KGProDesign_LOGO.png` (inline, ~120px wide) |
| Social media avatar | `KGProDesign_logo_square.png` |
| Open Graph / share card | FLAG MISSING — needs `KGProDesign_og.png` |

</selection_logic>

<brand_colors>

## Logo Color Palette

The "KG" lettermark uses a signature red. The exact hex should be confirmed, but approximate values:
- **KG Red (approximate):** `#B91C1C` (dark crimson red)
- **ProDesign Black:** `#1A1A1A` (near-black, used in dark text variant)
- **ProDesign White Outline:** `#FFFFFF` with dark stroke (used in white variant)

</brand_colors>

<clear_zone>

## Clear Zone & Minimum Size

- **Clear zone:** Maintain padding equal to the height of the "K" letterform on all sides
- **Minimum width (horizontal logo):** 120px for web, 1 inch for print
- **Minimum size (square logo):** 32x32px for web icons, 16x16px for favicons
- **Do not:** rotate, stretch, recolor, add effects, or place on busy backgrounds without sufficient contrast

</clear_zone>

<missing_assets>

## Missing Assets Checklist

Assets that should be created for full branding coverage:

- [ ] **`KGProDesign_LOGO.svg`** — SVG version of horizontal logo (scalable for web/print)
- [ ] **`KGProDesign_wht.svg`** — SVG version of white variant
- [ ] **`KGProDesign_favicon.svg`** — Modern SVG favicon for browsers
- [ ] **`KGProDesign_og.png`** — Open Graph social sharing image (1200x630, dark bg with centered logo)
- [ ] **`KGProDesign_logo_192.png`** — PWA icon (192x192, derived from square)
- [ ] **`KGProDesign_logo_512.png`** — PWA icon (512x512, derived from square)
- [ ] **`KGProDesign_email_200.png`** — Email signature logo (~200px wide, derived from horizontal)
- [ ] **Confirmed "KG Red" hex value** — exact brand red from original design files

### How to Create Missing Assets

1. **SVG versions:** Export from original vector source (Illustrator/Figma). If only raster exists, use a vector tracing tool.
2. **OG image:** Create 1200x630 dark background (#0F172A) with centered horizontal white logo, company tagline below.
3. **PWA icons:** Resize `KGProDesign_logo_square.png` to 192x192 and 512x512.
4. **Email logo:** Resize `KGProDesign_LOGO.png` to 200px wide, maintaining aspect ratio.

</missing_assets>
