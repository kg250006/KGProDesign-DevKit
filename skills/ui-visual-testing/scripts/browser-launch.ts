/**
 * UI Visual Testing Skill - Browser Launch Utility
 *
 * Provides typed browser launch with integrated console capture,
 * error capture, and network monitoring.
 */

import puppeteer, {
  Browser,
  Page,
  ConsoleMessage,
  HTTPRequest,
  HTTPResponse,
} from 'puppeteer';

// ============================================================================
// Types
// ============================================================================

export interface LaunchOptions {
  /** Run browser with visible UI (default: 'new' headless) */
  headless?: boolean | 'new';
  /** Slow down operations by N milliseconds */
  slowMo?: number;
  /** Open DevTools on launch */
  devtools?: boolean;
  /** Custom viewport size */
  viewport?: { width: number; height: number };
  /** Additional browser args */
  args?: string[];
  /** Timeout for launch in ms (default: 30000) */
  timeout?: number;
}

export interface ConsoleEntry {
  type: string;
  text: string;
  timestamp: Date;
  location?: string;
  stackTrace?: string;
}

export interface PageError {
  message: string;
  stack?: string;
  timestamp: Date;
}

export interface RequestFailure {
  url: string;
  resourceType: string;
  error: string;
  timestamp: Date;
}

export interface ResponseError {
  url: string;
  status: number;
  statusText: string;
  resourceType: string;
  timestamp: Date;
}

export interface BrowserContext {
  browser: Browser;
  page: Page;
  consoleLogs: ConsoleEntry[];
  pageErrors: PageError[];
  requestFailures: RequestFailure[];
  responseErrors: ResponseError[];
}

export interface NavigationResult {
  success: boolean;
  loadTimeMs: number;
  finalUrl: string;
  error?: string;
}

export interface ConsoleAnalysis {
  total: number;
  errors: ConsoleEntry[];
  warnings: ConsoleEntry[];
  criticalCount: number;
  byCategory: Record<string, number>;
}

// ============================================================================
// Default Configuration
// ============================================================================

const DEFAULT_LAUNCH_OPTIONS: Required<LaunchOptions> = {
  headless: 'new',
  slowMo: 0,
  devtools: false,
  viewport: { width: 1280, height: 720 },
  args: [
    '--no-sandbox',
    '--disable-setuid-sandbox',
    '--disable-dev-shm-usage',
    '--disable-gpu',
    '--no-first-run',
  ],
  timeout: 30000,
};

// ============================================================================
// Core Functions
// ============================================================================

/**
 * Launch browser with full capture setup
 */
export async function launchBrowser(
  options: LaunchOptions = {}
): Promise<BrowserContext> {
  const config = { ...DEFAULT_LAUNCH_OPTIONS, ...options };

  const browser = await puppeteer.launch({
    headless: config.headless,
    slowMo: config.slowMo,
    devtools: config.devtools,
    args: config.args,
    timeout: config.timeout,
  });

  const page = await browser.newPage();
  await page.setViewport(config.viewport);

  // Initialize capture arrays
  const consoleLogs: ConsoleEntry[] = [];
  const pageErrors: PageError[] = [];
  const requestFailures: RequestFailure[] = [];
  const responseErrors: ResponseError[] = [];

  // Capture console messages
  page.on('console', (msg: ConsoleMessage) => {
    consoleLogs.push({
      type: msg.type(),
      text: msg.text(),
      timestamp: new Date(),
      location: msg.location()?.url,
      stackTrace: msg.stackTrace()?.map((f) => `${f.url}:${f.lineNumber}`).join('\n'),
    });
  });

  // Capture page errors (uncaught exceptions)
  page.on('pageerror', (error: Error) => {
    pageErrors.push({
      message: error.message,
      stack: error.stack,
      timestamp: new Date(),
    });
  });

  // Capture failed requests
  page.on('requestfailed', (request: HTTPRequest) => {
    requestFailures.push({
      url: request.url(),
      resourceType: request.resourceType(),
      error: request.failure()?.errorText ?? 'Unknown error',
      timestamp: new Date(),
    });
  });

  // Capture error responses (4xx, 5xx)
  page.on('response', (response: HTTPResponse) => {
    const status = response.status();
    if (status >= 400) {
      responseErrors.push({
        url: response.url(),
        status,
        statusText: response.statusText(),
        resourceType: response.request().resourceType(),
        timestamp: new Date(),
      });
    }
  });

  return {
    browser,
    page,
    consoleLogs,
    pageErrors,
    requestFailures,
    responseErrors,
  };
}

/**
 * Navigate to URL and capture results
 */
export async function navigateAndCapture(
  ctx: BrowserContext,
  url: string,
  options: {
    timeout?: number;
    waitUntil?: 'load' | 'domcontentloaded' | 'networkidle0' | 'networkidle2';
  } = {}
): Promise<NavigationResult> {
  const startTime = Date.now();

  try {
    await ctx.page.goto(url, {
      timeout: options.timeout ?? 30000,
      waitUntil: options.waitUntil ?? 'networkidle0',
    });

    return {
      success: true,
      loadTimeMs: Date.now() - startTime,
      finalUrl: ctx.page.url(),
    };
  } catch (error) {
    return {
      success: false,
      loadTimeMs: Date.now() - startTime,
      finalUrl: ctx.page.url(),
      error: error instanceof Error ? error.message : String(error),
    };
  }
}

