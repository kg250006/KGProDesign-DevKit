# Debug UI Issue Workflow

<objective>
Investigate and diagnose specific UI problems using progressive testing levels. Start with lightweight DOM/console checks, escalate to screenshots and video only when needed. Use when something specific is broken and needs debugging.
</objective>

<required_reading>
Before starting:
- references/console-error-patterns.md (error classification)
- references/dom-inspection-patterns.md (selector strategies)
- references/screenshot-strategies.md (when to capture)
</required_reading>

<inputs>
## Required Information

Before proceeding, confirm:
1. **Issue description** - What's broken? What should happen vs what happens?
2. **URL** - Where does the issue occur?
3. **Reproduction steps** - How to trigger the issue
4. **Environment** - Browser, device, user state (logged in, specific data)
</inputs>

<process>
## Step 1: Initial Assessment (Level 1 - DOM)

Start with lightweight DOM inspection:

```typescript
import puppeteer, { Browser, Page } from 'puppeteer';

interface DebugContext {
  browser: Browser;
  page: Page;
  consoleLogs: any[];
  networkRequests: any[];
  findings: string[];
}

async function initDebugSession(url: string): Promise<DebugContext> {
  const browser = await puppeteer.launch({ headless: 'new' });
  const page = await browser.newPage();
  await page.setViewport({ width: 1280, height: 720 });

  const consoleLogs: any[] = [];
  const networkRequests: any[] = [];
  const findings: string[] = [];

  // Capture everything
  page.on('console', msg => {
    consoleLogs.push({
      type: msg.type(),
      text: msg.text(),
      location: msg.location()?.url,
    });
  });

  page.on('pageerror', err => {
    consoleLogs.push({ type: 'error', text: err.message, stack: err.stack });
    findings.push(`PAGE ERROR: ${err.message}`);
  });

  page.on('requestfailed', req => {
    networkRequests.push({
      url: req.url(),
      error: req.failure()?.errorText,
      type: 'failed',
    });
    findings.push(`NETWORK FAILED: ${req.url()}`);
  });

  page.on('response', res => {
    if (res.status() >= 400) {
      networkRequests.push({
        url: res.url(),
        status: res.status(),
        type: 'error_response',
      });
      findings.push(`HTTP ${res.status()}: ${res.url()}`);
    }
  });

  await page.goto(url, { waitUntil: 'networkidle0', timeout: 30000 });

  return { browser, page, consoleLogs, networkRequests, findings };
}

// DOM inspection helpers
async function inspectElement(page: Page, selector: string) {
  const element = await page.$(selector);
  if (!element) {
    return { exists: false, selector };
  }

  const info = await page.evaluate((sel: string) => {
    const el = document.querySelector(sel);
    if (!el) return null;

    const style = window.getComputedStyle(el);
    const rect = el.getBoundingClientRect();

    return {
      tagName: el.tagName,
      id: el.id,
      classes: Array.from(el.classList),
      visible: style.display !== 'none' && style.visibility !== 'hidden',
      dimensions: { width: rect.width, height: rect.height },
      position: { top: rect.top, left: rect.left },
      text: el.textContent?.substring(0, 100),
      attributes: Object.fromEntries(
        Array.from(el.attributes).map(a => [a.name, a.value])
      ),
    };
  }, selector);

  return { exists: true, selector, ...info };
}
```

## Step 2: Console Analysis (Level 2)

Analyze captured console output:

```typescript
function analyzeConsoleLogs(logs: any[]): {
  errors: any[];
  warnings: any[];
  criticalIssues: string[];
} {
  const errors = logs.filter(l => l.type === 'error');
  const warnings = logs.filter(l => l.type === 'warning');
  const criticalIssues: string[] = [];

  // Check for common critical patterns
  const patterns = {
    'Uncaught TypeError': 'JavaScript type error - likely accessing undefined property',
    'Uncaught ReferenceError': 'Undefined variable reference',
    'ChunkLoadError': 'Code splitting failure - bundle not loading',
    'Failed to fetch': 'Network request failure',
    'CORS': 'Cross-origin request blocked',
    'hydration': 'React hydration mismatch',
    'React error': 'React component error',
    'Vue warn': 'Vue.js warning',
  };

  for (const error of errors) {
    for (const [pattern, description] of Object.entries(patterns)) {
      if (error.text.includes(pattern)) {
        criticalIssues.push(`${description}: ${error.text.substring(0, 200)}`);
      }
    }
  }

  return { errors, warnings, criticalIssues };
}
```

## Step 3: Reproduce and Capture (Level 3 - Screenshots)

If issue involves visual state:

