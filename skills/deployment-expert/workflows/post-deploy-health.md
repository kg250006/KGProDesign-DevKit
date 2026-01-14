<overview>
## Post-Deploy Health Check Workflow

Run comprehensive health checks after deployment to verify everything is working.
This workflow is critical for Docker/NPM deployments where DNS caching can cause 502 errors.

**CRITICAL: Always reload NPM after container rebuilds to refresh DNS cache.**
</overview>

<process>
## Step 1: Verify Container Health

```bash
# Check all containers are running and healthy
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Health}}' | grep {app}

# Expected output:
# {app}-backend-prod   Up 30 seconds (healthy)   healthy
# {app}-frontend-prod  Up 25 seconds (healthy)   healthy
# {app}-db-prod        Up 35 seconds (healthy)   healthy
```

**Health status meanings:**
- `healthy` - Container passed health checks
- `unhealthy` - Health check failed (investigate immediately)
- `starting` - Still running initial health checks (wait and retry)
- `(none)` - No health check defined (consider adding one)

**If unhealthy:**
```bash
# Check logs for the specific container
docker logs {app}-backend-prod --tail 100

# Check the health check command
docker inspect {app}-backend-prod --format='{{.Config.Healthcheck}}'
```

## Step 2: Reload NPM DNS Cache (CRITICAL)

**Why this is critical:** When Docker containers are rebuilt, they get new IP addresses. Nginx Proxy Manager caches the old IPs and will return 502 Bad Gateway until its nginx config is reloaded.

```bash
NPM_CONTAINER="nginx-proxy-manager"

# Check if NPM is running
if docker ps --format '{{.Names}}' | grep -q "^${NPM_CONTAINER}$"; then
    echo "Reloading NPM DNS cache..."

    # Test config before reload
    docker exec ${NPM_CONTAINER} nginx -t

    # Reload nginx to refresh DNS cache
    docker exec ${NPM_CONTAINER} nginx -s reload

    # Wait for DNS cache to refresh
    sleep 3

    echo "NPM reloaded successfully"
else
    echo "NPM container not found (may be on different host or not using NPM)"
fi
```

## Step 3: Verify NPM Connectivity

```bash
# Test that NPM can reach the backend container via Docker DNS
docker exec nginx-proxy-manager curl -sf http://{app}-backend-prod:8000/health && \
    echo "NPM → Backend: OK" || \
    echo "NPM → Backend: FAILED"

# Test that NPM can reach the frontend container
docker exec nginx-proxy-manager curl -sf http://{app}-frontend-prod:3000/ && \
    echo "NPM → Frontend: OK" || \
    echo "NPM → Frontend: FAILED"
```

**If connectivity fails:**
1. Verify containers are on the same Docker network as NPM
2. Check network configuration: `docker network inspect nginx-proxy-manager_npm-public`
3. Ensure docker-compose.prod.yml includes the external NPM network

## Step 4: Verify External Access

```bash
# Test HTTPS endpoint (through NPM/SSL)
DOMAIN="{domain}"

# Health endpoint
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 30 "https://${DOMAIN}/api/health")
if [[ "$HTTP_STATUS" == "200" ]]; then
    echo "HTTPS Health Check: OK ($HTTP_STATUS)"
else
    echo "HTTPS Health Check: FAILED ($HTTP_STATUS)"
fi

# Frontend page
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 30 "https://${DOMAIN}/")
if [[ "$HTTP_STATUS" == "200" ]]; then
    echo "Frontend Check: OK ($HTTP_STATUS)"
else
    echo "Frontend Check: FAILED ($HTTP_STATUS)"
fi
```

## Step 5: Check Application Logs for Errors

```bash
# Backend logs (last 50 lines, grep for errors)
echo "=== Backend Logs ==="
docker logs {app}-backend-prod --tail 50 2>&1 | grep -iE "(error|exception|fatal|critical)" || echo "No errors found"

# Frontend logs
echo "=== Frontend Logs ==="
docker logs {app}-frontend-prod --tail 50 2>&1 | grep -iE "(error|exception|fatal)" || echo "No errors found"

# Database logs
echo "=== Database Logs ==="
docker logs {app}-db-prod --tail 20 2>&1 | grep -iE "(error|fatal)" || echo "No errors found"
```

## Step 6: Verify Database Connectivity

```bash
# Test database connection from backend container
docker exec {app}-backend-prod python -c "
from sqlalchemy import create_engine
import os
engine = create_engine(os.environ['DATABASE_URL'])
conn = engine.connect()
print('Database connection: OK')
conn.close()
" 2>/dev/null && echo "DB Connection: OK" || echo "DB Connection: FAILED"

# Or for Node.js backends:
# docker exec {app}-backend-prod node -e "
# const { Pool } = require('pg');
# const pool = new Pool({ connectionString: process.env.DATABASE_URL });
# pool.query('SELECT 1').then(() => console.log('OK')).catch(console.error);
# "
```

