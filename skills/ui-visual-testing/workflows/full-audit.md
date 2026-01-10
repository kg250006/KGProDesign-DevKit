# Full UI Audit Workflow

<objective>
Comprehensive UI validation including console monitoring, DOM inspection, accessibility checks, and performance metrics. Use for thorough QA before releases, after major changes, or periodic health assessments.
</objective>

<required_reading>
Before starting:
- references/puppeteer-setup.md (browser setup)
- references/console-error-patterns.md (error classification)
- references/dom-inspection-patterns.md (selector strategies)
- references/screenshot-strategies.md (capture best practices)
</required_reading>

<inputs>
## Required Information

Before proceeding, confirm:
1. **Target URL(s)** - Pages to audit (can be multiple)
2. **User flows** - Key interactions to test (optional)
3. **Accessibility level** - WCAG level (A, AA, AAA)
4. **Performance targets** - LCP, FCP thresholds (optional)
</inputs>

<process>
## Step 1: Initial Page Load Analysis

```typescript
import puppeteer, { Browser, Page } from 'puppeteer';

interface AuditResult {
  url: string;
  timestamp: Date;
  loadMetrics: LoadMetrics;
  consoleAnalysis: ConsoleAnalysis;
  domAnalysis: DOMAnalysis;
  accessibilityIssues: AccessibilityIssue[];
  performanceMetrics: PerformanceMetrics;
  screenshots: string[];
  overallScore: number;
  status: 'PASS' | 'WARN' | 'FAIL';
}

interface LoadMetrics {
  loadTimeMs: number;
  domContentLoaded: number;
  firstPaint: number;
  firstContentfulPaint: number;
}

async function auditPage(url: string): Promise<AuditResult> {
  let browser: Browser | null = null;

  try {
    browser = await puppeteer.launch({ headless: 'new' });
    const page = await browser.newPage();
    await page.setViewport({ width: 1280, height: 720 });

    // Enable performance metrics
    const client = await page.createCDPSession();
    await client.send('Performance.enable');

    // Capture console
    const consoleLogs: any[] = [];
    page.on('console', msg => {
      consoleLogs.push({ type: msg.type(), text: msg.text() });
    });
    page.on('pageerror', err => {
      consoleLogs.push({ type: 'error', text: err.message });
    });

    // Navigate and measure
    const startTime = Date.now();
    await page.goto(url, { waitUntil: 'networkidle0', timeout: 60000 });
    const loadTimeMs = Date.now() - startTime;

    // Get performance timing
    const performanceTiming = await page.evaluate(() => {
      const timing = performance.timing;
      const paint = performance.getEntriesByType('paint');
      return {
        domContentLoaded: timing.domContentLoadedEventEnd - timing.navigationStart,
        loadComplete: timing.loadEventEnd - timing.navigationStart,
        firstPaint: paint.find(p => p.name === 'first-paint')?.startTime ?? 0,
        firstContentfulPaint: paint.find(p => p.name === 'first-contentful-paint')?.startTime ?? 0,
      };
    });

    // Run all audit components
    const consoleAnalysis = analyzeConsoleLogs(consoleLogs);
    const domAnalysis = await analyzeDOMStructure(page);
    const accessibilityIssues = await checkAccessibility(page);
    const performanceMetrics = await measurePerformance(page);

    // Capture evidence
    const screenshots = await captureAuditScreenshots(page, url);

    // Calculate overall score
    const score = calculateAuditScore(
      consoleAnalysis,
      domAnalysis,
      accessibilityIssues,
      performanceMetrics
    );

    return {
      url,
      timestamp: new Date(),
      loadMetrics: {
        loadTimeMs,
        domContentLoaded: performanceTiming.domContentLoaded,
        firstPaint: performanceTiming.firstPaint,
        firstContentfulPaint: performanceTiming.firstContentfulPaint,
      },
      consoleAnalysis,
      domAnalysis,
      accessibilityIssues,
      performanceMetrics,
      screenshots,
      overallScore: score,
      status: score >= 80 ? 'PASS' : score >= 60 ? 'WARN' : 'FAIL',
    };
  } finally {
    if (browser) await browser.close();
  }
}
```

## Step 2: Console Error Analysis

