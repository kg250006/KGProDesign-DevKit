# Video Recording Guide

<objective>
Last-resort visual testing technique for complex timing issues, animations, and race conditions. Video recording is resource-intensive - use only when screenshots and console capture are insufficient.
</objective>

---

## When to Use Video Recording

### Appropriate Use Cases

| Scenario | Why Video Helps |
|----------|-----------------|
| Intermittent bugs | Capture exact sequence when bug occurs |
| Animation issues | See timing and transitions |
| Race conditions | Observe order of operations |
| Complex user flows | Document multi-step interactions |
| Flaky tests | Identify what's different in failures |
| Performance perception | Visual feel of page load |

### When NOT to Use Video

| Scenario | Better Alternative |
|----------|-------------------|
| Element existence | DOM assertion |
| Text verification | Text assertion |
| API testing | Direct response check |
| Static UI check | Screenshot |
| Most functional tests | Standard assertions |

**Video should be your last resort** - it's expensive (CPU, storage, time).

---

## Resource Costs

### Storage Requirements
| Duration | Resolution | Approx. Size |
|----------|------------|--------------|
| 10 sec | 1280x720 | 2-5 MB |
| 1 min | 1280x720 | 10-30 MB |
| 5 min | 1280x720 | 50-150 MB |
| 1 min | 1920x1080 | 20-60 MB |

### Performance Impact
- CPU: 10-30% additional during recording
- Memory: 50-200MB additional
- Disk I/O: Continuous write operations
- Test duration: Encoding overhead at end

---

## Recording Methods

### Method 1: puppeteer-screen-recorder (Recommended)

```bash
npm install puppeteer-screen-recorder
```

```typescript
import { PuppeteerScreenRecorder } from 'puppeteer-screen-recorder';
import puppeteer from 'puppeteer';

async function recordInteraction() {
  const browser = await puppeteer.launch();
  const page = await browser.newPage();
  await page.setViewport({ width: 1280, height: 720 });

  // Initialize recorder
  const recorder = new PuppeteerScreenRecorder(page, {
    fps: 30,
    videoFrame: {
      width: 1280,
      height: 720,
    },
    videoCrf: 18,           // Quality (0-51, lower = better)
    videoCodec: 'libx264',  // H.264 codec
    videoPreset: 'ultrafast', // Encoding speed
    aspectRatio: '16:9',
  });

  // Start recording
  await recorder.start('./recording.mp4');

  // Perform actions
  await page.goto('https://example.com');
  await page.click('.button');
  await page.waitForTimeout(2000);

  // Stop recording
  await recorder.stop();

  await browser.close();
}
```

### Method 2: CDP Screen Capture (Frame-by-frame)

```typescript
import puppeteer from 'puppeteer';
import fs from 'fs';
import { exec } from 'child_process';

async function captureFrames() {
  const browser = await puppeteer.launch();
  const page = await browser.newPage();
  const client = await page.createCDPSession();

  await client.send('Page.startScreencast', {
    format: 'png',
    quality: 100,
    maxWidth: 1280,
    maxHeight: 720,
    everyNthFrame: 1,
  });

  const frames: string[] = [];
  let frameIndex = 0;

  client.on('Page.screencastFrame', async (event) => {
    const framePath = `frames/frame-${String(frameIndex).padStart(5, '0')}.png`;
    fs.writeFileSync(framePath, Buffer.from(event.data, 'base64'));
    frames.push(framePath);
    frameIndex++;

    // Acknowledge frame
    await client.send('Page.screencastFrameAck', {
      sessionId: event.sessionId,
    });
  });

  // Perform actions
  await page.goto('https://example.com');
  await page.waitForTimeout(5000);

  // Stop capture
  await client.send('Page.stopScreencast');

  // Combine frames into video with ffmpeg
  exec('ffmpeg -framerate 30 -i frames/frame-%05d.png -c:v libx264 output.mp4');

  await browser.close();
}
```

### Method 3: Browser's Built-in Recording (Headful Mode)

```typescript
const browser = await puppeteer.launch({
  headless: false,
  args: [
    '--enable-usermedia-screen-capturing',
    '--allow-http-screen-capture',
    '--auto-select-desktop-capture-source=Entire screen',
  ],
});

// Use browser's MediaRecorder API
await page.evaluate(() => {
  navigator.mediaDevices.getDisplayMedia({ video: true })
    .then(stream => {
      const recorder = new MediaRecorder(stream);
      const chunks: Blob[] = [];

      recorder.ondataavailable = (e) => chunks.push(e.data);
      recorder.onstop = () => {
        const blob = new Blob(chunks, { type: 'video/webm' });
        // Handle blob
      };

      recorder.start();
      // Stop after recording
      setTimeout(() => recorder.stop(), 10000);
    });
});
```

---

## Recording Best Practices

### Configuration for Testing

```typescript
const recorderConfig = {
  // Balance quality and file size
  fps: 15,                    // Lower FPS for smaller files
  videoCrf: 23,               // Moderate quality
  videoPreset: 'veryfast',    // Fast encoding

  // Match test viewport
  videoFrame: {
    width: 1280,
    height: 720,
  },

  // Output format
  videoCodec: 'libx264',
  aspectRatio: '16:9',
};
```

### Add Visual Indicators

