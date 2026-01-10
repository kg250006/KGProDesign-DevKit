# Puppeteer Setup Reference

<objective>
Installation, configuration, and best practices for Puppeteer browser automation.
</objective>

<installation>
## Installation Options

### Option 1: Full Puppeteer (Recommended)

Downloads bundled Chromium (~280MB):

```bash
# npm
npm install puppeteer

# pnpm
pnpm add puppeteer

# yarn
yarn add puppeteer
```

### Option 2: Puppeteer-Core (Bring Your Own Browser)

No Chromium download, requires existing browser installation:

```bash
npm install puppeteer-core
```

Then specify browser path:
```typescript
import puppeteer from 'puppeteer-core';

const browser = await puppeteer.launch({
  executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
  // or use PUPPETEER_EXECUTABLE_PATH env var
});
```

### TypeScript Support

```bash
npm install --save-dev @types/node typescript
```

tsconfig.json:
```json
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "moduleResolution": "node",
    "esModuleInterop": true,
    "strict": true,
    "skipLibCheck": true,
    "outDir": "./dist"
  },
  "include": ["**/*.ts"]
}
```
</installation>

<browser_launch_options>
## Browser Launch Options

### Common Options

```typescript
const browser = await puppeteer.launch({
  // Headless mode
  headless: 'new',           // New headless (recommended)
  // headless: true,         // Legacy headless
  // headless: false,        // Show browser window (debugging)

  // Debugging
  devtools: false,           // Open DevTools
  slowMo: 0,                 // Slow down operations by N ms

  // Performance
  args: [
    '--no-sandbox',          // Required for some Linux environments
    '--disable-setuid-sandbox',
    '--disable-dev-shm-usage', // Overcome limited /dev/shm in Docker
    '--disable-gpu',         // Disable GPU (stability)
    '--no-first-run',
    '--no-zygote',
    '--single-process',      // Single process mode (Docker)
  ],

  // Timeouts
  timeout: 30000,            // Launch timeout in ms

  // User data
  userDataDir: './browser-data', // Persist session data
});
```

### Environment-Specific Configurations

**Development:**
```typescript
const browser = await puppeteer.launch({
  headless: false,
  devtools: true,
  slowMo: 100,
});
```

**CI/CD (GitHub Actions, Docker):**
```typescript
const browser = await puppeteer.launch({
  headless: 'new',
  args: [
    '--no-sandbox',
    '--disable-setuid-sandbox',
    '--disable-dev-shm-usage',
    '--disable-gpu',
    '--no-first-run',
    '--no-zygote',
  ],
});
```

**Docker:**
```dockerfile
FROM node:20-slim

# Install Chrome dependencies
RUN apt-get update && apt-get install -y \
    chromium \
    libx11-xcb1 \
    libxcomposite1 \
    libxcursor1 \
    libxdamage1 \
    libxi6 \
    libxtst6 \
    libnss3 \
    libxrandr2 \
    libasound2 \
    libpangocairo-1.0-0 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libgbm1 \
    --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium
```
</browser_launch_options>

<page_configuration>
## Page Configuration

### Viewport

```typescript
const page = await browser.newPage();

// Set viewport
await page.setViewport({
  width: 1280,
  height: 720,
  deviceScaleFactor: 1,
  isMobile: false,
  hasTouch: false,
});

// Common viewport presets
const viewports = {
  desktop: { width: 1920, height: 1080 },
  laptop: { width: 1280, height: 720 },
  tablet: { width: 768, height: 1024 },
  mobile: { width: 375, height: 667 },
};
```

### User Agent

```typescript
await page.setUserAgent('Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36');
```

### Request Interception

```typescript
await page.setRequestInterception(true);

page.on('request', request => {
  // Block images for faster tests
  if (request.resourceType() === 'image') {
    request.abort();
  } else {
    request.continue();
  }
});
```

### Authentication

```typescript
// Basic auth
await page.authenticate({
  username: 'user',
  password: 'pass',
});

// Cookie-based auth
await page.setCookie({
  name: 'session',
  value: 'abc123',
  domain: 'example.com',
});
```
</page_configuration>