```typescript
interface ConsoleAnalysis {
  totalLogs: number;
  errors: number;
  warnings: number;
  criticalErrors: string[];
  errorsByCategory: Record<string, number>;
}

function analyzeConsoleLogs(logs: any[]): ConsoleAnalysis {
  const errors = logs.filter(l => l.type === 'error');
  const warnings = logs.filter(l => l.type === 'warning');

  // Categorize errors
  const categories: Record<string, number> = {
    javascript: 0,
    network: 0,
    security: 0,
    react: 0,
    cors: 0,
    other: 0,
  };

  const criticalErrors: string[] = [];

  for (const error of errors) {
    const text = error.text.toLowerCase();

    if (text.includes('typeerror') || text.includes('referenceerror') || text.includes('syntaxerror')) {
      categories.javascript++;
      criticalErrors.push(error.text);
    } else if (text.includes('failed to fetch') || text.includes('net::') || text.includes('404') || text.includes('500')) {
      categories.network++;
      if (text.includes('500') || text.includes('failed to fetch')) {
        criticalErrors.push(error.text);
      }
    } else if (text.includes('csp') || text.includes('mixed content') || text.includes('insecure')) {
      categories.security++;
      criticalErrors.push(error.text);
    } else if (text.includes('react') || text.includes('hydration')) {
      categories.react++;
      criticalErrors.push(error.text);
    } else if (text.includes('cors') || text.includes('access-control')) {
      categories.cors++;
      criticalErrors.push(error.text);
    } else {
      categories.other++;
    }
  }

  return {
    totalLogs: logs.length,
    errors: errors.length,
    warnings: warnings.length,
    criticalErrors: criticalErrors.slice(0, 10), // Top 10
    errorsByCategory: categories,
  };
}
```

## Step 3: DOM Structure Analysis

```typescript
interface DOMAnalysis {
  hasSemanticStructure: boolean;
  headingHierarchy: { level: number; text: string }[];
  missingAltTags: number;
  emptyLinks: number;
  formLabels: { total: number; missing: number };
  criticalElements: { selector: string; found: boolean }[];
}

async function analyzeDOMStructure(page: Page): Promise<DOMAnalysis> {
  return await page.evaluate(() => {
    // Check semantic structure
    const hasMain = !!document.querySelector('main');
    const hasNav = !!document.querySelector('nav');
    const hasHeader = !!document.querySelector('header');
    const hasFooter = !!document.querySelector('footer');
    const hasSemanticStructure = hasMain && (hasNav || hasHeader);

    // Check heading hierarchy
    const headings = Array.from(document.querySelectorAll('h1, h2, h3, h4, h5, h6'));
    const headingHierarchy = headings.map(h => ({
      level: parseInt(h.tagName[1]),
      text: h.textContent?.substring(0, 50) ?? '',
    }));

    // Check images for alt tags
    const images = document.querySelectorAll('img');
    const missingAltTags = Array.from(images).filter(img => !img.alt).length;

    // Check for empty links
    const links = document.querySelectorAll('a');
    const emptyLinks = Array.from(links).filter(a =>
      !a.textContent?.trim() && !a.querySelector('img') && !a.getAttribute('aria-label')
    ).length;

    // Check form labels
    const inputs = document.querySelectorAll('input:not([type="hidden"]), select, textarea');
    const inputsWithoutLabels = Array.from(inputs).filter(input => {
      const id = input.id;
      const ariaLabel = input.getAttribute('aria-label');
      const ariaLabelledBy = input.getAttribute('aria-labelledby');
      const label = id ? document.querySelector(`label[for="${id}"]`) : null;
      const parentLabel = input.closest('label');
      return !label && !parentLabel && !ariaLabel && !ariaLabelledBy;
    });

    // Critical elements check
    const criticalSelectors = ['body', 'main', 'h1', 'nav'];
    const criticalElements = criticalSelectors.map(sel => ({
      selector: sel,
      found: !!document.querySelector(sel),
    }));

    return {
      hasSemanticStructure,
      headingHierarchy,
      missingAltTags,
      emptyLinks,
      formLabels: {
        total: inputs.length,
        missing: inputsWithoutLabels.length,
      },
      criticalElements,
    };
  });
}
```

## Step 4: Accessibility Quick Check

