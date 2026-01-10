---
name: kgp-3-verify
description: Verify deployment health, performance, and functionality
arguments: "<subdomain> <container-name> <port> - Subdomain, container name, and internal port to verify"
---

# KGP Deployment Verification Command

Comprehensive verification of deployed application including health checks, performance tests, and functional validation.

## Usage

```bash
# Verify deployment
/deploy:kgp-3-verify kimrose.srv1.kgprodesign.com kimrose-container 8084
```

## What This Command Does

1. ✅ Verifies VM connectivity
2. ✅ Checks container health status
3. ✅ Tests internal HTTP response
4. ✅ Validates file structure
5. ✅ Checks asset loading
6. ✅ Tests SPA routing
7. ✅ Provides DNS verification
8. ✅ Generates health report

## Implementation

$ARGUMENTS

<bash>
#!/bin/bash
set -e

SUBDOMAIN="$1"
CONTAINER_NAME="$2"
INTERNAL_PORT="$3"

# VM Configuration
VM_IP="74.249.103.192"
SSH_KEY="$HOME/.ssh/kgp_vm_deploy"
SSH_USER="kgpadmin"
SSH_OPTS="-i $SSH_KEY -o StrictHostKeyChecking=no"

# Validation
if [ -z "$SUBDOMAIN" ] || [ -z "$CONTAINER_NAME" ] || [ -z "$INTERNAL_PORT" ]; then
    echo "❌ Error: Missing arguments"
    echo ""
    echo "Usage: /deploy:kgp-3-verify <subdomain> <container-name> <port>"
    echo ""
    echo "Example: /deploy:kgp-3-verify kimrose.srv1.kgprodesign.com kimrose-container 8084"
    exit 1
fi

echo "═══════════════════════════════════════════════════════════"
echo "  🔍 KGP DEPLOYMENT VERIFICATION"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "🌐 Subdomain: $SUBDOMAIN"
echo "🐳 Container: $CONTAINER_NAME"
echo "🔌 Port: $INTERNAL_PORT"
echo "🖥️  VM: $VM_IP"
echo ""

ERRORS=0
WARNINGS=0

# Step 1: VM Connectivity
echo "1️⃣  Testing VM connectivity..."

if ssh $SSH_OPTS -o ConnectTimeout=5 $SSH_USER@$VM_IP 'echo "OK"' &> /dev/null; then
    echo "   ✅ VM is reachable"
else
    echo "   ❌ Cannot connect to VM"
    ERRORS=$((ERRORS + 1))
    exit 1
fi

# Step 2: Container Status
echo ""
echo "2️⃣  Checking container status..."

CONTAINER_STATUS=$(ssh $SSH_OPTS $SSH_USER@$VM_IP \
    "sudo docker inspect --format='{{.State.Status}}' $CONTAINER_NAME 2>/dev/null" || echo "not-found")

if [ "$CONTAINER_STATUS" = "running" ]; then
    echo "   ✅ Container is running"
else
    echo "   ❌ Container is not running (status: $CONTAINER_STATUS)"
    ERRORS=$((ERRORS + 1))
fi

# Step 3: Container Health
echo ""
echo "3️⃣  Checking container health..."

# Wait for health check (max 30 seconds)
echo "   ⏳ Waiting for health check..."

for i in {1..30}; do
    HEALTH_STATUS=$(ssh $SSH_OPTS $SSH_USER@$VM_IP \
        "sudo docker inspect --format='{{.State.Health.Status}}' $CONTAINER_NAME 2>/dev/null" || echo "none")

    if [ "$HEALTH_STATUS" = "healthy" ]; then
        echo "   ✅ Container is healthy (checked after ${i}s)"
        break
    elif [ "$HEALTH_STATUS" = "none" ]; then
        echo "   ⚠️  No health check configured"
        WARNINGS=$((WARNINGS + 1))
        break
    elif [ $i -eq 30 ]; then
        echo "   ❌ Container health check timeout (status: $HEALTH_STATUS)"
        ERRORS=$((ERRORS + 1))
    else
        sleep 1
    fi
done

# Step 4: Internal HTTP Response
echo ""
echo "4️⃣  Testing internal HTTP response..."

HTTP_CODE=$(ssh $SSH_OPTS $SSH_USER@$VM_IP \
    "sudo docker exec $CONTAINER_NAME curl -s -o /dev/null -w '%{http_code}' http://localhost:$INTERNAL_PORT/ 2>/dev/null" || echo "000")

