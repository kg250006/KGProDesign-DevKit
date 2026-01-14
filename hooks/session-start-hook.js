#!/usr/bin/env node
/**
 * Ralph Loop SessionStart Hook - Cross-Platform Wrapper
 *
 * Detects the current platform and executes the appropriate script:
 * - Windows: session-start-hook.ps1 (PowerShell)
 * - macOS/Linux: session-start-hook.sh (Bash)
 *
 * This wrapper ensures the Ralph Loop SessionStart hook works correctly on all platforms.
 */

const { spawn } = require('child_process');
const path = require('path');
const os = require('os');

const isWindows = os.platform() === 'win32';
const hooksDir = __dirname;

function executeHook() {
    let child;

    if (isWindows) {
        // Windows: Execute PowerShell script
        const ps1Path = path.join(hooksDir, 'session-start-hook.ps1');
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
        const shPath = path.join(hooksDir, 'session-start-hook.sh');
        child = spawn('bash', [shPath], {
            stdio: ['pipe', 'inherit', 'inherit']
        });
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

executeHook();
