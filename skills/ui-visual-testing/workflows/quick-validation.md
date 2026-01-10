# Quick Validation Workflow

<objective>
Fast 30-second UI health check. Validates page loads, captures console errors, verifies critical elements exist. Use this for smoke tests and quick sanity checks before deeper testing.
</objective>

<required_reading>
Before starting:
- references/puppeteer-setup.md (ensure Puppeteer installed)
- references/console-error-patterns.md (for error classification)
</required_reading>

<inputs>
## Required Information

Before proceeding, confirm:
1. **Target URL** - The page to validate
2. **Critical elements** - Selectors that must exist (optional, defaults provided)
3. **Timeout** - Max wait time in ms (default: 30000)
</inputs>

<process>
## Step 1: Launch Browser and Set Up Capture

```typescript
import puppeteer, { Browser, Page, ConsoleMessage } from 'puppeteer';

interface ConsoleEntry {
  type: string;
  text: string;
  timestamp: Date;
  location?: string;
}

interface QuickValidationResult {
  url: string;
  success: boolean;
  loadTimeMs: number;
  consoleErrors: ConsoleEntry[];
  consoleWarnings: ConsoleEntry[];
  criticalElements: { selector: string; found: boolean }[];
  screenshot?: string;
}

async function quickValidation(url: string, options: {
  criticalSelectors?: string[];
  timeout?: number;
} = {}): Promise<QuickValidationResult> {
  const criticalSelectors = options.criticalSelectors ?? [
    'body',
    'main, [role="main"], #main, .main',
    'h1',
  ];
  const timeout = options.timeout ?? 30000;

  let browser: Browser | null = null;
  const consoleLogs: ConsoleEntry[] = [];
  const startTime = Date.now();

  try {
    browser = await puppeteer.launch({ headless: 'new' });
    const page = await browser.newPage();
    await page.setViewport({ width: 1280, height: 720 });

    // Capture console messages
    page.on('console', (msg: ConsoleMessage) => {
      consoleLogs.push({
        type: msg.type(),
        text: msg.text(),
        timestamp: new Date(),
        location: msg.location()?.url,
      });
    });

    // Capture page errors
    page.on('pageerror', (error: Error) => {
      consoleLogs.push({
        type: 'error',
        text: error.message,
        timestamp: new Date(),
      });
    });

    // Navigate to page
    await page.goto(url, {
      waitUntil: 'networkidle0',
      timeout,
    });

    const loadTimeMs = Date.now() - startTime;

    // Check critical elements
    const elementResults = await Promise.all(
      criticalSelectors.map(async (selector) => ({
        selector,
        found: (await page.$(selector)) !== null,
      }))
    );

    // Filter console by type
    const consoleErrors = consoleLogs.filter(
      (log) => log.type === 'error'
    );
    const consoleWarnings = consoleLogs.filter(
      (log) => log.type === 'warning'
    );

    // Determine success
    const allElementsFound = elementResults.every((r) => r.found);
    const noErrors = consoleErrors.length === 0;
    const success = allElementsFound && noErrors;

    // Take screenshot on failure
    let screenshot: string | undefined;
    if (!success) {
      const screenshotPath = `quick-validation-${Date.now()}.png`;
      await page.screenshot({ path: screenshotPath, fullPage: true });
      screenshot = screenshotPath;
    }

    return {
      url,
      success,
      loadTimeMs,
      consoleErrors,
      consoleWarnings,
      criticalElements: elementResults,
      screenshot,
    };
  } finally {
    if (browser) {
      await browser.close();
    }
  }
}
```

## Step 2: Analyze Console Output

Classify console errors by severity:

| Type | Classification | Action |
|------|----------------|--------|
| JavaScript errors | CRITICAL | Fail test, investigate immediately |
| React/Vue errors | CRITICAL | Fail test, component issue |
| 5xx API errors | CRITICAL | Fail test, backend issue |
| CORS errors | CRITICAL | Fail test, configuration issue |
| 4xx API errors | ERROR | Log for review |
| Deprecation warnings | WARNING | Log, non-blocking |
| CSP warnings | WARNING | Log, security review |
| Debug logs | INFO | Ignore |

## Step 3: Verify Critical Elements

Default critical elements to check:
- `body` - Page rendered at all
- `main, [role="main"]` - Main content area exists
- `h1` - Primary heading exists

Additional selectors based on app type:
- **SPA**: `#root, #app, [data-reactroot]`
- **E-commerce**: `nav, .cart, .product`
- **Dashboard**: `.sidebar, .header, .main-content`

## Step 4: Generate Report

Use the test-report.md template format:

```markdown
# Quick Validation Report

**URL**: {url}
**Status**: {PASS|FAIL}
**Load Time**: {loadTimeMs}ms
**Timestamp**: {ISO timestamp}

## Console Analysis
- Errors: {count}
- Warnings: {count}

### Errors Found
{For each error: type, message, location}

## Critical Elements
{For each selector: found/not found}

## Screenshot
{Path if captured, or "Not captured (test passed)"}

## Recommendations
{Based on findings}
```
</process>

<execution_steps>
## Execute Quick Validation

1. **Confirm target URL** with user
2. **Run validation**:
   ```bash
   # If TypeScript file exists
   npx ts-node quick-validation.ts https://target-url.com

   # Or run inline
   node -e "
   const puppeteer = require('puppeteer');
   (async () => {
     const browser = await puppeteer.launch({headless: 'new'});
     const page = await browser.newPage();
     const logs = [];
     page.on('console', m => logs.push({type: m.type(), text: m.text()}));
     page.on('pageerror', e => logs.push({type: 'error', text: e.message}));

     try {
       await page.goto('$URL', {waitUntil: 'networkidle0', timeout: 30000});
       const errors = logs.filter(l => l.type === 'error');
       console.log('Errors:', errors.length);
       errors.forEach(e => console.log('  -', e.text));
     } finally {
       await browser.close();
     }
   })();
   "
   ```
3. **Analyze results** using console-error-patterns.md
4. **Report findings** using test-report.md template
</execution_steps>

<success_criteria>
Quick validation passes when:
- [ ] Page loads within timeout (default 30s)
- [ ] Zero unwhitelisted console errors
- [ ] All critical elements found
- [ ] Load time reasonable (< 5s for simple pages)

If any criteria fail:
- [ ] Screenshot captured
- [ ] Console errors logged with classification
- [ ] Recommendations provided
</success_criteria>

<common_failures>
| Failure | Likely Cause | Next Step |
|---------|--------------|-----------|
| Timeout | Slow server, blocked resources | Check network tab, increase timeout |
| Console errors | JS bug, API failure | Analyze with console-error-patterns.md |
| Missing elements | Wrong selector, async render | Use waitForSelector, check selectors |
| Blank page | JS crash, hydration failure | Check console for fatal errors |
</common_failures>