<console_capture>
## Console Capture Setup

### Basic Capture

```typescript
interface ConsoleEntry {
  type: string;
  text: string;
  timestamp: Date;
  location?: string;
}

const consoleLogs: ConsoleEntry[] = [];

page.on('console', msg => {
  consoleLogs.push({
    type: msg.type(),      // 'log', 'warning', 'error', 'info', 'debug'
    text: msg.text(),
    timestamp: new Date(),
    location: msg.location()?.url,
  });
});
```

### Error Capture

```typescript
const pageErrors: Error[] = [];

page.on('pageerror', error => {
  pageErrors.push(error);
});
```

### Network Failure Capture

```typescript
interface RequestFailure {
  url: string;
  resourceType: string;
  error: string;
}

const requestFailures: RequestFailure[] = [];

page.on('requestfailed', request => {
  requestFailures.push({
    url: request.url(),
    resourceType: request.resourceType(),
    error: request.failure()?.errorText ?? 'Unknown error',
  });
});
```

### Response Monitoring

```typescript
page.on('response', response => {
  const status = response.status();
  if (status >= 400) {
    console.warn(`HTTP ${status}: ${response.url()}`);
  }
});
```
</console_capture>

<error_handling>
## Error Handling Patterns

### Timeout Handling

```typescript
try {
  await page.goto(url, { waitUntil: 'networkidle0', timeout: 30000 });
} catch (error) {
  if (error.message.includes('timeout')) {
    console.error('Page load timeout - page may be slow or unresponsive');
    await page.screenshot({ path: 'timeout-screenshot.png' });
  }
  throw error;
}
```

### Navigation Errors

```typescript
try {
  await page.goto(url);
} catch (error) {
  if (error.message.includes('net::ERR_NAME_NOT_RESOLVED')) {
    console.error('DNS resolution failed - check URL');
  } else if (error.message.includes('net::ERR_CONNECTION_REFUSED')) {
    console.error('Connection refused - server may be down');
  } else if (error.message.includes('net::ERR_CERT_')) {
    console.error('SSL certificate error');
  }
  throw error;
}
```

### Element Not Found

```typescript
const element = await page.$('selector');
if (!element) {
  console.error('Element not found: selector');
  await page.screenshot({ path: 'element-not-found.png' });
  throw new Error('Required element not found');
}
```

### Graceful Cleanup

```typescript
let browser;
try {
  browser = await puppeteer.launch();
  const page = await browser.newPage();
  // ... test code
} catch (error) {
  console.error('Test failed:', error.message);
  throw error;
} finally {
  if (browser) {
    await browser.close();
  }
}
```
</error_handling>

<troubleshooting>
## Common Issues

### Chromium Download Fails

```bash
# Clear cache and reinstall
rm -rf node_modules/.cache/puppeteer
npm install puppeteer
```

### EACCES Permission Error

```bash
# Fix npm permissions
sudo chown -R $(whoami) ~/.npm
sudo chown -R $(whoami) node_modules
```

### Protocol Error: Target Closed

Usually means browser crashed. Check:
- Memory limits (increase Docker memory)
- Sandbox settings (add --no-sandbox)
- GPU issues (add --disable-gpu)

### Element Not Visible

```typescript
// Wait for element to be visible
await page.waitForSelector('selector', { visible: true });

// Or scroll into view
await page.$eval('selector', el => el.scrollIntoView());
```

### Detached Frame

Frame was navigated away before operation completed:
```typescript
// Store element references, don't reuse across navigations
const element = await page.$('selector');
await element.click(); // May fail if page navigated

// Better: re-query after navigation
await page.goto(newUrl);
const newElement = await page.$('selector');
```
</troubleshooting>

<version_compatibility>
## Version Compatibility

| Puppeteer | Node.js | Chromium |
|-----------|---------|----------|
| 22.x | 18+ | 123+ |
| 21.x | 16+ | 119+ |
| 20.x | 16+ | 115+ |

Always check: https://pptr.dev/supported-browsers
</version_compatibility>
