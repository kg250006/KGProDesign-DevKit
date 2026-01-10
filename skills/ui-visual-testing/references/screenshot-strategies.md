# Screenshot Strategies Reference

<objective>
Guidelines for when, how, and why to capture screenshots during UI testing. Covers capture patterns, storage conventions, and optimization techniques.
</objective>

---

## When to Use Screenshots

### Use Screenshots When

| Scenario | Reason |
|----------|--------|
| Visual regression testing | Compare UI state against baseline |
| Bug documentation | Evidence for bug reports |
| Test failure | Capture state at point of failure |
| Layout verification | Verify responsive design, positioning |
| Style validation | Check colors, fonts, spacing visually |
| Before/after comparison | Document changes from an action |
| Accessibility audit | Document visual accessibility issues |

### Don't Use Screenshots When

| Scenario | Better Alternative |
|----------|-------------------|
| Checking element exists | `page.$()` - faster, no I/O |
| Verifying text content | `page.$eval()` - precise assertion |
| Checking form values | DOM inspection - exact match |
| Functional testing | Assertions - deterministic |
| API response validation | Direct response check |
| Performance testing | Metrics APIs |

**Rule**: If you can assert the condition programmatically, don't screenshot.

---

## Capture Patterns

### Full Page Screenshot
```typescript
// Capture entire scrollable page
await page.screenshot({
  path: 'full-page.png',
  fullPage: true,
});
```
**Use for**: Landing pages, complete layout verification, documentation

### Viewport Screenshot
```typescript
// Capture only visible viewport
await page.screenshot({
  path: 'viewport.png',
  fullPage: false,  // default
});
```
**Use for**: Above-the-fold content, what user sees on load

### Element Screenshot
```typescript
// Capture specific element
const element = await page.$('.hero-section');
await element?.screenshot({ path: 'hero.png' });
```
**Use for**: Component testing, isolated UI elements, widgets

### Clip Region Screenshot
```typescript
// Capture specific region by coordinates
await page.screenshot({
  path: 'region.png',
  clip: {
    x: 100,
    y: 200,
    width: 400,
    height: 300,
  },
});
```
**Use for**: Specific areas without element selector, cropping

### Multiple Viewports
```typescript
const viewports = [
  { name: 'mobile', width: 375, height: 667 },
  { name: 'tablet', width: 768, height: 1024 },
  { name: 'desktop', width: 1920, height: 1080 },
];

for (const vp of viewports) {
  await page.setViewport({ width: vp.width, height: vp.height });
  await page.screenshot({ path: `${pageName}-${vp.name}.png`, fullPage: true });
}
```
**Use for**: Responsive design testing, cross-device verification

---

## Screenshot Options

### Quality and Format
```typescript
// PNG (default) - lossless, larger files
await page.screenshot({
  path: 'image.png',
  type: 'png',
});

// JPEG - smaller files, lossy compression
await page.screenshot({
  path: 'image.jpg',
  type: 'jpeg',
  quality: 80,  // 0-100
});

// WebP - best compression, modern format
await page.screenshot({
  path: 'image.webp',
  type: 'webp',
  quality: 80,
});
```

### Transparency
```typescript
// With transparent background (PNG only)
await page.screenshot({
  path: 'transparent.png',
  omitBackground: true,
});
```

### Return Buffer Instead of File
```typescript
// Get base64 string
const base64 = await page.screenshot({ encoding: 'base64' });

// Get binary buffer
const buffer = await page.screenshot({ encoding: 'binary' });

// Use buffer (e.g., upload to cloud storage)
await uploadToS3(buffer, 'screenshot.png');
```

---

## Pre-Screenshot Preparation

### Wait for Content to Load
```typescript
// Wait for network idle
await page.goto(url, { waitUntil: 'networkidle0' });

// Wait for specific element
await page.waitForSelector('.content-loaded');

// Wait for fonts to load
await page.evaluateHandle('document.fonts.ready');

// Additional delay for animations to settle
await page.waitForTimeout(500);
```

### Hide Dynamic Content
```typescript
// Hide elements that vary (timestamps, ads, etc.)
await page.evaluate(() => {
  const hide = (selector: string) => {
    document.querySelectorAll(selector).forEach(el => {
      (el as HTMLElement).style.visibility = 'hidden';
    });
  };

  hide('.timestamp');
  hide('.ad-banner');
  hide('.loading-spinner');
  hide('[data-animated]');
  hide('.user-avatar');  // Different for each user
});
```

### Disable Animations
```typescript
// Disable CSS animations and transitions
await page.addStyleTag({
  content: `
    *, *::before, *::after {
      animation-duration: 0s !important;
      animation-delay: 0s !important;
      transition-duration: 0s !important;
      transition-delay: 0s !important;
    }
  `,
});
```

### Set Consistent State
```typescript
// Mock date/time for consistent screenshots
await page.evaluateOnNewDocument(() => {
  const fixedDate = new Date('2024-01-15T12:00:00Z');
  Date = class extends Date {
    constructor(...args: any[]) {
      if (args.length === 0) {
        super(fixedDate);
      } else {
        super(...args);
      }
    }
    static now() {
      return fixedDate.getTime();
    }
  } as any;
});
```