```typescript
// Show mouse cursor position
await page.evaluate(() => {
  const cursor = document.createElement('div');
  cursor.id = 'test-cursor';
  cursor.style.cssText = `
    position: fixed;
    width: 20px;
    height: 20px;
    background: red;
    border-radius: 50%;
    pointer-events: none;
    z-index: 999999;
    transform: translate(-50%, -50%);
  `;
  document.body.appendChild(cursor);

  document.addEventListener('mousemove', (e) => {
    cursor.style.left = e.clientX + 'px';
    cursor.style.top = e.clientY + 'px';
  });
});

// Show click indicators
await page.evaluate(() => {
  document.addEventListener('click', (e) => {
    const ripple = document.createElement('div');
    ripple.style.cssText = `
      position: fixed;
      left: ${e.clientX}px;
      top: ${e.clientY}px;
      width: 0;
      height: 0;
      border: 2px solid blue;
      border-radius: 50%;
      transform: translate(-50%, -50%);
      animation: ripple 0.5s ease-out;
      pointer-events: none;
      z-index: 999999;
    `;
    document.body.appendChild(ripple);
    setTimeout(() => ripple.remove(), 500);
  });

  // Add animation keyframes
  const style = document.createElement('style');
  style.textContent = `
    @keyframes ripple {
      to {
        width: 40px;
        height: 40px;
        opacity: 0;
      }
    }
  `;
  document.head.appendChild(style);
});
```

### Add Timestamp Overlay

```typescript
await page.evaluate(() => {
  const timestamp = document.createElement('div');
  timestamp.id = 'recording-timestamp';
  timestamp.style.cssText = `
    position: fixed;
    top: 10px;
    right: 10px;
    background: rgba(0, 0, 0, 0.7);
    color: white;
    padding: 5px 10px;
    font-family: monospace;
    font-size: 14px;
    z-index: 999999;
  `;
  document.body.appendChild(timestamp);

  setInterval(() => {
    timestamp.textContent = new Date().toISOString().substr(11, 12);
  }, 100);
});
```

---

## Cleanup and Storage

### Automatic Cleanup

```typescript
import fs from 'fs';
import path from 'path';

const MAX_RECORDINGS = 10;
const RECORDINGS_DIR = './recordings';

function cleanupOldRecordings() {
  const files = fs.readdirSync(RECORDINGS_DIR)
    .filter(f => f.endsWith('.mp4'))
    .map(f => ({
      name: f,
      path: path.join(RECORDINGS_DIR, f),
      mtime: fs.statSync(path.join(RECORDINGS_DIR, f)).mtime,
    }))
    .sort((a, b) => b.mtime.getTime() - a.mtime.getTime());

  // Remove oldest files beyond limit
  files.slice(MAX_RECORDINGS).forEach(f => {
    fs.unlinkSync(f.path);
    console.log(`Deleted old recording: ${f.name}`);
  });
}
```

### Conditional Recording

```typescript
// Only record on failure
let recorder: PuppeteerScreenRecorder | null = null;
let testPassed = false;

if (process.env.RECORD_FAILURES === 'true') {
  recorder = new PuppeteerScreenRecorder(page);
  await recorder.start(`./recordings/test-${Date.now()}.mp4`);
}

try {
  // Test code
  testPassed = true;
} finally {
  if (recorder) {
    await recorder.stop();

    // Delete recording if test passed
    if (testPassed && process.env.KEEP_SUCCESSFUL_RECORDINGS !== 'true') {
      fs.unlinkSync(recordingPath);
    }
  }
}
```

---

## Troubleshooting

### Recording Not Starting

**Check**: FFmpeg installed
```bash
ffmpeg -version
```

**Install FFmpeg**:
```bash
# macOS
brew install ffmpeg

# Ubuntu
apt-get install ffmpeg

# Windows
# Download from ffmpeg.org
```

### Poor Video Quality

Adjust CRF (lower = better quality):
```typescript
const recorder = new PuppeteerScreenRecorder(page, {
  videoCrf: 15,  // High quality (default is 23)
});
```

### Choppy Video

Increase FPS or use veryfast preset:
```typescript
const recorder = new PuppeteerScreenRecorder(page, {
  fps: 30,
  videoPreset: 'veryfast',
});
```

### Large File Size

- Lower FPS: 15 instead of 30
- Increase CRF: 28 instead of 23
- Lower resolution: 1280x720 instead of 1920x1080
- Shorter recordings: Only capture relevant portions

### Recording Fails in CI

Check:
1. FFmpeg is installed in CI environment
2. Sufficient disk space
3. Headless mode compatible
4. Write permissions to output directory

---

## Dependencies

```bash
# Required
npm install puppeteer puppeteer-screen-recorder

# Optional (for frame-based capture)
# Install ffmpeg on system
```

---

## Summary

| Aspect | Recommendation |
|--------|----------------|
| When to use | Complex timing, animations, race conditions |
| When NOT to use | Any case where assertions or screenshots suffice |
| FPS | 15 for smaller files, 30 for smooth playback |
| Quality (CRF) | 23 for balance, lower for better quality |
| Duration | Keep as short as possible |
| Cleanup | Delete passed tests, keep failures |
| CI/CD | Only enable when debugging specific issues |
