#!/usr/bin/env node
/**
 * PRP Safety Hook - Cross-Platform Wrapper
 * PreToolUse hook that blocks dangerous commands in isolated PRP execution.
 *
 * Detects the current platform and executes the appropriate script:
 * - Windows: prp-safety-hook.ps1 (PowerShell)
 * - macOS/Linux: prp-safety-hook.sh (Bash)
 *
 * This wrapper ensures the safety hook works correctly on all platforms.
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
    // On error, approve by default (fail-open for usability)
    console.log('{"decision": "approve", "reason": "stdin error - fail-open"}');
    process.exit(0);
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
        const ps1Path = path.join(hooksDir, 'prp-safety-hook.ps1');
        child = spawn('powershell.exe', [
            '-ExecutionPolicy', 'Bypass',
            '-NoProfile',
            '-NonInteractive',
            '-File', ps1Path
        ], {
            stdio: ['pipe', 'pipe', 'inherit'],
            windowsHide: true
        });
    } else {
        // macOS/Linux: Execute Bash script
        const shPath = path.join(hooksDir, 'prp-safety-hook.sh');
        child = spawn('bash', [shPath], {
            stdio: ['pipe', 'pipe', 'inherit']
        });
    }

    // Pass stdin data to child process
    if (stdinData) {
        child.stdin.write(stdinData);
    }
    child.stdin.end();

    // Capture stdout from child
    let output = '';
    child.stdout.on('data', (data) => {
        output += data;
    });

    // Propagate result
    child.on('close', (code) => {
        // Output the child's response
        if (output) {
            console.log(output.trim());
        } else {
            // Default approve if no output
            console.log('{"decision": "approve", "reason": "No hook output - default approve"}');
        }
        process.exit(0);
    });

    child.on('error', (err) => {
        // Fail-open on error
        console.log('{"decision": "approve", "reason": "Hook error - fail-open"}');
        process.exit(0);
    });
}