```typescript
interface AccessibilityIssue {
  type: string;
  severity: 'critical' | 'serious' | 'moderate' | 'minor';
  element?: string;
  description: string;
}

async function checkAccessibility(page: Page): Promise<AccessibilityIssue[]> {
  const issues: AccessibilityIssue[] = [];

  const a11yResults = await page.evaluate(() => {
    const results: any[] = [];

    // Check for missing alt text
    document.querySelectorAll('img:not([alt])').forEach(img => {
      results.push({
        type: 'missing-alt',
        severity: 'critical',
        element: img.outerHTML.substring(0, 100),
        description: 'Image missing alt attribute',
      });
    });

    // Check for empty alt on decorative images (should use alt="")
    document.querySelectorAll('img[alt=""]').forEach(img => {
      const role = img.getAttribute('role');
      if (role !== 'presentation' && role !== 'none') {
        results.push({
          type: 'empty-alt-no-role',
          severity: 'minor',
          element: img.outerHTML.substring(0, 100),
          description: 'Decorative image should have role="presentation"',
        });
      }
    });

    // Check for form inputs without labels
    document.querySelectorAll('input:not([type="hidden"]):not([aria-label]):not([aria-labelledby])').forEach(input => {
      const id = input.id;
      const label = id ? document.querySelector(`label[for="${id}"]`) : null;
      const parentLabel = input.closest('label');
      if (!label && !parentLabel) {
        results.push({
          type: 'missing-label',
          severity: 'serious',
          element: input.outerHTML.substring(0, 100),
          description: 'Form input missing associated label',
        });
      }
    });

    // Check color contrast (simplified - would need axe-core for full check)
    // Check for focus indicators
    document.querySelectorAll('a, button, input, select, textarea').forEach(el => {
      const style = window.getComputedStyle(el);
      const outlineWidth = parseInt(style.outlineWidth);
      const boxShadow = style.boxShadow;
      // This is a simplified check
    });

    // Check for skip link
    const skipLink = document.querySelector('a[href="#main"], a[href="#content"], .skip-link');
    if (!skipLink) {
      results.push({
        type: 'missing-skip-link',
        severity: 'moderate',
        description: 'No skip navigation link found',
      });
    }

    // Check heading hierarchy
    const headings = Array.from(document.querySelectorAll('h1, h2, h3, h4, h5, h6'));
    let prevLevel = 0;
    headings.forEach(h => {
      const level = parseInt(h.tagName[1]);
      if (level - prevLevel > 1) {
        results.push({
          type: 'heading-skip',
          severity: 'moderate',
          element: h.outerHTML.substring(0, 100),
          description: `Heading level skipped from h${prevLevel} to h${level}`,
        });
      }
      prevLevel = level;
    });

    // Check for multiple h1
    const h1Count = document.querySelectorAll('h1').length;
    if (h1Count > 1) {
      results.push({
        type: 'multiple-h1',
        severity: 'moderate',
        description: `Multiple h1 elements found (${h1Count})`,
      });
    } else if (h1Count === 0) {
      results.push({
        type: 'missing-h1',
        severity: 'serious',
        description: 'No h1 element found',
      });
    }

    return results;
  });

  return a11yResults;
}
```

## Step 5: Performance Metrics

