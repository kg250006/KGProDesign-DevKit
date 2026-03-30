# Workflow: Brand an App

<required_reading>

Read these reference files NOW:
1. `references/company-info.md` — company data, copyright
2. `references/logo-assets.md` — logo selection for app contexts
3. `references/color-system.md` — theme colors for app UI

</required_reading>

<process>

## Step 1: Determine Platform

Ask the user what platform:

1. **iOS (SwiftUI)** — About view, splash screen, app icon
2. **iOS (UIKit)** — About view controller
3. **macOS (SwiftUI)** — About window, app icon
4. **Cross-platform / Web app** — About page, PWA manifest

## Step 2: Determine Scope

Ask what branding is needed:

1. **About screen / dialog** — company info, version, copyright
2. **Splash screen** — logo display during launch
3. **App icon** — logo asset guidance
4. **Info.plist / manifest** — metadata fields
5. **All of the above**

## Step 3: Select Logo Assets

Copy needed logos from the plugin into the project:
```bash
cp "${CLAUDE_PLUGIN_ROOT}/templates/{SELECTED_LOGO}" ./{project-asset-dir}/
```

| Context | Source File | Notes |
|---------|------------|-------|
| App icon (iOS) | `${CLAUDE_PLUGIN_ROOT}/templates/KGProDesign_logo_square.png` | Resize to required sizes (1024x1024 source) |
| App icon (macOS) | `${CLAUDE_PLUGIN_ROOT}/templates/KGProDesign_logo_square.png` | macOS icons can be rounded |
| Splash (dark bg) | `${CLAUDE_PLUGIN_ROOT}/templates/KGProDesign_wht.png` | Centered on dark launch screen |
| Splash (light bg) | `${CLAUDE_PLUGIN_ROOT}/templates/KGProDesign_LOGO.png` | Centered on light launch screen |
| About screen | Either variant based on screen bg | Use selection logic from logo-assets.md |
| PWA icon 192 | FLAG MISSING | Needs `KGProDesign_logo_192.png` |
| PWA icon 512 | FLAG MISSING | Needs `KGProDesign_logo_512.png` |

## Step 4: Generate Branded Output

### SwiftUI About View

Use `templates/app-about-swift.md` to generate a SwiftUI view containing:
- Logo image
- App name and version (from Bundle)
- "Developed by KG ProDesign LLC"
- Copyright: `© {CURRENT_YEAR} KG ProDesign LLC`
- Contact links (website, email, phone)

### Info.plist Fields

```xml
<key>CFBundleName</key>
<string>{App Name}</string>
<key>NSHumanReadableCopyright</key>
<string>© {YEAR} KG ProDesign LLC</string>
```

### PWA Manifest

```json
{
  "name": "{App Name}",
  "short_name": "{Short Name}",
  "description": "{Description}",
  "icons": [
    { "src": "/icons/kgprodesign-192.png", "sizes": "192x192", "type": "image/png" },
    { "src": "/icons/kgprodesign-512.png", "sizes": "512x512", "type": "image/png" }
  ]
}
```

## Step 5: Deliver and Flag Missing Assets

Present the branded code. Flag any missing assets from `references/logo-assets.md` that are needed (e.g., PWA icons).

</process>

<success_criteria>

- Correct logo variant for the app's background context
- Copyright uses dynamic year format
- About screen shows accurate company info
- App icon uses the square logo variant
- Missing assets flagged with specs for creation

</success_criteria>