if [ "$HTTP_CODE" = "200" ]; then
    echo "   ✅ HTTP 200 OK"
elif [ "$HTTP_CODE" = "301" ] || [ "$HTTP_CODE" = "302" ]; then
    echo "   ⚠️  HTTP $HTTP_CODE (redirect)"
    WARNINGS=$((WARNINGS + 1))
else
    echo "   ❌ HTTP $HTTP_CODE (expected 200)"
    ERRORS=$((ERRORS + 1))
fi

# Step 5: Validate HTML Content
echo ""
echo "5️⃣  Validating HTML content..."

HTML_CONTENT=$(ssh $SSH_OPTS $SSH_USER@$VM_IP \
    "sudo docker exec $CONTAINER_NAME curl -s http://localhost:$INTERNAL_PORT/" 2>/dev/null || echo "")

if echo "$HTML_CONTENT" | grep -q "<!DOCTYPE html>"; then
    echo "   ✅ Valid HTML document"
else
    echo "   ❌ Invalid HTML response"
    ERRORS=$((ERRORS + 1))
fi

if echo "$HTML_CONTENT" | grep -q '<div id="root">'; then
    echo "   ✅ React root element found"
else
    echo "   ⚠️  React root element not found"
    WARNINGS=$((WARNINGS + 1))
fi

if echo "$HTML_CONTENT" | grep -q '/assets/.*\.js'; then
    echo "   ✅ JavaScript assets referenced"
else
    echo "   ❌ No JavaScript assets found"
    ERRORS=$((ERRORS + 1))
fi

if echo "$HTML_CONTENT" | grep -q '/assets/.*\.css'; then
    echo "   ✅ CSS assets referenced"
else
    echo "   ⚠️  No CSS assets referenced"
    WARNINGS=$((WARNINGS + 1))
fi

# Step 6: File Structure Validation
echo ""
echo "6️⃣  Validating file structure..."

TARGET_DIR="/var/www/$SUBDOMAIN/public"

FILE_COUNT=$(ssh $SSH_OPTS $SSH_USER@$VM_IP \
    "find $TARGET_DIR -type f 2>/dev/null | wc -l | tr -d ' '")

if [ "$FILE_COUNT" -gt 0 ]; then
    echo "   ✅ Files present: $FILE_COUNT files"
else
    echo "   ❌ No files found in $TARGET_DIR"
    ERRORS=$((ERRORS + 1))
fi

# Check for required files
if ssh $SSH_OPTS $SSH_USER@$VM_IP "[ -f '$TARGET_DIR/index.html' ]"; then
    echo "   ✅ index.html exists"
else
    echo "   ❌ index.html missing"
    ERRORS=$((ERRORS + 1))
fi

if ssh $SSH_OPTS $SSH_USER@$VM_IP "[ -d '$TARGET_DIR/assets' ]"; then
    ASSET_COUNT=$(ssh $SSH_OPTS $SSH_USER@$VM_IP \
        "find $TARGET_DIR/assets -type f | wc -l | tr -d ' '")
    echo "   ✅ assets/ directory exists ($ASSET_COUNT files)"
else
    echo "   ❌ assets/ directory missing"
    ERRORS=$((ERRORS + 1))
fi

# Step 7: Asset Loading Test
echo ""
echo "7️⃣  Testing asset loading..."

# Extract first JS file from HTML
JS_FILE=$(echo "$HTML_CONTENT" | grep -oP '/assets/[^"]+\.js' | head -1)

if [ -n "$JS_FILE" ]; then
    JS_HTTP_CODE=$(ssh $SSH_OPTS $SSH_USER@$VM_IP \
        "sudo docker exec $CONTAINER_NAME curl -s -o /dev/null -w '%{http_code}' http://localhost:$INTERNAL_PORT$JS_FILE 2>/dev/null" || echo "000")

    if [ "$JS_HTTP_CODE" = "200" ]; then
        echo "   ✅ JavaScript assets load correctly"
    else
        echo "   ❌ JavaScript asset failed (HTTP $JS_HTTP_CODE)"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo "   ⚠️  No JavaScript files to test"
    WARNINGS=$((WARNINGS + 1))
fi

# Step 8: SPA Routing Test
echo ""
echo "8️⃣  Testing SPA routing..."