```typescript
interface PerformanceMetrics {
  lcp: number;       // Largest Contentful Paint
  fcp: number;       // First Contentful Paint
  cls: number;       // Cumulative Layout Shift
  tti: number;       // Time to Interactive (approximation)
  totalBlockingTime: number;
  resourceCount: { total: number; byType: Record<string, number> };
  totalBytes: number;
}

async function measurePerformance(page: Page): Promise<PerformanceMetrics> {
  // Get Web Vitals
  const metrics = await page.evaluate(() => {
    return new Promise<any>(resolve => {
      const entries: any = {};

      // LCP
      new PerformanceObserver(list => {
        const lcpEntries = list.getEntries();
        entries.lcp = lcpEntries[lcpEntries.length - 1]?.startTime ?? 0;
      }).observe({ entryTypes: ['largest-contentful-paint'] });

      // FCP from paint timing
      const paintEntries = performance.getEntriesByType('paint');
      entries.fcp = paintEntries.find(e => e.name === 'first-contentful-paint')?.startTime ?? 0;

      // CLS
      let clsValue = 0;
      new PerformanceObserver(list => {
        for (const entry of list.getEntries() as any[]) {
          if (!entry.hadRecentInput) {
            clsValue += entry.value;
          }
        }
        entries.cls = clsValue;
      }).observe({ entryTypes: ['layout-shift'] });

      // Resource timing
      const resources = performance.getEntriesByType('resource') as PerformanceResourceTiming[];
      const byType: Record<string, number> = {};
      let totalBytes = 0;

      resources.forEach(r => {
        const type = r.initiatorType || 'other';
        byType[type] = (byType[type] || 0) + 1;
        totalBytes += r.transferSize || 0;
      });

      entries.resourceCount = { total: resources.length, byType };
      entries.totalBytes = totalBytes;

      // TTI approximation (last long task + 5s quiet)
      entries.tti = performance.timing.domInteractive - performance.timing.navigationStart;

      // Give time for metrics to collect
      setTimeout(() => resolve(entries), 2000);
    });
  });

  return {
    lcp: metrics.lcp || 0,
    fcp: metrics.fcp || 0,
    cls: metrics.cls || 0,
    tti: metrics.tti || 0,
    totalBlockingTime: 0, // Would need TBT observer
    resourceCount: metrics.resourceCount,
    totalBytes: metrics.totalBytes,
  };
}
```

## Step 6: Calculate Audit Score

```typescript
function calculateAuditScore(
  console: ConsoleAnalysis,
  dom: DOMAnalysis,
  a11y: AccessibilityIssue[],
  perf: PerformanceMetrics
): number {
  let score = 100;

  // Console errors (-5 each, max -30)
  score -= Math.min(console.criticalErrors.length * 5, 30);

  // DOM issues
  if (!dom.hasSemanticStructure) score -= 10;
  score -= Math.min(dom.missingAltTags * 2, 10);
  score -= Math.min(dom.emptyLinks * 2, 10);

  // Accessibility (-severity weight)
  const a11yPenalty = a11y.reduce((sum, issue) => {
    const weights = { critical: 10, serious: 5, moderate: 3, minor: 1 };
    return sum + (weights[issue.severity] || 0);
  }, 0);
  score -= Math.min(a11yPenalty, 30);

  // Performance
  if (perf.lcp > 2500) score -= 10;
  if (perf.fcp > 1800) score -= 5;
  if (perf.cls > 0.1) score -= 10;

  return Math.max(0, Math.min(100, score));
}
```
</process>

<execution_steps>
## Execute Full Audit

1. **Identify pages** to audit
2. **Run audit** for each page:
   ```bash
   npx ts-node full-audit.ts --url https://example.com --output ./audit-results
   ```
3. **Review results** across all categories
4. **Generate report** using comprehensive template
5. **Prioritize fixes** based on severity and impact
</execution_steps>

<success_criteria>
Audit passes when:
- [ ] Overall score >= 80
- [ ] Zero critical console errors
- [ ] All critical DOM elements present
- [ ] No critical accessibility issues
- [ ] LCP < 2.5s, FCP < 1.8s, CLS < 0.1

Report generated with:
- [ ] All metrics captured
- [ ] Screenshots at key viewports
- [ ] Prioritized issue list
- [ ] Remediation recommendations
</success_criteria>

<report_format>
## Full Audit Report Structure

```markdown
# UI Audit Report: {URL}

**Date**: {timestamp}
**Overall Score**: {score}/100 - {PASS|WARN|FAIL}

## Executive Summary
{1-2 sentence overview}

## Metrics Overview
| Metric | Value | Target | Status |
|--------|-------|--------|--------|
| Load Time | {ms}ms | <3000ms | {OK|WARN|FAIL} |
| LCP | {ms}ms | <2500ms | {OK|WARN|FAIL} |
| FCP | {ms}ms | <1800ms | {OK|WARN|FAIL} |
| CLS | {score} | <0.1 | {OK|WARN|FAIL} |

## Console Analysis
- Errors: {count} ({critical} critical)
- Warnings: {count}

## DOM Analysis
- Semantic Structure: {OK|Missing components}
- Accessibility Score: {score}

## Top Issues (by priority)
1. {issue} - {severity} - {recommendation}

## Screenshots
{desktop, tablet, mobile captures}

## Recommendations
{prioritized action items}
```
</report_format>
