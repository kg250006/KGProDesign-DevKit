---
name: ui-visual-testing
description: Expert UI testing skill for visual validation, DOM inspection, console monitoring, browser automation, and screenshot-iterate design QA. Prefers Chrome DevTools MCP / claude-in-chrome when connected; falls back to Puppeteer for headless CI. Use when validating frontend applications, running visual QA on changed pages, checking console errors, or verifying a PRP's verify="visual" criteria.
---

<essential_principles>
## Tool Selection (check FIRST, before any workflow)

Two execution paths — pick by what's available in the session:

**Path A — Chrome DevTools MCP / claude-in-chrome (PREFERRED).**
If `mcp__chrome-devtools__*` or `mcp__claude-in-chrome__*` tools are available (or loadable via ToolSearch), use them. No installation, no scripts, and richer signals:

| Need | Chrome DevTools MCP tool |
|------|--------------------------|
| DOM inspection | `take_snapshot` (a11y tree with element UIDs) |
| Console errors | `list_console_messages` / `get_console_message` |
| Network failures | `list_network_requests` / `get_network_request` |
| Screenshots | `take_screenshot` (viewport, full-page, or element) |
| Interactions | `click`, `fill`, `fill_form`, `hover`, `press_key` |
| Performance | `performance_start_trace` / `performance_analyze_insight` |
| Audits | `lighthouse_audit` (perf, a11y, SEO in one call) |
| Responsive checks | `resize_page` / `emulate` |

`claude-in-chrome` additionally drives the user's real Chrome session (logged-in state, extensions) — prefer it when the test needs authenticated state; prefer `chrome-devtools` for clean-profile testing and performance traces.

**Path B — Puppeteer (FALLBACK).**
Use only when no browser MCP is connected (headless CI, scripted regression suites). All `references/` and `scripts/` files support this path.

## Testing Hierarchy (least to most resource-intensive)

**ALWAYS start at level 1 and escalate only when needed.**

1. **DOM Inspection** - Element existence, attributes, structure
   - Path A: `take_snapshot`; Path B: `page.$()`, `page.$eval()`, `waitForSelector()`
2. **Console Monitoring** - Errors, warnings, network failures
   - Path A: `list_console_messages`; Path B: `page.on('console')`, `page.on('pageerror')`
3. **Screenshots** - Visual state capture
   - Path A: `take_screenshot`; Path B: `page.screenshot()`
4. **Performance/Audit** - Traces, Lighthouse (Path A only), video recording (Path B)

## Screenshot-Iterate Design QA Loop

The standard gate for design-forward work (websites, landing pages, dashboards). Run on EVERY changed page/view before calling UI work done:

1. **Render** the page at desktop (1440px) and mobile (390px) widths.
2. **Screenshot** both.
3. **Critique** against the project's style guide / design tokens (`kgprodesign-branding` for KGP properties): spacing rhythm, type hierarchy, color usage, alignment, contrast (WCAG AA), hover/focus states, empty states.
4. **Refine** — fix the top issues found.
5. **Re-screenshot** to confirm. One full iteration minimum; two for hero/landing surfaces.

This loop satisfies `verify="visual"` criteria in PRPs executed by `/KGP:prp-execute`.

## Browser Automation Principles

- **Always close browsers** (Path B) in finally blocks to prevent memory leaks
- **Wait for network idle** before assertions to avoid race conditions
- **Use semantic selectors** (data-testid > aria > semantic > text > class)
- **Set explicit timeouts** to fail fast on broken pages
- **Capture evidence** for failures (screenshots, console logs)
- **Never trigger browser modal dialogs** (alert/confirm) via MCP paths — they block the extension

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
4. **Design QA loop** - Screenshot-critique-refine against style guide
5. **Debug UI issue** - Investigate a specific problem
6. **Full UI audit** - Comprehensive check (console, DOM, accessibility, performance)

**Describe the URL and what you're testing, or select a number.**
</intake>

<routing>
| Response | Intent | Workflow |
|----------|--------|----------|
| 1, "quick", "health", "console errors", "smoke" | Fast validation | workflows/quick-validation.md |
| 2, "interaction", "login", "click", "form", "user flow", "checkout", "navigate" | Test interactions | workflows/interaction-testing.md |
| 3, "visual", "screenshot", "regression", "compare", "baseline", "diff" | Visual comparison | workflows/visual-regression.md |
| 4, "design QA", "style guide", "critique", "polish", "verify visual" | Design QA loop | Run the Screenshot-Iterate loop from essential_principles (no separate workflow file) |
| 5, "debug", "investigate", "broken", "issue", "bug", "why", "diagnose" | Debug mode | workflows/debug-ui-issue.md |
| 6, "full", "audit", "comprehensive", "everything", "complete" | Complete audit | workflows/full-audit.md |

**Workflows are written Puppeteer-first; when on Path A, translate each step to the equivalent MCP tool from the table in essential_principles. After selecting a workflow, read its required references before proceeding.**
</routing>

<quick_reference>
## Path A: Chrome DevTools MCP Quick Patterns

```
# Load tools (one ToolSearch call):
ToolSearch "select:mcp__chrome-devtools__new_page,mcp__chrome-devtools__navigate_page,mcp__chrome-devtools__take_snapshot,mcp__chrome-devtools__take_screenshot,mcp__chrome-devtools__list_console_messages"

# Health check: navigate → list_console_messages (filter errors) → take_snapshot (verify key elements)
# Visual QA: navigate → resize_page 1440w → take_screenshot → resize_page 390w → take_screenshot → critique
# Audit: lighthouse_audit for perf/a11y/SEO scores in one call
```

## Path B: Common Puppeteer Patterns

**Launch browser:**
```typescript
const browser = await puppeteer.launch({ headless: true });
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
## Reference Files (Path B / Puppeteer fallback)

All in `references/`:

| File | Purpose |
|------|---------|
| console-error-patterns.md | 50+ error patterns with regex, severity, fixes (applies to both paths) |
| dom-inspection-patterns.md | Selector strategies, waiting, form validation |
| puppeteer-setup.md | Installation, TypeScript config, browser options |
| screenshot-strategies.md | When/how to capture, storage, naming (applies to both paths) |
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
## Scripts (Path B only)

All in `scripts/`:

| Script | Purpose |
|--------|---------|
| puppeteer-setup.sh | Install Puppeteer and dependencies |
| browser-launch.ts | Typed browser launch with console capture |
</scripts_index>

<success_criteria>
A successful UI test:
- Used Path A (browser MCP) when available; fell back to Puppeteer only when not
- Runs at appropriate testing level (DOM first, escalate if needed)
- Captures and classifies all console output
- Provides clear pass/fail with evidence
- Design-forward changes passed at least one screenshot-critique-refine iteration
- Cleans up browser resources (Path B)
- Generates actionable report with fix recommendations
</success_criteria>