## Step 7: Resource Check

```bash
# Check container resource usage
echo "=== Resource Usage ==="
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" | grep {app}

# Check host disk space
echo "=== Disk Space ==="
df -h / | tail -1

# Alert if disk usage > 80%
DISK_USAGE=$(df / | awk 'NR==2 {print int($5)}')
if [[ $DISK_USAGE -gt 80 ]]; then
    echo "WARNING: Disk usage at ${DISK_USAGE}%"
fi
```

## Step 8: Generate Health Report

```bash
echo "═══════════════════════════════════════"
echo "POST-DEPLOY HEALTH CHECK REPORT"
echo "═══════════════════════════════════════"
echo ""
echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
echo "App: {app-name}"
echo "Domain: {domain}"
echo ""
echo "Container Status:"
docker ps --format '  {{.Names}}: {{.Status}}' | grep {app}
echo ""
echo "Health Endpoints:"
echo "  Backend API:  $(curl -s -o /dev/null -w '%{http_code}' https://{domain}/api/health)"
echo "  Frontend:     $(curl -s -o /dev/null -w '%{http_code}' https://{domain}/)"
echo ""
echo "NPM Status:"
docker exec nginx-proxy-manager nginx -t 2>&1 | tail -1
echo ""
echo "Disk Space: $(df -h / | awk 'NR==2 {print $5 " used (" $4 " available)"}')"
echo ""
echo "═══════════════════════════════════════"
```
</process>

<quick_checks>
## Quick Health Check Commands

**One-liner for basic health:**
```bash
docker ps | grep {app} && curl -sf https://{domain}/api/health && echo "ALL OK"
```

**NPM reload (do this after every deploy):**
```bash
docker exec nginx-proxy-manager nginx -s reload
```

**Full health dashboard:**
```bash
docker ps --format 'table {{.Names}}\t{{.Status}}' | grep -E "(nginx|{app})" && \
curl -sw "\n" -o /dev/null https://{domain}/api/health && \
df -h / | tail -1
```
</quick_checks>

<common_issues>
## If Health Check Fails

| Status Code | Likely Cause | Fix |
|-------------|--------------|-----|
| 502 | NPM DNS cache stale | `docker exec nginx-proxy-manager nginx -s reload` |
| 503 | Container unhealthy/stopped | `docker compose up -d && docker compose logs` |
| Connection refused | Container not on NPM network | Check docker-compose networks config |
| Timeout | Container still starting | Wait 30s, retry |
| SSL error | Certificate issue | Check NPM SSL config |

**502 Bad Gateway is almost always fixed by reloading NPM after deploy.**
</common_issues>

<automation>
## Automated Health Check Script

Add to your deploy script after `docker compose up -d`:

```bash
# Post-deploy health check
post_deploy_health_check() {
    local MAX_RETRIES=6
    local RETRY_DELAY=10
    local NPM_CONTAINER="nginx-proxy-manager"
    local HEALTH_URL="https://{domain}/api/health"

    echo "Running post-deploy health checks..."

    # Step 1: Reload NPM (CRITICAL)
    if docker ps --format '{{.Names}}' | grep -q "^${NPM_CONTAINER}$"; then
        docker exec ${NPM_CONTAINER} nginx -s reload
        sleep 3
    fi

    # Step 2: Wait for containers to be healthy
    for i in $(seq 1 $MAX_RETRIES); do
        echo "Health check attempt $i/$MAX_RETRIES..."

        # Check container health
        UNHEALTHY=$(docker ps --format '{{.Names}} {{.Health}}' | grep {app} | grep -v healthy | wc -l)
        if [[ $UNHEALTHY -gt 0 ]]; then
            echo "Containers not yet healthy, waiting..."
            sleep $RETRY_DELAY
            continue
        fi

        # Check HTTP health
        HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$HEALTH_URL")
        if [[ "$HTTP_STATUS" == "200" ]]; then
            echo "Health check passed!"
            return 0
        fi

        echo "HTTP status: $HTTP_STATUS, retrying..."
        sleep $RETRY_DELAY
    done

    echo "Health check failed after $MAX_RETRIES attempts"
    return 1
}

# Call it
post_deploy_health_check
```
</automation>

<success_criteria>
Health check is complete when:
- [ ] All containers show "healthy" status
- [ ] NPM nginx config reloaded successfully
- [ ] NPM can reach backend and frontend containers
- [ ] External HTTPS endpoints return 200
- [ ] No critical errors in application logs
- [ ] Database connection verified
- [ ] Disk space above 20% free
- [ ] Health report generated
</success_criteria>
