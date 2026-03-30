# Workflow: Brand Legal Text

<required_reading>

Read these reference files NOW:
1. `references/company-info.md` — legal entity, copyright format

</required_reading>

<process>

## Step 1: Determine Type

Ask the user what legal text is needed:

1. **Copyright notice** — for website, app, or code
2. **License header** — for source code files
3. **License file** — full LICENSE/LICENSE.md
4. **Terms of service branding** — company name in ToS
5. **Privacy policy branding** — company name in privacy policy

## Step 2: Generate Branded Output

### Copyright Notices

Use `templates/copyright-notice.md` for various formats:

**HTML footer:**
```html
<p>&copy; <span id="year"></span> KG ProDesign LLC</p>
<script>document.getElementById('year').textContent = new Date().getFullYear();</script>
```

**JavaScript/TypeScript source header:**
```javascript
/**
 * Copyright (c) present KG ProDesign LLC
 * All rights reserved.
 */
```

**Python source header:**
```python
# Copyright (c) present KG ProDesign LLC
# All rights reserved.
```

**Swift source header:**
```swift
// Copyright (c) present KG ProDesign LLC
// All rights reserved.
```

### License File (MIT)

```
MIT License

Copyright (c) present KG ProDesign LLC

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

### Terms of Service / Privacy Policy

For legal documents, replace placeholder company references with:
- **Company name:** KG ProDesign LLC
- **Contact email:** info@kgprodesign.com
- **Phone:** 407-900-7724
- **Website:** kgprodesign.com
- **Address:** (to be provided — flag if needed for legal docs)

Note: This skill provides branding text only, not legal advice. Recommend the user consult a legal professional for full ToS/privacy policy content.

## Step 3: Deliver

Present the formatted legal text ready for use.

</process>

<success_criteria>

- Copyright uses `KG ProDesign LLC` (not parent entity)
- Year format is `present` for source code or `{CURRENT_YEAR}` with dynamic year for web
- License file uses correct entity name
- Comment style matches the target programming language
- Legal disclaimer included when providing ToS/privacy guidance

</success_criteria>
