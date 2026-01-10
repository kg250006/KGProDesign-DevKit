# Interaction Testing Workflow

<objective>
Test user interactions: clicks, form submissions, navigation flows. Validates that interactive elements work correctly and state updates as expected. Use for login flows, checkout processes, form submissions, and navigation testing.
</objective>

<required_reading>
Before starting:
- references/puppeteer-setup.md (browser setup)
- references/dom-inspection-patterns.md (waiting strategies, selectors)
- references/console-error-patterns.md (for error classification)
</required_reading>

<inputs>
## Required Information

Before proceeding, confirm:
1. **Base URL** - Starting point for the interaction
2. **User flow** - Steps to perform (click X, type Y, verify Z)
3. **Test data** - Usernames, passwords, form values (if applicable)
4. **Expected outcomes** - What should happen after each step
</inputs>

<process>
## Step 1: Define Interaction Steps

Create a test plan as array of steps:

```typescript
interface InteractionStep {
  action: 'navigate' | 'click' | 'type' | 'select' | 'wait' | 'verify' | 'screenshot';
  selector?: string;
  value?: string;
  timeout?: number;
  description: string;
}

// Example: Login flow
const loginFlow: InteractionStep[] = [
  { action: 'navigate', value: 'https://app.example.com/login', description: 'Go to login page' },
  { action: 'wait', selector: 'input[name="email"]', description: 'Wait for email field' },
  { action: 'type', selector: 'input[name="email"]', value: 'test@example.com', description: 'Enter email' },
  { action: 'type', selector: 'input[name="password"]', value: 'testpass123', description: 'Enter password' },
  { action: 'click', selector: 'button[type="submit"]', description: 'Click submit' },
  { action: 'wait', selector: '.dashboard, [data-testid="dashboard"]', timeout: 10000, description: 'Wait for dashboard' },
  { action: 'verify', selector: '.user-name', value: 'Test User', description: 'Verify user name displayed' },
];
```

## Step 2: Execute Interactions

```typescript
import puppeteer, { Browser, Page } from 'puppeteer';

interface StepResult {
  step: InteractionStep;
  success: boolean;
  error?: string;
  screenshot?: string;
  duration: number;
}

async function executeInteraction(
  page: Page,
  step: InteractionStep
): Promise<StepResult> {
  const startTime = Date.now();

  try {
    switch (step.action) {
      case 'navigate':
        await page.goto(step.value!, {
          waitUntil: 'networkidle0',
          timeout: step.timeout ?? 30000,
        });
        break;

      case 'click':
        await page.waitForSelector(step.selector!, {
          visible: true,
          timeout: step.timeout ?? 5000,
        });
        await page.click(step.selector!);
        break;

      case 'type':
        await page.waitForSelector(step.selector!, {
          visible: true,
          timeout: step.timeout ?? 5000,
        });
        // Clear existing value
        await page.$eval(step.selector!, (el: HTMLInputElement) => el.value = '');
        await page.type(step.selector!, step.value!);
        break;

      case 'select':
        await page.waitForSelector(step.selector!, {
          visible: true,
          timeout: step.timeout ?? 5000,
        });
        await page.select(step.selector!, step.value!);
        break;

      case 'wait':
        await page.waitForSelector(step.selector!, {
          visible: true,
          timeout: step.timeout ?? 10000,
        });
        break;

      case 'verify':
        await page.waitForSelector(step.selector!, {
          visible: true,
          timeout: step.timeout ?? 5000,
        });
        if (step.value) {
          const text = await page.$eval(step.selector!, el => el.textContent);
          if (!text?.includes(step.value)) {
            throw new Error(`Expected "${step.value}" but got "${text}"`);
          }
        }
        break;

      case 'screenshot':
        const path = step.value ?? `step-${Date.now()}.png`;
        await page.screenshot({ path, fullPage: false });
        return {
          step,
          success: true,
          screenshot: path,
          duration: Date.now() - startTime,
        };
    }

    return {
      step,
      success: true,
      duration: Date.now() - startTime,
    };
  } catch (error) {
    // Take screenshot on failure
    const screenshotPath = `failure-${Date.now()}.png`;
    await page.screenshot({ path: screenshotPath, fullPage: true });

    return {
      step,
      success: false,
      error: error instanceof Error ? error.message : String(error),
      screenshot: screenshotPath,
      duration: Date.now() - startTime,
    };
  }
}

async function runInteractionTest(
  steps: InteractionStep[]
): Promise<{ success: boolean; results: StepResult[]; consoleLogs: any[] }> {
  let browser: Browser | null = null;
  const results: StepResult[] = [];
  const consoleLogs: any[] = [];

  try {
    browser = await puppeteer.launch({ headless: 'new' });
    const page = await browser.newPage();
    await page.setViewport({ width: 1280, height: 720 });

    // Capture console
    page.on('console', msg => {
      consoleLogs.push({ type: msg.type(), text: msg.text() });
    });
    page.on('pageerror', err => {
      consoleLogs.push({ type: 'error', text: err.message });
    });

    for (const step of steps) {
      console.log(`Executing: ${step.description}`);
      const result = await executeInteraction(page, step);
      results.push(result);

      if (!result.success) {
        console.error(`FAILED: ${step.description}`);
        console.error(`  Error: ${result.error}`);
        break; // Stop on first failure
      }
    }

    const success = results.every(r => r.success);
    return { success, results, consoleLogs };
  } finally {
    if (browser) {
      await browser.close();
    }
  }
}
```

