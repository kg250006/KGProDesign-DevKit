# Visual Regression Workflow

<objective>
Compare current UI state against baseline screenshots to detect visual changes. Use for catching unintended style changes, layout shifts, and visual regressions after code changes.
</objective>

<required_reading>
Before starting:
- references/puppeteer-setup.md (browser setup)
- references/screenshot-strategies.md (capture best practices)
</required_reading>

<inputs>
## Required Information

Before proceeding, confirm:
1. **Target URL(s)** - Pages to capture
2. **Baseline location** - Path to baseline screenshots (or "create new baseline")
3. **Viewport sizes** - Screen sizes to test (default: desktop 1280x720)
4. **Threshold** - Acceptable pixel difference percentage (default: 0.1%)
</inputs>

<process>
## Step 1: Capture Current State

```typescript
import puppeteer, { Browser, Page } from 'puppeteer';
import fs from 'fs';
import path from 'path';

interface ScreenshotConfig {
  url: string;
  name: string;
  selector?: string;     // Element to capture (optional, full page by default)
  viewport?: { width: number; height: number };
  waitFor?: string;      // Selector to wait for before capture
  hideSelectors?: string[];  // Elements to hide (ads, animations)
}

async function captureScreenshot(
  page: Page,
  config: ScreenshotConfig,
  outputDir: string
): Promise<string> {
  const viewport = config.viewport ?? { width: 1280, height: 720 };
  await page.setViewport(viewport);

  await page.goto(config.url, { waitUntil: 'networkidle0', timeout: 30000 });

  // Wait for specific element if specified
  if (config.waitFor) {
    await page.waitForSelector(config.waitFor, { visible: true, timeout: 10000 });
  }

  // Hide dynamic elements that might cause false positives
  if (config.hideSelectors?.length) {
    await page.evaluate((selectors: string[]) => {
      selectors.forEach(selector => {
        document.querySelectorAll(selector).forEach(el => {
          (el as HTMLElement).style.visibility = 'hidden';
        });
      });
    }, config.hideSelectors);
  }

  // Small delay for any animations to settle
  await new Promise(resolve => setTimeout(resolve, 500));

  const filename = `${config.name}-${viewport.width}x${viewport.height}.png`;
  const filepath = path.join(outputDir, filename);

  if (config.selector) {
    const element = await page.$(config.selector);
    if (element) {
      await element.screenshot({ path: filepath });
    }
  } else {
    await page.screenshot({ path: filepath, fullPage: true });
  }

  return filepath;
}

async function captureBaselines(
  configs: ScreenshotConfig[],
  baselineDir: string
): Promise<string[]> {
  let browser: Browser | null = null;
  const screenshots: string[] = [];

  try {
    browser = await puppeteer.launch({ headless: 'new' });
    const page = await browser.newPage();

    // Ensure directory exists
    fs.mkdirSync(baselineDir, { recursive: true });

    for (const config of configs) {
      console.log(`Capturing: ${config.name} at ${config.url}`);
      const filepath = await captureScreenshot(page, config, baselineDir);
      screenshots.push(filepath);
      console.log(`  Saved: ${filepath}`);
    }

    return screenshots;
  } finally {
    if (browser) {
      await browser.close();
    }
  }
}
```

## Step 2: Compare Screenshots

```typescript
import { PNG } from 'pngjs';
import pixelmatch from 'pixelmatch';

interface ComparisonResult {
  baseline: string;
  current: string;
  diffPath: string;
  totalPixels: number;
  differentPixels: number;
  percentDifferent: number;
  passed: boolean;
}

function compareScreenshots(
  baselinePath: string,
  currentPath: string,
  diffOutputPath: string,
  threshold: number = 0.1
): ComparisonResult {
  // Read images
  const baseline = PNG.sync.read(fs.readFileSync(baselinePath));
  const current = PNG.sync.read(fs.readFileSync(currentPath));

  // Check dimensions match
  if (baseline.width !== current.width || baseline.height !== current.height) {
    throw new Error(
      `Dimension mismatch: baseline ${baseline.width}x${baseline.height} ` +
      `vs current ${current.width}x${current.height}`
    );
  }

  const { width, height } = baseline;
  const diff = new PNG({ width, height });

  // Compare pixels
  const differentPixels = pixelmatch(
    baseline.data,
    current.data,
    diff.data,
    width,
    height,
    {
      threshold: 0.1,        // Color difference threshold
      includeAA: false,      // Ignore anti-aliasing differences
      alpha: 0.1,            // Alpha channel threshold
      diffColor: [255, 0, 0], // Red for differences
      diffColorAlt: [0, 255, 0], // Green for anti-aliased diffs
    }
  );

  // Save diff image
  fs.writeFileSync(diffOutputPath, PNG.sync.write(diff));

  const totalPixels = width * height;
  const percentDifferent = (differentPixels / totalPixels) * 100;
  const passed = percentDifferent <= threshold;

  return {
    baseline: baselinePath,
    current: currentPath,
    diffPath: diffOutputPath,
    totalPixels,
    differentPixels,
    percentDifferent,
    passed,
  };
}
```

