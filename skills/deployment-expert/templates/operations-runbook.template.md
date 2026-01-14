# {VM-Name} Operations Runbook

**CRITICAL: Read this document FIRST when entering this VM for any deployment or troubleshooting.**

---

## Overview

**VM Purpose:** {Brief description of what this VM hosts}

**Architecture:**
- **Nginx Proxy Manager**: GUI-based reverse proxy and SSL management (port 81 for admin)
- **{App Name}**: {Tech stack, e.g., FastAPI backend + Next.js frontend}
- **Database**: PostgreSQL 16 (internal, not exposed)
- **Other Services**: {List any other hosted services}

**Key URLs:**
| Service | URL |
|---------|-----|
| NPM Admin | http://{vm-private-ip}:81 |
| Application | https://{domain} |
| API | https://{domain}/api/v1 |
| Health Check | https://{domain}/api/health |

**Auto-Deploy Status:**
- Cron Schedule: `*/5 * * * *` (every 5 minutes)
- Branch: `production`
- Log File: `/opt/cron/logs/{app}-deploy.log`

---

## Daily Operations

### Quick Health Check
```bash
# One-liner health check
docker ps | grep {app} && curl -sf https://{domain}/api/health && df -h / | tail -1
```

### Full Health Dashboard
```bash
# Container status
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Health}}' | grep -E "(nginx|{app})"

# Disk space
df -h /

# Memory
free -h

# Recent deploy logs
tail -20 /opt/cron/logs/{app}-deploy.log
```

### Monitor Logs
```bash
# All containers
docker logs {app}-backend-prod --tail 100 -f
docker logs {app}-frontend-prod --tail 100 -f
docker logs nginx-proxy-manager --tail 100

# Deployment logs
tail -f /opt/cron/logs/{app}-deploy.log

# System logs (cron execution)
grep CRON /var/log/syslog | tail -20
```

---

## Adding New Domain/Service

### Step 1: Create Container (if new service)
```bash
# Example for adding a new service
cd /opt/{new-service}
docker compose -f docker-compose.prod.yml up -d --build
```

### Step 2: Configure NPM Proxy Host
1. Access NPM Admin: http://{vm-private-ip}:81
2. Login with admin credentials
3. Add Proxy Host:
   - Domain: `{new-domain}`
   - Forward Hostname: `{container-name}` (Docker DNS)
   - Forward Port: `{internal-port}`
   - Enable "Block Common Exploits"
   - Enable "Websockets Support" if needed
4. Add SSL Certificate:
   - Request new Let's Encrypt certificate
   - Enable "Force SSL"

### Step 3: Update DNS
- Add A record: `{new-domain}` → `{gateway-ip}` (or Application Gateway IP)

### Step 4: Verify
```bash
curl -I https://{new-domain}
```

---

## Emergency Procedures

### Rollback Deployment
```bash
cd /opt/{app-name}

# Find previous commit
git log --oneline -n 10

# Rollback to specific commit
git reset --hard {commit-hash}

# Rebuild and restart
docker compose -f docker-compose.prod.yml up -d --build

# CRITICAL: Reload NPM
docker exec nginx-proxy-manager nginx -s reload
```

### Restart All Services
```bash
cd /opt/{app-name}
docker compose -f docker-compose.prod.yml down
docker compose -f docker-compose.prod.yml up -d

# CRITICAL: Reload NPM after restart
docker exec nginx-proxy-manager nginx -s reload
```

### Fix 502 Bad Gateway (Most Common)
```bash
# This is almost always NPM DNS cache issue after deploy
docker exec nginx-proxy-manager nginx -s reload
```

### Reset Circuit Breaker
```bash
# If auto-deploy stopped due to failures
cat /opt/cron/state/{app}-failures  # Check failure count
echo 0 > /opt/cron/state/{app}-failures  # Reset
```

### Disk Full Emergency
```bash
# Clear Docker build cache
docker system prune -af

# Clear old logs
sudo journalctl --vacuum-time=3d

# Check what's using space
du -sh /opt/*
du -sh /var/lib/docker/*
```

### Database Emergency Restore
```bash
# List available backups
ls -lh /opt/database_backups/

# Restore from backup
gunzip -c /opt/database_backups/{app}-{date}.sql.gz | \
    docker exec -i {app}-db-prod psql -U postgres -d {database}
```

---

## Troubleshooting

### 502 Bad Gateway
1. **Check container running:** `docker ps | grep {app}`
2. **Check logs:** `docker logs {app}-backend-prod --tail 50`
3. **Reload NPM:** `docker exec nginx-proxy-manager nginx -s reload`
4. **Verify network:** `docker network inspect nginx-proxy-manager_npm-public`