```typescript
async function reproduceWithCapture(
  ctx: DebugContext,
  steps: Array<{ action: string; selector?: string; value?: string; description: string }>
): Promise<{ screenshots: string[]; error?: string }> {
  const screenshots: string[] = [];

  try {
    for (let i = 0; i < steps.length; i++) {
      const step = steps[i];
      console.log(`Step ${i + 1}: ${step.description}`);

      // Capture before state
      const beforePath = `debug-step${i + 1}-before.png`;
      await ctx.page.screenshot({ path: beforePath });
      screenshots.push(beforePath);

      // Execute action
      switch (step.action) {
        case 'click':
          await ctx.page.click(step.selector!);
          break;
        case 'type':
          await ctx.page.type(step.selector!, step.value!);
          break;
        case 'wait':
          await ctx.page.waitForSelector(step.selector!, { timeout: 5000 });
          break;
        case 'scroll':
          await ctx.page.evaluate((sel: string) => {
            document.querySelector(sel)?.scrollIntoView();
          }, step.selector!);
          break;
      }

      // Small delay for state changes
      await new Promise(r => setTimeout(r, 500));

      // Capture after state
      const afterPath = `debug-step${i + 1}-after.png`;
      await ctx.page.screenshot({ path: afterPath });
      screenshots.push(afterPath);
    }

    return { screenshots };
  } catch (error) {
    const errorPath = `debug-error-${Date.now()}.png`;
    await ctx.page.screenshot({ path: errorPath, fullPage: true });
    screenshots.push(errorPath);

    return {
      screenshots,
      error: error instanceof Error ? error.message : String(error),
    };
  }
}
```

## Step 4: Video Recording (Level 4 - Last Resort)

Only for timing/animation issues:

```typescript
// Using puppeteer-screen-recorder
import { PuppeteerScreenRecorder } from 'puppeteer-screen-recorder';

async function recordInteraction(
  ctx: DebugContext,
  steps: Array<{ action: string; selector?: string; value?: string }>,
  outputPath: string
): Promise<void> {
  const recorder = new PuppeteerScreenRecorder(ctx.page, {
    fps: 30,
    videoFrame: { width: 1280, height: 720 },
  });

  await recorder.start(outputPath);

  try {
    for (const step of steps) {
      // Execute steps with delays for visibility
      await new Promise(r => setTimeout(r, 1000));
      // ... execute step
    }
  } finally {
    await recorder.stop();
  }
}
```

## Step 5: Generate Debug Report

```markdown
# Debug Report: {issue_description}

**URL**: {url}
**Date**: {timestamp}

## Issue Summary
{description of what's wrong}

## Reproduction Steps
{numbered steps to reproduce}

## Findings

### Level 1: DOM Analysis
{element inspection results}

### Level 2: Console Analysis
- **Errors Found**: {count}
- **Critical Issues**:
  {list of critical issues}

### Level 3: Visual Evidence
{screenshots with annotations}

### Level 4: Video (if captured)
{video path}

## Root Cause Analysis
{likely cause based on findings}

## Recommended Fixes
1. {fix 1}
2. {fix 2}

## Additional Context
- Console logs: {path to full log dump}
- Network requests: {path to HAR file}
```
</process>

<execution_steps>
## Debug Flow

1. **Understand the issue** - Get clear description and reproduction steps
2. **Start debug session** - Initialize browser with full capture
3. **Level 1 (DOM)** - Inspect relevant elements
   - Does element exist?
   - Is it visible?
   - Correct attributes?
4. **Level 2 (Console)** - Analyze captured logs
   - Any JavaScript errors?
   - Network failures?
   - Framework warnings?
5. **Level 3 (Screenshots)** - If visual issue, capture state
   - Before/after each action
   - Full page and element-specific
6. **Level 4 (Video)** - Only if timing/animation issue
   - Record full reproduction
7. **Generate report** with findings and recommendations
</execution_steps>

<escalation_criteria>
## When to Escalate Levels

**Stay at Level 1 (DOM) when**:
- Element existence issues
- Attribute/state problems
- Simple selector issues

**Escalate to Level 2 (Console) when**:
- Element exists but doesn't work
- Unexpected behavior
- Need to check for JS errors

**Escalate to Level 3 (Screenshots) when**:
- Visual styling issues
- Layout problems
- Need evidence for report

**Escalate to Level 4 (Video) when**:
- Intermittent issues
- Animation/transition bugs
- Race conditions
- Complex timing problems
</escalation_criteria>

<success_criteria>
Debug session successful when:
- [ ] Issue reproduced and documented
- [ ] Root cause identified (or narrowed down)
- [ ] Evidence collected (logs, screenshots)
- [ ] Recommended fix provided
- [ ] Browser resources cleaned up
</success_criteria>

<common_issues>
| Symptom | Likely Cause | Debug Approach |
|---------|--------------|----------------|
| Element not found | Wrong selector, async | DOM Level 1 |
| Click doesn't work | Covered element, disabled | DOM Level 1 + Console |
| Blank page | JS crash, hydration | Console Level 2 |
| Wrong styling | CSS specificity, load order | Screenshots Level 3 |
| Flaky behavior | Race condition, timing | Video Level 4 |
| Works locally, fails in test | Different state, cache | Full session capture |
</common_issues>
