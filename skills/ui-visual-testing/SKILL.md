---
name: ui-visual-testing
description: Expert UI testing skill for visual validation, DOM inspection, console monitoring, and browser automation using Puppeteer. Routes to optimal testing strategy based on validation needs. Use when QA agent needs to validate frontend applications.
---

<essential_principles>
## Testing Hierarchy (least to most resource-intensive)

**ALWAYS start at level 1 and escalate only when needed.**

1. **DOM Inspection** - Check element existence, attributes, structure
   - When: Element presence, form state, text content, accessibility
   - Cost: Low (no screenshots, no video)
   - Tools: `page.$()`, `page.$$()`, `page.$eval()`, `waitForSelector()`

2. **Console Monitoring** - Capture errors, warnings, network failures
   - When: JavaScript errors, failed requests, CORS issues, React hydration
   - Cost: Low (text capture only)
   - Tools: `page.on('console')`, `page.on('pageerror')`, `page.on('requestfailed')`

3. **Screenshots** - Visual state capture
   - When: Layout verification, visual bugs, regression comparison
   - Cost: Medium (file I/O, storage)
   - Tools: `page.screenshot()`, element-level captures, full-page captures

4. **Video Recording** - Full interaction capture
   - When: Complex timing bugs, animations, race conditions
   - Cost: High (10-50MB/minute, CPU intensive)
   - Tools: puppeteer-screen-recorder, manual frame capture

## Browser Automation Principles

- **Always close browsers** in finally blocks to prevent memory leaks
- **Wait for network idle** before assertions to avoid race conditions
- **Use semantic selectors** (data-testid > aria > semantic > text > class)
- **Set explicit timeouts** to fail fast on broken pages
- **Capture evidence** for failures (screenshots, console logs)

## Error Severity Classification

| Level | Examples | Action |
|-------|----------|--------|
| **CRITICAL** | Page crash, JS fatal error, blank page | Fail test immediately |
| **ERROR** | Uncaught exception, 5xx API, CORS block | Fail test, capture evidence |
| **WARNING** | Deprecation, 404 asset, performance violation | Log for review |
| **INFO** | Debug logs, informational console output | Ignore in tests |
</essential_principles>

<intake>
What would you like to validate?

1. **Quick health check** - Console errors, critical elements (30 seconds)
2. **User interaction test** - Login, checkout, form submission flows
3. **Visual regression** - Compare screenshots against baseline
4. **Debug UI issue** - Investigate a specific problem
5. **Full UI audit** - Comprehensive check (console, DOM, accessibility, performance)

**Describe the URL and what you're testing, or select a number.**
</intake>

<routing>
| Response | Intent | Workflow |
|----------|--------|----------|
| 1, "quick", "health", "console errors", "smoke" | Fast validation | workflows/quick-validation.md |
| 2, "interaction", "login", "click", "form", "user flow", "checkout", "navigate" | Test interactions | workflows/interaction-testing.md |
| 3, "visual", "screenshot", "regression", "compare", "baseline", "diff" | Visual comparison | workflows/visual-regression.md |
| 4, "debug", "investigate", "broken", "issue", "bug", "why", "diagnose" | Debug mode | workflows/debug-ui-issue.md |
| 5, "full", "audit", "comprehensive", "everything", "complete" | Complete audit | workflows/full-audit.md |

**After selecting a workflow, read its required references before proceeding.**
</routing>

<quick_reference>
## Common Puppeteer Patterns

**Launch browser:**
```typescript
const browser = await puppeteer.launch({ headless: 'new' });
const page = await browser.newPage();
```

**Console capture:**
```typescript
const logs = [];
page.on('console', msg => logs.push({ type: msg.type(), text: msg.text() }));
page.on('pageerror', err => logs.push({ type: 'error', text: err.message }));
```

**Navigate with wait:**
```typescript
await page.goto(url, { waitUntil: 'networkidle0', timeout: 30000 });
```

**DOM inspection:**
```typescript
const exists = await page.$('selector') !== null;
const text = await page.$eval('selector', el => el.textContent);
const visible = await page.$eval('selector', el => {
  const style = window.getComputedStyle(el);
  return style.display !== 'none' && style.visibility !== 'hidden';
});
```

**Screenshot:**
```typescript
await page.screenshot({ path: 'screenshot.png', fullPage: true });
```

**Cleanup:**
```typescript
try {
  // test code
} finally {
  await browser.close();
}
```
</quick_reference>

<reference_index>
## Reference Files

All in `references/`:

| File | Purpose |
|------|---------|
| console-error-patterns.md | 50+ error patterns with regex, severity, fixes |
| dom-inspection-patterns.md | Selector strategies, waiting, form validation |
| puppeteer-setup.md | Installation, TypeScript config, browser options |
| screenshot-strategies.md | When/how to capture, storage, naming |
| video-recording-guide.md | Complex timing issues, recorder setup |
</reference_index>

<workflows_index>
## Workflows

All in `workflows/`:

| Workflow | Purpose | Time |
|----------|---------|------|
| quick-validation.md | Fast health check | ~30s |
| interaction-testing.md | User flow validation | ~2-5min |
| visual-regression.md | Screenshot comparison | ~1-2min |
| debug-ui-issue.md | Investigate problems | Variable |
| full-audit.md | Comprehensive check | ~5-10min |
</workflows_index>

<templates_index>
## Templates

All in `templates/`:

| Template | Purpose |
|----------|---------|
| test-report.md | Standard test result output |
| visual-diff-report.md | Screenshot comparison report |
</templates_index>

<scripts_index>
## Scripts

All in `scripts/`:

| Script | Purpose |
|--------|---------|
| puppeteer-setup.sh | Install Puppeteer and dependencies |
| browser-launch.ts | Typed browser launch with console capture |
</scripts_index>

<success_criteria>
A successful UI test:
- Runs at appropriate testing level (DOM first, escalate if needed)
- Captures and classifies all console output
- Provides clear pass/fail with evidence
- Cleans up browser resources
- Generates actionable report with fix recommendations
</success_criteria>