### Scroll to Element
```typescript
// Ensure element is in view before capturing
await page.$eval('.target-element', el => {
  el.scrollIntoView({ behavior: 'instant', block: 'center' });
});
await page.waitForTimeout(100);  // Wait for scroll to complete
```

---

## Storage and Naming Conventions

### Directory Structure
```
screenshots/
├── baselines/           # Reference screenshots
│   ├── desktop/
│   ├── tablet/
│   └── mobile/
├── current/             # Latest test run
│   └── YYYY-MM-DD/
├── diffs/               # Visual diff images
│   └── YYYY-MM-DD/
└── failures/            # Screenshots from failed tests
    └── YYYY-MM-DD/
```

### Naming Convention
```
{page-name}-{viewport}-{state}-{timestamp}.png

Examples:
homepage-desktop-initial-20240115-120000.png
login-mobile-error-state-20240115-120015.png
dashboard-tablet-logged-in-20240115-120030.png
```

### Filename Components
```typescript
function generateScreenshotPath(config: {
  page: string;
  viewport: string;
  state?: string;
  isBaseline?: boolean;
}): string {
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  const state = config.state ? `-${config.state}` : '';
  const dir = config.isBaseline ? 'baselines' : `current/${timestamp.split('T')[0]}`;

  return `screenshots/${dir}/${config.page}-${config.viewport}${state}.png`;
}
```

---

## Optimization Techniques

### Reduce File Size
```typescript
// Use JPEG for photos/complex images
if (hasPhotographicContent) {
  await page.screenshot({ path: 'image.jpg', type: 'jpeg', quality: 75 });
}

// Use PNG for UI with text/sharp edges
await page.screenshot({ path: 'ui.png', type: 'png' });

// Reduce viewport size if full resolution not needed
await page.setViewport({ width: 1280, height: 720, deviceScaleFactor: 1 });
```

### Capture Only What's Needed
```typescript
// Bad: Full page screenshot when only header matters
await page.screenshot({ fullPage: true });

// Good: Capture just the relevant element
const header = await page.$('header');
await header?.screenshot({ path: 'header.png' });
```

### Parallel Capture for Multiple Pages
```typescript
// Capture multiple pages concurrently
const urls = ['/home', '/about', '/contact'];
const browser = await puppeteer.launch();

await Promise.all(urls.map(async (url, i) => {
  const page = await browser.newPage();
  await page.goto(`${baseUrl}${url}`);
  await page.screenshot({ path: `page-${i}.png` });
  await page.close();
}));
```

### Skip Screenshots in CI When Not Needed
```typescript
const CAPTURE_SCREENSHOTS = process.env.CAPTURE_SCREENSHOTS !== 'false';

if (CAPTURE_SCREENSHOTS) {
  await page.screenshot({ path: 'evidence.png' });
}
```

---

## Failure Screenshot Patterns

### On Test Failure
```typescript
let testPassed = false;

try {
  // Test code here
  testPassed = true;
} catch (error) {
  // Capture screenshot on failure
  const timestamp = Date.now();
  await page.screenshot({
    path: `screenshots/failures/failure-${timestamp}.png`,
    fullPage: true,
  });

  // Also capture console logs
  const logs = await page.evaluate(() => {
    return (window as any).__consoleLogs || [];
  });

  throw error;
} finally {
  if (!testPassed) {
    console.log('Screenshot saved for failed test');
  }
}
```

### Before/After Action
```typescript
async function clickWithEvidence(page: Page, selector: string, name: string) {
  // Before state
  await page.screenshot({ path: `${name}-before.png` });

  // Perform action
  await page.click(selector);

  // Wait for result
  await page.waitForTimeout(500);

  // After state
  await page.screenshot({ path: `${name}-after.png` });
}
```

### Annotated Screenshots
```typescript
// Add visual annotation to screenshot
async function annotatedScreenshot(page: Page, selector: string, path: string) {
  // Add highlight overlay
  await page.evaluate((sel: string) => {
    const el = document.querySelector(sel);
    if (el) {
      const rect = el.getBoundingClientRect();
      const overlay = document.createElement('div');
      overlay.style.cssText = `
        position: fixed;
        top: ${rect.top - 5}px;
        left: ${rect.left - 5}px;
        width: ${rect.width + 10}px;
        height: ${rect.height + 10}px;
        border: 3px solid red;
        background: rgba(255, 0, 0, 0.1);
        z-index: 999999;
        pointer-events: none;
      `;
      overlay.id = 'test-overlay';
      document.body.appendChild(overlay);
    }
  }, selector);

  // Capture
  await page.screenshot({ path });

  // Remove overlay
  await page.evaluate(() => {
    document.getElementById('test-overlay')?.remove();
  });
}
```

---

## Common Issues

### Blurry Screenshots
**Cause**: Low device scale factor
**Fix**:
```typescript
await page.setViewport({
  width: 1280,
  height: 720,
  deviceScaleFactor: 2,  // Retina-quality
});
```

### Incomplete Content
**Cause**: Screenshot taken before content loaded
**Fix**: Wait for network idle and specific elements

### Different Fonts
**Cause**: System fonts vary between environments
**Fix**: Use web fonts or font mocking in tests

### Scrollbar Differences
**Cause**: Different scrollbar styles per OS
**Fix**: Hide scrollbars in test CSS or use element screenshots
