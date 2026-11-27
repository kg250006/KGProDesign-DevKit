# Template: Email Signature (HTML)

Replace placeholders: `{NAME}`, `{TITLE}`, `{EMAIL}`, `{LOGO_URL}`.

The logo URL must be a publicly hosted image (email clients don't render local files).
Use `brand-2026/lockup-horizontal/kgp-lockup-h-light-64@2x.png` (black lettering) for light email themes, or `kgp-lockup-h-dark-64@2x.png` for dark ones. Host it publicly first.

```html
<table cellpadding="0" cellspacing="0" border="0" style="font-family: Arial, Helvetica, sans-serif; font-size: 14px; color: #333333; line-height: 1.5;">
  <tr>
    <td style="padding-right: 16px; border-right: 2px solid #8C2828; vertical-align: top;">
      <img
        src="{LOGO_URL}"
        alt="KG ProDesign"
        width="120"
        style="display: block;"
      />
    </td>
    <td style="padding-left: 16px; vertical-align: top;">
      <table cellpadding="0" cellspacing="0" border="0">
        <tr>
          <td style="font-size: 16px; font-weight: bold; color: #18181B; padding-bottom: 2px;">
            {NAME}
          </td>
        </tr>
        <tr>
          <td style="font-size: 13px; color: #64748B; padding-bottom: 8px;">
            {TITLE} | KG ProDesign LLC
          </td>
        </tr>
        <tr>
          <td style="font-size: 13px; padding-bottom: 2px;">
            <a href="mailto:{EMAIL}" style="color: #8C2828; text-decoration: none;">{EMAIL}</a>
          </td>
        </tr>
        <tr>
          <td style="font-size: 13px; padding-bottom: 2px;">
            <a href="tel:+14079007724" style="color: #8C2828; text-decoration: none;">(407) 900-7724</a>
          </td>
        </tr>
        <tr>
          <td style="font-size: 13px;">
            <a href="https://kgprodesign.com" style="color: #8C2828; text-decoration: none;">kgprodesign.com</a>
          </td>
        </tr>
      </table>
    </td>
  </tr>
</table>
```

**Notes:**
- Uses Arial as fallback (custom fonts won't render in most email clients)
- Brand maroon `#8C2828` for the divider and links (8.6:1 on white)
- Inline CSS only — email clients strip `<style>` tags
- Table-based layout for maximum email client compatibility
- Logo should be hosted publicly (e.g., on your website) and referenced by URL
- Recommended logo width: 200px (horizontal lockup)
