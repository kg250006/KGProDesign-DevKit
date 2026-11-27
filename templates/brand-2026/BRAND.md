# KG ProDesign — Brand Kit 2026

> **Plugin copy (subset).** The full kit (every size, post templates, fonts, and the scripts that rebuild it) lives in the KGP-ContentCreatorApp repo at `assets/brands/kgprodesign/kit-2026/`. Paths below that are missing here (`templates/`) are in that repo.

Adopted 2026-11-27. Replaces the red-slash script logo and #A51414 red.
Every file here is generated from **`kgp_geometry.py`** by **`build_kit.py`**:
edit the geometry, run `python build_kit.py --all`, and the whole kit rebuilds.
`python build_kit.py --proof` writes `_proof.png` for review.

## The mark

A hexagon shield (maroon rim → white ring → black field) with an angular **KGP**
monogram. It was rebuilt as true vector from KG's draft as a rule-based system:
- maroon band 46u, white ring 36u (thickened 2026-11-27 so it holds up at 32-64px)
- letters sit 57u inside the black field, with stroke ~125u and gaps 62u
- K and P are exact mirror images
- the letter tops follow the shield's shoulders, and the bottoms follow its V

## Colors

| Token | Hex | Use |
|---|---|---|
| Black | `#000000` | Primary background, shield field |
| White | `#FFFFFF` | Letters, ring, text on dark |
| Maroon | `#8C2828` | Screen brand red: shield rim, underline bars, accents |
| Maroon print | `#6E1F1F` | The same red for print and paper (the draft's maroon) |
| Maroon light | `#A33A3A` | Maroon **text on dark** backgrounds. 3.2:1 on black, so large text only |
| Charcoal | `#1A1A1A` | Surfaces |
| Rim charcoal | `#272323` | The ghost shield-rim lines on banners and post templates (inner line `#1D1A1A`) |
| Gray | `#8F8F8F` | Secondary text, rules |

Maroon `#8C2828` on black is 2.4:1. Use it there for decoration (the rim, rules), never for text.

## Type

- **Lettering:** **Anton** (OFL, `fonts/Anton-Regular.ttf`), converted to vector outlines by `kgp_geometry.py` and set in all caps as **KG PRODESIGN**, with slightly open letter spacing. Use the supplied lettering files; never retype "KG PRODESIGN" in a font.
- **Headlines:** Anton. **Body:** Inter. Both are unchanged from before.
- **Footer credit on client sites:** the shield image plus **"KG ProDesign" as live text** in Inter medium at 12px. It's not a logo, so text is correct there. The label says **"Dev & Hosted By"** when KG ProDesign hosts the site and **"Developed By"** when it's hosted elsewhere. See the footer stamp in the brand guide.

## Which file where

| Need | File |
|---|---|
| Website nav bar, dark header | `lockup-horizontal/kgp-lockup-h-dark.svg` (or `-64.png` / `-64@2x.png`) |
| Website nav bar, light header | `lockup-horizontal/kgp-lockup-h-light.svg` |
| Logo with name, centered (about pages, docs, splash) | `lockup-stacked/kgp-lockup-stacked-{dark,light}.svg` |
| Logo with tagline (banners, decks, email headers) | `lockup-tagline/kgp-lockup-tagline-{dark,light}.svg` |
| Name only | `wordmark/kgp-wordmark-{dark,light}.svg` |
| Shield only, any background | `mark/kgp-mark-color.svg` (it carries its own black field) |
| Shield on a white page, when you want a stronger edge (optional) | `mark/kgp-mark-color-light-bg.svg`. The ring area is black with a thin white keyline, so it doesn't merge into the page |
| One color (print, engraving, embroidery, stamps) | `mark/kgp-mark-mono-{white,black,maroon}.svg` |
| Social profile picture | `social/kgp-profile-800.png` (padded for circle crops) or `square/kgp-square-black-*.png` |
| Favicon | `favicon/favicon.ico` + `favicon/favicon.svg` |
| Apple / PWA icons | `square/apple-touch-icon.png`, `square/icon-192.png`, `square/icon-512.png` |
| Banners | `social/` holds YouTube 2560x1440, X 1500x500, Facebook 1640x624, LinkedIn 1584x396, and link preview (OG) 1200x630 |
| Post templates | `templates/post-template{,-white}.png` |
| Post watermark | Wired in `profiles/brands/kgprodesign.json` (horizontal lockup @2x) |

"dark" = made **for dark backgrounds** (white lettering). "light" = for light backgrounds.

```html
<link rel="icon" href="/favicon.ico" sizes="any">
<link rel="icon" href="/favicon.svg" type="image/svg+xml">
<link rel="apple-touch-icon" href="/apple-touch-icon.png">
```

## Rules

- **Clear space:** leave at least the width of the P's stem (about 7.5% of the shield's height) on every side.
- **Minimum sizes:** shield 32px. Horizontal lockup 32px tall (proofed at 40px). Wordmark letters 12px tall.
- **Favicon 16 and 32px:** a small-size shield with a thick maroon rim and **no white ring** (at that size the ring turns grey and the thin rim turns pink), with KGP scaled into the black field. 48px and up use the full shield.
- **Don't:**
  - stretch or skew the logo
  - recolor the shield's layers
  - put the full-color shield on a busy photo without a dark plate
  - outline or add drop shadows to the lettering
  - set the logo name in any other font, or retype it by hand in Anton. The small-cap sizing and weight are tuned, so use the wordmark and lockup files. Plain-text "KG ProDesign" in running text or the footer credit is fine
  - use maroon `#8C2828` for text on black (use `#A33A3A`, large text only)
