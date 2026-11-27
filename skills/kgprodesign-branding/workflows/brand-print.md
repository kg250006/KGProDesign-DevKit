# Workflow: Print & Handouts (business card, flyer)

KG ProDesign has finished, print-ready handouts for meeting people in person. Use these files as they are. Don't redesign them unless KG asks.

## Step 1: What does the user need?

| Need | Give them |
|---|---|
| Send to an **online printer** (Vistaprint, MOO, etc.) | `print/business-card-2-sided.pdf`, `print/flyer-4x6.pdf` |
| Send to a **local print shop** | `print/business-card-2-sided-cropmarks.pdf`, `print/flyer-4x6-cropmarks.pdf` |
| **Share or preview** on a phone, email or social | `print/share/KGP-business-card-{front,back}.png`, `print/share/KGP-flyer-4x6-{front,back}.png` |
| A **new or changed** handout | Go to Step 4 |

All paths are under `${CLAUDE_PLUGIN_ROOT}/templates/brand-2026/`. Copy the files into the user's working folder; never hand out the plugin path itself.

## Step 2: Specs (tell the printer)

| Piece | Finished size | File size (with bleed) | Pages |
|---|---|---|---|
| Business card | 3.5 × 2 in | 3.75 × 2.25 in | 2 (1 = front, 2 = back) |
| Flyer | 4 × 6 in, portrait | 4.25 × 6.25 in | 2 (1 = front, 2 = back) |

- **Resolution:** 300 dpi.
- **Bleed:** 0.125in on every edge. Backgrounds run into it.
- **Safe area:** text stays 0.125in inside the trim.
- **Smallest text:** about 6pt.
- **PDF boxes:** TrimBox and BleedBox are set.
- **Color:** the files are RGB. The printer converts them to CMYK, so **order a printed proof** before the first full run. The brand reds can shift.
- **Print maroon:** the pieces use `#6E1F1F` (the screen red `#8C2828` prints muddy).

## Step 3: What's on them (so you can describe or quote them)

**Business card**
- **Front (black):**
  - the KGP shield with KG PRODESIGN LLC
  - IDEAS INTO INTELLIGENT SOLUTIONS
  - EST. 2005
- **Back (white):**
  - KENRICK “KG” GOLDSON, FOUNDER · KG PRODESIGN LLC
  - the four featured services, each with a short line (see `references/company-info.md` → Featured services)
  - 321-427-6753 · KG@KGProDesign.com · kgprodesign.com · IG @KGProDesign · github.com/kgprodesign
  - a shield, then "SCAN TO START" over the QR code

**Flyer 4x6**
- **Front (black):**
  - the logo with LLC
  - YOUR WEBSITE, HANDLED. START TO FINISH.
  - "One partner for design, hosting, and advice, so you can focus on your business."
  - the four services on a maroon band
  - the tagline, kgprodesign.com and the phone
- **Back (white):**
  - YOUR WEB PARTNER SINCE 2005, with a large shield badge
  - the four services with one-line benefits
  - KG's name and title
  - a black footer with SCAN TO START YOUR PROJECT, the QR code and all contacts

**QR codes:** they open `https://kgprodesign.com/contact/` with `utm_source=print&utm_campaign=road-2026`, plus `utm_medium=card` or `utm_medium=flyer`, so leads can be traced to the piece. Keep the tags if the code is reused.

**The phone number is 321-427-6753 on handouts only.** Everywhere else, use the company number 407-900-7724 (`references/company-info.md`).

## Step 4: Changes or new handouts

The art is generated, not hand-drawn. The source is in the KGP-ContentCreatorApp repo:

```bash
cd <KGP-ContentCreatorApp>/assets/brands/kgprodesign/kit-2026
pip install segno pypdf        # QR codes + PDF trim/bleed boxes
python build_print.py          # rebuilds print/*.pdf and the PNGs
```

1. Edit the copy and contacts at the top of `build_print.py` (`NAME`, `PHONE`, `SERVICES`, ...).
2. Rebuild, then check `print/_print-proof.png`: red = trim, green = safe area.
3. Re-scan both QR codes.
4. Copy the new `print/` files back into `templates/brand-2026/print/` here.

For a **new** piece (poster, banner stand, sticker), follow the same rules:
- black / white / maroon `#6E1F1F` for print
- the shield, and the lockup from `lockup-*/` (never retyped)
- Anton headlines, Inter body (fonts in `fonts/`, OFL)
- 0.125in bleed, a safe margin, 300 dpi, text at 6pt or larger
- QR codes with a 4-module white quiet zone

Run any new marketing copy past the marketing strategist first.