### SSL Certificate Issues
```bash
# Check certificate status in NPM
docker exec nginx-proxy-manager certbot certificates

# Force renewal
docker exec nginx-proxy-manager certbot renew --force-renewal
```

### Database Connection Errors
```bash
# Check database health
docker logs {app}-db-prod --tail 50

# Test connection from backend
docker exec {app}-backend-prod python -c "
from sqlalchemy import create_engine
import os
engine = create_engine(os.environ['DATABASE_URL'])
conn = engine.connect()
print('OK')
conn.close()
"
```

### Cron Auto-Deploy Not Working
```bash
# Check cron logs
grep CRON /var/log/syslog | tail -20

# Check lock file (stuck deploy?)
ls -la /opt/cron/locks/

# Check failure count (circuit breaker?)
cat /opt/cron/state/{app}-failures

# Check SSH config (git fetch failing?)
cat ~/.ssh/config | grep github
ssh -T git@github.com  # Test authentication
```

### High CPU/Memory
```bash
# Check container resource usage
docker stats --no-stream

# Restart specific container
docker restart {app}-backend-prod

# Check for memory leaks in logs
docker logs {app}-backend-prod --tail 200 | grep -i "memory\|oom"
```

---

## Maintenance Schedule

### Daily (Automated by cron)
- [x] Auto-deploy on git push (*/5 * * * *)
- [ ] Check container status: `docker ps`
- [ ] Check disk space: `df -h` (alert if >80%)

### Weekly
- [ ] Review deployment logs for errors
- [ ] Check SSL certificate expiry in NPM
- [ ] Review /opt/cron/logs/ for issues

### Monthly
- [ ] Update Docker images: `docker compose pull && docker compose up -d`
- [ ] Review access logs for security
- [ ] Prune old Docker images: `docker image prune -a --filter "until=720h"`

### Quarterly
- [ ] Test backup restoration
- [ ] Security vulnerability scan
- [ ] Update this runbook
- [ ] Rotate SSH keys if needed

---

## Backup Configuration

### Automated Backups (Cron)
```bash
# View current backup crons
crontab -l

# Expected entries:
# Database backup: 0 2 * * * /opt/scripts/backup-database.sh
# Auto-deploy: */5 * * * * /opt/cron/jobs/auto-deploy-{app}.sh
```

### Manual Database Backup
```bash
docker exec {app}-db-prod pg_dump -U postgres {database} | \
    gzip > /opt/database_backups/{app}-$(date +%Y%m%d).sql.gz

# Verify backup
ls -lh /opt/database_backups/
gunzip -c /opt/database_backups/{app}-$(date +%Y%m%d).sql.gz | head -50
```

---

## Useful Commands Reference

### Docker
```bash
docker ps                              # List running containers
docker logs {container} -f --tail 100  # Follow logs
docker stats                           # Resource usage
docker exec -it {container} sh         # Shell access
docker system df                       # Disk usage
docker system prune -af                # Clean up everything
```

### NPM (Nginx Proxy Manager)
```bash
docker exec nginx-proxy-manager nginx -t       # Test config
docker exec nginx-proxy-manager nginx -s reload # Reload (fixes 502)
docker exec nginx-proxy-manager certbot certificates  # List certs
```

### Database
```bash
docker exec {app}-db-prod psql -U postgres -d {database}  # Interactive
docker exec {app}-db-prod psql -U postgres -d {database} -c "SELECT version();"
docker exec {app}-db-prod pg_dump -U postgres {database} > backup.sql
```

### Network Debugging
```bash
docker network ls
docker network inspect {network}
docker exec nginx-proxy-manager curl -sf http://{app}-backend-prod:8000/health
```

### SSL
```bash
openssl s_client -connect {domain}:443 -servername {domain} | openssl x509 -noout -dates
curl -vI https://{domain} 2>&1 | grep -E "SSL|certificate"
```

---

## Contact / Access

**SSH Access:**
```bash
ssh {deploy-user}@{vm-private-ip}
# Or via jump host:
# ssh -J jumphost {deploy-user}@{vm-private-ip}
```

**VM Details:**
| Property | Value |
|----------|-------|
| VM Name | {vm-name} |
| Resource Group | {resource-group} |
| Private IP | {vm-private-ip} |
| Public IP | {public-ip} (via App Gateway) |
| Deploy User | {deploy-user} |

**Primary Admin:** {admin-email}

**Escalation:** {escalation-contact}

---

**Document Version:** 1.0
**Last Updated:** {date}
**Next Review:** {date + 3 months}
