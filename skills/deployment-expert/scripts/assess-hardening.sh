#!/bin/bash
# Corporate-Hardening Assess probe (Stage A).
# Detects stack + hosting + header-mechanism, flags shared-subdomain presented URLs,
# and probes the live URL for the security-header set + HTTPS/HSTS.
#
# Read-only: never edits the project. Prints detected stack/host/mechanism BEFORE findings.
# Exits non-zero only on script error (bad usage), NOT on hardening gaps.
#
# Usage: assess-hardening.sh [<url>] [<project-dir>]
#   url         Presented/custom domain (default: read from .deployment-profile.json)
#   project-dir Project root to inspect (default: current directory)
#
# Reuses scripts/detect-platform.sh for platform detection.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${2:-$PWD}"

cd "$PROJECT_DIR" 2>/dev/null || { echo "ERROR: project dir not found: $PROJECT_DIR" >&2; exit 2; }

# --- URL resolution ---
URL="${1:-}"
if [ -z "$URL" ] && [ -f ".deployment-profile.json" ] && command -v jq >/dev/null 2>&1; then
    URL="$(jq -r '.verification.url // empty' .deployment-profile.json)"
fi

# --- Platform detection (reuse detect-platform.sh) ---
PLATFORM="unknown"
if [ -f "$SCRIPT_DIR/detect-platform.sh" ]; then
    # Source only the function defs; detect-platform.sh's trailing main-block echoes
    # a platform line when sourced with no args, so discard that source-time output.
    # shellcheck source=/dev/null
    . "$SCRIPT_DIR/detect-platform.sh" >/dev/null 2>&1
    # detect_platform already echoes "unknown" on no-match; don't add a second fallback
    # (it returns non-zero on unknown, which would double the value).
    PLATFORM="$(detect_platform 2>/dev/null)"
    [ -z "$PLATFORM" ] && PLATFORM="unknown"
fi

# --- Build-type detection (static / spa / ssr) ---
detect_stack() {
    if [ -f "next.config.js" ] || [ -f "next.config.mjs" ] || [ -f "nuxt.config.ts" ] || [ -f "nuxt.config.js" ]; then
        echo "ssr"; return
    fi
    if [ -f "astro.config.mjs" ] || [ -f "astro.config.ts" ]; then
        echo "static"; return   # Astro defaults to static output
    fi
    if [ -f "vite.config.js" ] || [ -f "vite.config.ts" ] || [ -f "angular.json" ]; then
        echo "spa"; return
    fi
    if [ -f "index.html" ] && [ ! -f "package.json" ]; then
        echo "static"; return
    fi
    echo "unknown"
}
STACK="$(detect_stack)"

# --- Header-mechanism detection ---
detect_header_mechanism() {
    if [ "$PLATFORM" = "kgp-host" ]; then echo "kgp.toml [headers] (platform defaults; no .htaccess, no HSTS preload)"; return; fi
    if [ -f "netlify.toml" ] || [ -f "_headers" ]; then echo "netlify-config (_headers / netlify.toml)"; return; fi
    if [ -f "vercel.json" ]; then echo "vercel-config (vercel.json headers)"; return; fi
    if [ -f ".htaccess" ]; then echo "apache-htaccess"; return; fi
    case "$PLATFORM" in
        azure-vm|github-production) echo "nginx/NPM server-block"; return ;;
        ftp) echo "static-host (.htaccess or host header panel)"; return ;;
    esac
    echo "unknown (confirm with operator)"
}
MECHANISM="$(detect_header_mechanism)"

# --- Report detection BEFORE any verdict (F1 / AC1.1) ---
echo "=== Corporate-Hardening Assessment ==="
echo "Project:          $PROJECT_DIR"
echo "Presented URL:    ${URL:-<none>}"
echo "Detected stack:   $STACK"
echo "Detected host:    $PLATFORM"
echo "Header mechanism: $MECHANISM"
echo ""

# --- M1: shared-subdomain BLOCKER check ---
echo "--- M1: Custom domain ---"
case "$URL" in
    *.netlify.app|*.vercel.app|*.web.app|*.github.io|*.pages.dev|*.sitepage.app|*.sitepage.app/*)
        echo "BLOCKER: presented URL is a shared free-host subdomain — bind a custom domain before handoff." ;;
    https://*) echo "pass: custom HTTPS domain" ;;
    "") echo "manual-required: no URL set — cannot assess M1" ;;
    *) echo "fail: URL is not HTTPS or not a custom domain: $URL" ;;
esac
echo ""

# --- M2 + M4: live header + HTTPS/HSTS probe ---
echo "--- M2 (headers) / M4 (HTTPS + HSTS) ---"
if [ -z "$URL" ] || ! command -v curl >/dev/null 2>&1; then
    echo "manual-required: no URL or curl unavailable — skipping live probe"
else
    HDRS="$(curl -sS -D - -o /dev/null --max-time 30 "$URL" 2>/dev/null)"
    for h in x-frame-options x-content-type-options referrer-policy strict-transport-security permissions-policy; do
        if printf '%s\n' "$HDRS" | grep -iq "^$h:"; then
            echo "  present: $h"
        else
            echo "  MISSING: $h"
        fi
    done
    case "$URL" in
        https://*) echo "  HTTPS: yes" ;;
        *) echo "  HTTPS: NO" ;;
    esac
fi
echo ""
echo "Assessment probe complete (read-only). Feed results into workflows/hardening-assess.md."
exit 0
