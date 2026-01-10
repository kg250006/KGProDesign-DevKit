---
name: kgp-build
description: Build production bundle with validation and optimization checks
arguments: "[base-url] - Optional base URL for the build (e.g., '/' or '/kimrose/')"
---

# KGP Production Build Command

Build and validate production bundle for deployment with size checks and optimization warnings.

## Usage

```bash
# Build with default base URL (/)
/deploy:kgp-build

# Build with custom base URL
/deploy:kgp-build /kimrosecenter/
```

## What This Command Does

1. ✅ Cleans previous builds
2. ✅ Runs TypeScript type checking
3. ✅ Builds production bundle with Vite
4. ✅ Analyzes bundle size
5. ✅ Verifies dist/ structure
6. ✅ Checks for common issues
7. ✅ Provides optimization recommendations

## Implementation

$ARGUMENTS

<bash>
#!/bin/bash
set -e

BASE_URL="${1:-/}"

echo "═══════════════════════════════════════════════════════════"
echo "  🏗️  KGP PRODUCTION BUILD"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "📦 Base URL: $BASE_URL"
echo ""

# Step 1: Clean previous build
echo "1️⃣  Cleaning previous build..."
if [ -d "dist" ]; then
    rm -rf dist
    echo "   ✅ Removed old dist/ folder"
else
    echo "   ℹ️  No previous build found"
fi

# Step 2: Update base URL if needed
if [ "$BASE_URL" != "/" ]; then
    echo ""
    echo "2️⃣  Updating base URL in vite.config.ts..."

    # Backup vite.config.ts
    cp vite.config.ts vite.config.ts.backup

    # Update base URL (assumes vite.config.ts exists)
    if grep -q "base:" vite.config.ts; then
        # macOS-compatible sed
        sed -i '' "s|base: .*,|base: '$BASE_URL',|g" vite.config.ts 2>/dev/null || \
        sed -i "s|base: .*,|base: '$BASE_URL',|g" vite.config.ts
        echo "   ✅ Updated base URL to: $BASE_URL"
    else
        echo "   ⚠️  Warning: Could not find 'base:' in vite.config.ts"
    fi
else
    echo ""
    echo "2️⃣  Using default base URL: /"
fi

# Step 3: Type checking
echo ""
echo "3️⃣  Running TypeScript type checking..."
if npm run type-check; then
    echo "   ✅ Type checking passed"
else
    echo "   ❌ Type checking failed!"
    echo ""
    echo "   Fix TypeScript errors before deploying."

    # Restore vite.config.ts if we modified it
    if [ -f "vite.config.ts.backup" ]; then
        mv vite.config.ts.backup vite.config.ts
    fi

    exit 1
fi

# Step 4: Build production bundle
echo ""
echo "4️⃣  Building production bundle..."
echo ""

START_TIME=$(date +%s)

if npm run build; then
    END_TIME=$(date +%s)
    BUILD_TIME=$((END_TIME - START_TIME))
    echo ""
    echo "   ✅ Build completed in ${BUILD_TIME}s"
else
    echo ""
    echo "   ❌ Build failed!"

    # Restore vite.config.ts if we modified it
    if [ -f "vite.config.ts.backup" ]; then
        mv vite.config.ts.backup vite.config.ts
    fi

    exit 1
fi

# Step 5: Restore vite.config.ts if we modified it
if [ -f "vite.config.ts.backup" ]; then
    mv vite.config.ts.backup vite.config.ts
    echo ""
    echo "   ℹ️  Restored original vite.config.ts"
fi

# Step 6: Verify dist/ structure
echo ""
echo "5️⃣  Verifying build output..."

if [ ! -d "dist" ]; then
    echo "   ❌ dist/ folder not created!"
    exit 1
fi

if [ ! -f "dist/index.html" ]; then
    echo "   ❌ index.html not found in dist/!"
    exit 1
fi

if [ ! -d "dist/assets" ]; then
    echo "   ❌ assets/ folder not found in dist/!"
    exit 1
fi

echo "   ✅ Build structure is valid"

# Step 7: Analyze bundle size
echo ""
echo "6️⃣  Analyzing bundle size..."

