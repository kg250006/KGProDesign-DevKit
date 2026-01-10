#!/bin/bash
# UI Visual Testing Skill - Puppeteer Setup Script
# Installs Puppeteer and verifies browser automation is working

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[*]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[+]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[-]${NC} $1"
}

# Check mode
if [ "$1" == "--check" ]; then
    echo "=== Puppeteer Setup Check ==="

    # Check Node.js
    if command -v node &> /dev/null; then
        NODE_VERSION=$(node --version)
        print_success "Node.js installed: $NODE_VERSION"

        # Check version >= 18
        MAJOR_VERSION=$(echo $NODE_VERSION | cut -d'.' -f1 | tr -d 'v')
        if [ "$MAJOR_VERSION" -lt 18 ]; then
            print_warning "Puppeteer 22+ requires Node.js 18+. Current: $NODE_VERSION"
        fi
    else
        print_error "Node.js not found"
        exit 1
    fi

    # Check npm/pnpm/yarn
    if command -v pnpm &> /dev/null; then
        print_success "pnpm installed: $(pnpm --version)"
    elif command -v yarn &> /dev/null; then
        print_success "yarn installed: $(yarn --version)"
    elif command -v npm &> /dev/null; then
        print_success "npm installed: $(npm --version)"
    else
        print_error "No package manager found (npm/pnpm/yarn)"
        exit 1
    fi

    # Check if Puppeteer is installed
    if [ -d "node_modules/puppeteer" ]; then
        PUPPETEER_VERSION=$(node -p "require('puppeteer/package.json').version" 2>/dev/null || echo "unknown")
        print_success "Puppeteer installed: $PUPPETEER_VERSION"
    else
        print_warning "Puppeteer not installed in current directory"
    fi

    # Check TypeScript
    if command -v npx &> /dev/null && npx tsc --version &> /dev/null 2>&1; then
        TSC_VERSION=$(npx tsc --version)
        print_success "TypeScript available: $TSC_VERSION"
    else
        print_warning "TypeScript not available (npx tsc)"
    fi

    echo ""
    echo "=== Check Complete ==="
    exit 0
fi

echo "========================================"
echo "  UI Visual Testing - Puppeteer Setup"
echo "========================================"
echo ""

# Check Node.js version
print_status "Checking Node.js version..."
if ! command -v node &> /dev/null; then
    print_error "Node.js is not installed. Please install Node.js 18+ first."
    echo "  Visit: https://nodejs.org/"
    exit 1
fi

NODE_VERSION=$(node --version)
MAJOR_VERSION=$(echo $NODE_VERSION | cut -d'.' -f1 | tr -d 'v')

if [ "$MAJOR_VERSION" -lt 18 ]; then
    print_error "Node.js 18+ required. Current version: $NODE_VERSION"
    exit 1
fi
print_success "Node.js $NODE_VERSION detected"

# Detect package manager
print_status "Detecting package manager..."
if command -v pnpm &> /dev/null; then
    PKG_MANAGER="pnpm"
    INSTALL_CMD="pnpm add"
elif command -v yarn &> /dev/null; then
    PKG_MANAGER="yarn"
    INSTALL_CMD="yarn add"
elif command -v npm &> /dev/null; then
    PKG_MANAGER="npm"
    INSTALL_CMD="npm install"
else
    print_error "No package manager found. Please install npm, pnpm, or yarn."
    exit 1
fi
print_success "Using $PKG_MANAGER"

# Check if package.json exists
if [ ! -f "package.json" ]; then
    print_status "No package.json found. Initializing..."
    $PKG_MANAGER init -y
    print_success "Created package.json"
fi

# Install Puppeteer
print_status "Installing Puppeteer (this may take a few minutes on first install)..."
echo "  Puppeteer will download Chromium (~280MB) if not cached."
echo ""

$INSTALL_CMD puppeteer

if [ $? -eq 0 ]; then
    print_success "Puppeteer installed successfully"
else
    print_error "Failed to install Puppeteer"
    echo ""
    echo "Troubleshooting:"
    echo "  1. Clear npm cache: npm cache clean --force"
    echo "  2. Delete node_modules: rm -rf node_modules"
    echo "  3. Try again: npm install puppeteer"
    exit 1
fi

# Install TypeScript (dev dependency)
print_status "Installing TypeScript..."
$INSTALL_CMD --save-dev typescript @types/node

if [ $? -eq 0 ]; then
    print_success "TypeScript installed"
else
    print_warning "TypeScript installation failed (optional)"
fi

# Verify installation
print_status "Verifying Puppeteer installation..."

# Create a simple test script
TEST_SCRIPT=$(cat << 'EOF'
const puppeteer = require('puppeteer');

async function test() {
  console.log('Launching browser...');
  const browser = await puppeteer.launch({ headless: 'new' });
  const page = await browser.newPage();

  console.log('Navigating to example.com...');
  await page.goto('https://example.com', { waitUntil: 'networkidle0' });

  const title = await page.title();
  console.log('Page title:', title);

  await browser.close();
  console.log('Browser closed successfully');

  return title === 'Example Domain';
}

test()
  .then(success => {
    if (success) {
      console.log('Verification PASSED');
      process.exit(0);
    } else {
      console.log('Verification FAILED - unexpected title');
      process.exit(1);
    }
  })
  .catch(err => {
    console.error('Verification FAILED:', err.message);
    process.exit(1);
  });
EOF
)

echo "$TEST_SCRIPT" > /tmp/puppeteer-test.js

if node /tmp/puppeteer-test.js; then
    print_success "Puppeteer verification passed"
    rm /tmp/puppeteer-test.js
else
    print_error "Puppeteer verification failed"
    rm /tmp/puppeteer-test.js
    echo ""
    echo "Troubleshooting:"
    echo "  1. Check if Chromium downloaded: ls node_modules/puppeteer/.local-chromium/"
    echo "  2. On Linux, install dependencies:"
    echo "     apt-get install -y libx11-xcb1 libxcomposite1 libxcursor1 libxdamage1"
    echo "  3. Try with --no-sandbox:"
    echo "     PUPPETEER_ARGS='--no-sandbox' node test.js"
    exit 1
fi

echo ""
echo "========================================"
print_success "Setup Complete!"
echo "========================================"
echo ""
echo "Puppeteer is ready for UI testing."
echo ""
echo "Quick start:"
echo "  const puppeteer = require('puppeteer');"
echo "  const browser = await puppeteer.launch({ headless: 'new' });"
echo "  const page = await browser.newPage();"
echo "  await page.goto('https://your-app.com');"
echo ""
echo "Run tests with: node your-test.js"
echo "Or TypeScript:  npx ts-node your-test.ts"