## Step 3: Handle Common Scenarios

### Form Submissions

```typescript
// Clear and type
await page.$eval('input[name="field"]', (el: HTMLInputElement) => el.value = '');
await page.type('input[name="field"]', 'value');

// Check checkbox
await page.click('input[type="checkbox"]:not(:checked)');

// Select dropdown
await page.select('select[name="country"]', 'US');

// File upload
const fileInput = await page.$('input[type="file"]');
await fileInput?.uploadFile('/path/to/file.pdf');
```

### Waiting for State Changes

```typescript
// Wait for navigation after click
await Promise.all([
  page.waitForNavigation({ waitUntil: 'networkidle0' }),
  page.click('a.next-page'),
]);

// Wait for element to disappear (loading spinner)
await page.waitForSelector('.loading-spinner', { hidden: true });

// Wait for specific text
await page.waitForFunction(
  (text: string) => document.body.innerText.includes(text),
  {},
  'Success!'
);

// Wait for network request
await page.waitForResponse(
  response => response.url().includes('/api/submit') && response.status() === 200
);
```

### Handling Modals and Popups

```typescript
// Wait for modal and interact
await page.waitForSelector('.modal', { visible: true });
await page.click('.modal .confirm-button');
await page.waitForSelector('.modal', { hidden: true });

// Handle alert/confirm dialogs
page.on('dialog', async dialog => {
  console.log('Dialog:', dialog.message());
  await dialog.accept(); // or dialog.dismiss()
});
```
</process>

<execution_steps>
## Execute Interaction Test

1. **Define test steps** with user
2. **Create step array** following the InteractionStep format
3. **Run the test**:
   ```bash
   npx ts-node interaction-test.ts
   ```
4. **Analyze results**:
   - Check each step success/failure
   - Review console errors
   - Examine failure screenshots
5. **Report findings** using test-report.md template
</execution_steps>

<success_criteria>
Interaction test passes when:
- [ ] All steps execute successfully
- [ ] Expected outcomes match actual results
- [ ] No console errors during interaction
- [ ] Page state is correct after flow completes

If test fails:
- [ ] Identify failing step
- [ ] Screenshot captured at failure point
- [ ] Console logs analyzed for clues
- [ ] Root cause documented
</success_criteria>

<common_failures>
| Failure | Likely Cause | Solution |
|---------|--------------|----------|
| Element not found | Wrong selector, async render | Use waitForSelector, check selector strategy |
| Click not working | Element covered, not clickable | scrollIntoView, check z-index |
| Type not working | Input not focused, readonly | Click first, check disabled state |
| Verification failed | Async data, wrong text | Add wait, check exact text |
| Navigation timeout | Slow page, infinite redirect | Increase timeout, check network |
</common_failures>

<selector_priority>
## Selector Priority (Best to Worst)

1. **data-testid** - `[data-testid="submit-btn"]` - Most stable
2. **aria-label** - `[aria-label="Submit"]` - Accessibility-friendly
3. **Semantic HTML** - `button[type="submit"]` - Meaningful
4. **ID** - `#submit-button` - Unique but may change
5. **Name** - `input[name="email"]` - Form-specific
6. **Class** - `.submit-btn` - May be shared
7. **XPath** - `//button[contains(text(),'Submit')]` - Last resort
</selector_priority>