TOTAL_SIZE_KB=$(du -sk dist | cut -f1)
TOTAL_SIZE_MB=$(echo "scale=2; $TOTAL_SIZE_KB / 1024" | bc)

echo "   📦 Total bundle size: ${TOTAL_SIZE_MB}MB (${TOTAL_SIZE_KB}KB)"

# Check for size warnings
if [ $TOTAL_SIZE_KB -gt 20000 ]; then
    echo "   ⚠️  Warning: Bundle is very large (>20MB)"
    echo "   💡 Consider:"
    echo "      - Code splitting"
    echo "      - Lazy loading routes"
    echo "      - Optimizing images"
    echo "      - Tree shaking unused dependencies"
elif [ $TOTAL_SIZE_KB -gt 10000 ]; then
    echo "   ⚠️  Warning: Bundle is quite large (>10MB)"
    echo "   💡 Consider optimizing for better performance"
else
    echo "   ✅ Bundle size is reasonable"
fi

# Count files
JS_FILES=$(find dist/assets -name "*.js" 2>/dev/null | wc -l | tr -d ' ')
CSS_FILES=$(find dist/assets -name "*.css" 2>/dev/null | wc -l | tr -d ' ')
IMAGE_FILES=$(find dist/images -type f 2>/dev/null | wc -l | tr -d ' ')

echo ""
echo "   📊 Build contents:"
echo "      - JavaScript files: $JS_FILES"
echo "      - CSS files: $CSS_FILES"
echo "      - Image files: $IMAGE_FILES"

# Step 8: Check for common issues
echo ""
echo "7️⃣  Checking for common issues..."

# Check for .map files (should exist for debugging)
MAP_FILES=$(find dist/assets -name "*.map" 2>/dev/null | wc -l | tr -d ' ')
if [ $MAP_FILES -eq 0 ]; then
    echo "   ⚠️  Warning: No source maps found"
    echo "   💡 Enable sourcemaps in vite.config.ts for debugging"
else
    echo "   ✅ Source maps generated ($MAP_FILES files)"
fi

# Check if images were copied
if [ $IMAGE_FILES -eq 0 ]; then
    echo "   ⚠️  Warning: No images found in dist/images/"
    echo "   💡 Verify images are in public/images/"
else
    echo "   ✅ Images copied successfully"
fi

# Check for index.html with proper asset references
if grep -q "assets/" dist/index.html; then
    echo "   ✅ Asset references look correct"
else
    echo "   ⚠️  Warning: No asset references found in index.html"
fi

# Step 9: Summary
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  ✅ BUILD COMPLETE!"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "📦 Build Summary:"
echo "   ├─ Location: ./dist/"
echo "   ├─ Size: ${TOTAL_SIZE_MB}MB"
echo "   ├─ JS files: $JS_FILES"
echo "   ├─ CSS files: $CSS_FILES"
echo "   ├─ Images: $IMAGE_FILES"
echo "   └─ Build time: ${BUILD_TIME}s"
echo ""
echo "🚀 Next steps:"
echo "   1. Test locally: npm run preview"
echo "   2. Upload to VM: /deploy:kgp-upload-files <subdomain>"
echo "   3. Or deploy everything: /deploy:kgp-deploy-app <app-name> <subdomain>"
echo ""

</bash>

## Success Criteria

- ✅ TypeScript compilation passes
- ✅ Vite build succeeds
- ✅ dist/ folder contains index.html and assets/
- ✅ Bundle size is analyzed
- ✅ No critical warnings

## Common Issues

### Build Fails with Type Errors

```bash
# Fix TypeScript errors first
npm run type-check

# Then rebuild
/deploy:kgp-build
```

### Bundle Too Large

```bash
# Analyze what's taking space
npm run build -- --mode=production

# Check vite.config.ts for:
# - Manual chunks configuration
# - Vendor splitting
# - Tree shaking
```

### Images Not Copied

Ensure images are in `public/images/` directory:
```
public/
  └── images/
      ├── logo.png
      └── hero.jpg
```

---

**Last Updated**: 2025-10-15
**Version**: 1.0
