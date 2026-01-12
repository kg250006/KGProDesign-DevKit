#!/usr/bin/env node
/**
 * Ralph Loop Stop Hook - Cross-Platform Wrapper
 *
 * Detects the current platform and executes the appropriate script:
 * - Windows: stop-hook.ps1 (PowerShell)
 * - macOS/Linux: stop-hook.sh (Bash)
 *
 * This wrapper ensures the Ralph Loop hook works correctly on all platforms.
 */

const { spawn } = require('child_process');
const path = require('path');
const os = require('os');

const isWindows = os.platform() === 'win32';
const hooksDir = __dirname;

// Collect stdin to pass to child process
let stdinData = '';
process.stdin.setEncoding('utf8');

process.stdin.on('data', (chunk) => {
    stdinData += chunk;
});

process.stdin.on('end', () => {
    executeHook();
});

// Handle case where stdin is empty/closed immediately
process.stdin.on('error', () => {
    executeHook();
});

// Set a timeout in case stdin never closes (shouldn't happen, but safety first)
setTimeout(() => {
    if (!stdinData) {
        executeHook();
    }
}, 100);

function executeHook() {
    let child;

    if (isWindows) {
        // Windows: Execute PowerShell script
        const ps1Path = path.join(hooksDir, 'stop-hook.ps1');
        child = spawn('powershell.exe', [
            '-ExecutionPolicy', 'Bypass',
            '-NoProfile',
            '-NonInteractive',
            '-File', ps1Path
        ], {
            stdio: ['pipe', 'inherit', 'inherit'],
            windowsHide: true
        });
    } else {
        // macOS/Linux: Execute Bash script
        const shPath = path.join(hooksDir, 'stop-hook.sh');
        child = spawn('bash', [shPath], {
            stdio: ['pipe', 'inherit', 'inherit']
        });
    }

    // Pass stdin data to child process
    if (stdinData) {
        child.stdin.write(stdinData);
    }
    child.stdin.end();

    // Propagate exit code
    child.on('close', (code) => {
        process.exit(code || 0);
    });

    child.on('error', (err) => {
        console.error(`Failed to execute hook: ${err.message}`);
        process.exit(0); // Exit cleanly to not block Claude
    });
}