## Step 3: Run Regression Suite

```typescript
interface RegressionResult {
  name: string;
  comparison: ComparisonResult;
}

async function runVisualRegression(
  configs: ScreenshotConfig[],
  baselineDir: string,
  currentDir: string,
  diffDir: string,
  threshold: number = 0.1
): Promise<{ passed: boolean; results: RegressionResult[] }> {
  // Capture current state
  console.log('Capturing current screenshots...');
  const currentScreenshots = await captureBaselines(configs, currentDir);

  // Compare each screenshot
  const results: RegressionResult[] = [];
  fs.mkdirSync(diffDir, { recursive: true });

  for (let i = 0; i < configs.length; i++) {
    const config = configs[i];
    const baselinePath = path.join(
      baselineDir,
      `${config.name}-${config.viewport?.width ?? 1280}x${config.viewport?.height ?? 720}.png`
    );
    const currentPath = currentScreenshots[i];
    const diffPath = path.join(diffDir, `diff-${config.name}.png`);

    if (!fs.existsSync(baselinePath)) {
      console.warn(`No baseline found for ${config.name}, skipping comparison`);
      continue;
    }

    console.log(`Comparing: ${config.name}`);
    const comparison = compareScreenshots(baselinePath, currentPath, diffPath, threshold);
    results.push({ name: config.name, comparison });

    console.log(`  Difference: ${comparison.percentDifferent.toFixed(3)}%`);
    console.log(`  Status: ${comparison.passed ? 'PASS' : 'FAIL'}`);
  }

  const passed = results.every(r => r.comparison.passed);
  return { passed, results };
}
```

## Step 4: Generate Report

Use templates/visual-diff-report.md format:

```markdown
# Visual Regression Report

**Date**: {timestamp}
**Baseline**: {baseline_dir}
**Threshold**: {threshold}%

## Summary
- **Total Comparisons**: {count}
- **Passed**: {passed_count}
- **Failed**: {failed_count}

## Results

### {page_name}
- **Status**: {PASS|FAIL}
- **Difference**: {percent}% ({pixel_count} pixels)
- **Baseline**: {baseline_path}
- **Current**: {current_path}
- **Diff**: {diff_path}

{For failed comparisons, include diff image}

## Recommendations
{Based on findings}
```
</process>

<execution_steps>
## Execute Visual Regression

1. **First run (create baseline)**:
   ```bash
   # Capture baseline screenshots
   node capture-baselines.js --output ./baselines
   ```

2. **Subsequent runs (compare)**:
   ```bash
   # Compare against baselines
   node visual-regression.js \
     --baseline ./baselines \
     --current ./current \
     --diff ./diffs \
     --threshold 0.1
   ```

3. **Review results**:
   - Check failed comparisons
   - View diff images (red = changed pixels)
   - Decide: intentional change or regression?

4. **Update baselines** (if changes are intentional):
   ```bash
   # Replace old baseline with current
   cp ./current/page-name.png ./baselines/page-name.png
   ```
</execution_steps>

<success_criteria>
Visual regression passes when:
- [ ] All screenshots captured successfully
- [ ] Pixel difference below threshold for all pages
- [ ] No dimension mismatches

If test fails:
- [ ] Diff images generated showing changed regions
- [ ] Percentage difference reported
- [ ] Decision required: update baseline or fix regression
</success_criteria>

<best_practices>
## Screenshot Stability

**Hide dynamic content** to reduce false positives:
```typescript
const hideSelectors = [
  '.timestamp',        // Dates/times
  '.ad-banner',        // Advertisements
  '.loading-spinner',  // Loading indicators
  '.avatar',           // User avatars
  '[data-animated]',   // Animations
  '.carousel',         // Carousels
];
```

**Consistent state**:
- Wait for network idle
- Wait for fonts to load
- Disable animations in CSS
- Use fixed test data

**Viewport consistency**:
- Always set explicit viewport
- Test multiple sizes (mobile, tablet, desktop)
- Account for device pixel ratio
</best_practices>

<dependencies>
## Required Packages

```bash
npm install puppeteer pngjs pixelmatch
npm install --save-dev @types/pngjs @types/pixelmatch
```
</dependencies>