/**
 * Analyze captured console logs
 */
export function analyzeConsole(logs: ConsoleEntry[]): ConsoleAnalysis {
  const errors = logs.filter((l) => l.type === 'error');
  const warnings = logs.filter((l) => l.type === 'warning');

  const byCategory: Record<string, number> = {
    javascript: 0,
    network: 0,
    cors: 0,
    react: 0,
    security: 0,
    performance: 0,
    other: 0,
  };

  let criticalCount = 0;

  for (const log of errors) {
    const text = log.text.toLowerCase();

    if (text.includes('typeerror') || text.includes('referenceerror') || text.includes('syntaxerror')) {
      byCategory.javascript++;
      criticalCount++;
    } else if (text.includes('failed to fetch') || text.includes('net::') || text.includes('404') || text.includes('500')) {
      byCategory.network++;
      if (text.includes('500') || text.includes('failed to fetch')) {
        criticalCount++;
      }
    } else if (text.includes('cors') || text.includes('access-control')) {
      byCategory.cors++;
      criticalCount++;
    } else if (text.includes('react') || text.includes('hydration')) {
      byCategory.react++;
      criticalCount++;
    } else if (text.includes('csp') || text.includes('mixed content')) {
      byCategory.security++;
    } else if (text.includes('violation')) {
      byCategory.performance++;
    } else {
      byCategory.other++;
    }
  }

  return {
    total: logs.length,
    errors,
    warnings,
    criticalCount,
    byCategory,
  };
}

/**
 * Check if element exists
 */
export async function elementExists(
  ctx: BrowserContext,
  selector: string
): Promise<boolean> {
  const element = await ctx.page.$(selector);
  return element !== null;
}

/**
 * Check if element is visible
 */
export async function elementVisible(
  ctx: BrowserContext,
  selector: string
): Promise<boolean> {
  try {
    const visible = await ctx.page.$eval(selector, (el) => {
      const style = window.getComputedStyle(el);
      return (
        style.display !== 'none' &&
        style.visibility !== 'hidden' &&
        parseFloat(style.opacity) > 0
      );
    });
    return visible;
  } catch {
    return false;
  }
}

/**
 * Get element text content
 */
export async function getElementText(
  ctx: BrowserContext,
  selector: string
): Promise<string | null> {
  try {
    return await ctx.page.$eval(selector, (el) => el.textContent?.trim() ?? null);
  } catch {
    return null;
  }
}

/**
 * Take screenshot with error handling
 */
export async function takeScreenshot(
  ctx: BrowserContext,
  path: string,
  options: {
    fullPage?: boolean;
    selector?: string;
  } = {}
): Promise<boolean> {
  try {
    if (options.selector) {
      const element = await ctx.page.$(options.selector);
      if (element) {
        await element.screenshot({ path });
        return true;
      }
      return false;
    }

    await ctx.page.screenshot({
      path,
      fullPage: options.fullPage ?? false,
    });
    return true;
  } catch {
    return false;
  }
}

/**
 * Cleanup browser resources
 */
export async function cleanup(ctx: BrowserContext): Promise<void> {
  try {
    await ctx.browser.close();
  } catch {
    // Browser may already be closed
  }
}

// ============================================================================
// Quick Test Functions
// ============================================================================

/**
 * Quick health check - returns pass/fail with console errors
 */
export async function quickHealthCheck(
  url: string,
  options: LaunchOptions = {}
): Promise<{
  passed: boolean;
  loadTimeMs: number;
  errors: ConsoleEntry[];
  warnings: ConsoleEntry[];
  criticalCount: number;
}> {
  const ctx = await launchBrowser(options);

  try {
    const navResult = await navigateAndCapture(ctx, url);
    const analysis = analyzeConsole(ctx.consoleLogs);

    return {
      passed: navResult.success && analysis.criticalCount === 0,
      loadTimeMs: navResult.loadTimeMs,
      errors: analysis.errors,
      warnings: analysis.warnings,
      criticalCount: analysis.criticalCount,
    };
  } finally {
    await cleanup(ctx);
  }
}

// ============================================================================
// Export for direct execution
// ============================================================================

// Run quick test if executed directly
if (require.main === module) {
  const url = process.argv[2] || 'https://example.com';

  console.log(`Testing: ${url}\n`);

  quickHealthCheck(url)
    .then((result) => {
      console.log('Result:', result.passed ? 'PASS' : 'FAIL');
      console.log(`Load time: ${result.loadTimeMs}ms`);
      console.log(`Errors: ${result.errors.length}`);
      console.log(`Warnings: ${result.warnings.length}`);
      console.log(`Critical: ${result.criticalCount}`);

      if (result.errors.length > 0) {
        console.log('\nErrors found:');
        result.errors.forEach((e) => console.log(`  - ${e.text.substring(0, 100)}`));
      }

      process.exit(result.passed ? 0 : 1);
    })
    .catch((err) => {
      console.error('Test failed:', err.message);
      process.exit(1);
    });
}