# Test a common route (should return index.html, not 404)
ROUTE_CODE=$(ssh $SSH_OPTS $SSH_USER@$VM_IP \
    "sudo docker exec $CONTAINER_NAME curl -s -o /dev/null -w '%{http_code}' http://localhost:$INTERNAL_PORT/about 2>/dev/null" || echo "000")

if [ "$ROUTE_CODE" = "200" ]; then
    echo "   ✅ SPA routing configured correctly"
elif [ "$ROUTE_CODE" = "404" ]; then
    echo "   ❌ SPA routing NOT configured (404 on /about)"
    echo "   💡 Nginx needs: try_files \$uri \$uri/ /index.html;"
    ERRORS=$((ERRORS + 1))
else
    echo "   ⚠️  Unexpected response for /about (HTTP $ROUTE_CODE)"
    WARNINGS=$((WARNINGS + 1))
fi

# Step 9: DNS Verification
echo ""
echo "9️⃣  Verifying DNS configuration..."

DNS_IP=$(dig +short $SUBDOMAIN 2>/dev/null | tail -1)

if [ -n "$DNS_IP" ]; then
    if [ "$DNS_IP" = "$VM_IP" ]; then
        echo "   ✅ DNS correctly points to VM ($DNS_IP)"
    else
        echo "   ⚠️  DNS mismatch!"
        echo "      Expected: $VM_IP"
        echo "      Got: $DNS_IP"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo "   ⚠️  DNS not configured for $SUBDOMAIN"
    echo "   💡 Add A record: $SUBDOMAIN → $VM_IP"
    WARNINGS=$((WARNINGS + 1))
fi

# Step 10: Container Logs Check
echo ""
echo "🔟 Checking container logs for errors..."

ERROR_LOGS=$(ssh $SSH_OPTS $SSH_USER@$VM_IP \
    "sudo docker logs $CONTAINER_NAME --tail 50 2>&1 | grep -i 'error\|fatal\|warning' | head -5" || echo "")

if [ -z "$ERROR_LOGS" ]; then
    echo "   ✅ No errors in container logs"
else
    echo "   ⚠️  Found warnings/errors in logs:"
    echo "$ERROR_LOGS" | while read line; do
        echo "      $line"
    done
    WARNINGS=$((WARNINGS + 1))
fi

# Final Summary
echo ""
echo "═══════════════════════════════════════════════════════════"

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo "  ✅ ALL CHECKS PASSED!"
elif [ $ERRORS -eq 0 ]; then
    echo "  ⚠️  PASSED WITH WARNINGS"
else
    echo "  ❌ VERIFICATION FAILED"
fi

echo "═══════════════════════════════════════════════════════════"
echo ""
echo "📊 Verification Summary:"
echo "   ├─ Errors: $ERRORS"
echo "   ├─ Warnings: $WARNINGS"
echo "   ├─ Container: $CONTAINER_STATUS"
echo "   ├─ Health: $HEALTH_STATUS"
echo "   ├─ HTTP: $HTTP_CODE"
echo "   └─ Files: $FILE_COUNT"
echo ""

if [ $ERRORS -eq 0 ]; then
    echo "🚀 Next steps:"
    echo "   1. Configure NPM proxy host (if not done)"
    echo "   2. Test public URL: https://$SUBDOMAIN"
    echo "   3. Run Lighthouse audit"
    echo ""
else
    echo "🔧 Fix the errors above before proceeding."
    echo ""
    exit 1
fi

</bash>

## Success Criteria

- ✅ Container running and healthy
- ✅ HTTP 200 response
- ✅ Valid HTML with React root
- ✅ Assets referenced and loading
- ✅ SPA routing configured
- ✅ DNS pointing to correct IP
- ⚠️  No critical errors in logs

## Common Issues

### SPA Routing Returns 404

Nginx config needs `try_files` directive. Update Dockerfile:
```nginx
location / {
    try_files $uri $uri/ /index.html;
}
```

### Assets Return 404

Check base URL in vite.config.ts matches deployment path.

### Container Not Healthy

Check container logs:
```bash
ssh -i ~/.ssh/kgp_vm_deploy kgpadmin@74.249.103.192 \
  'sudo docker logs kimrose-container --tail 50'
```

---

**Last Updated**: 2025-10-15
**Version**: 1.0
