<overview>
Azure VM deployment via SSH and Azure CLI. Covers connection setup, deploy scripts, Docker-based deployments, and CI/CD integration with cron jobs or webhooks.
</overview>

<prerequisites>
## Prerequisites

**Local requirements:**
```bash
# Azure CLI
brew install azure-cli  # macOS
# Or: curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash  # Linux

# SSH client (usually pre-installed)
ssh -V
```

**Azure requirements:**
- Azure subscription
- Resource group with VM
- VM with public IP or private endpoint
- SSH key pair configured
- NSG rules allowing SSH (port 22)
</prerequisites>

<authentication>
## Authentication

**Azure CLI login:**
```bash
# Interactive browser login
az login

# Service principal (CI/CD)
az login --service-principal -u $APP_ID -p $PASSWORD --tenant $TENANT_ID

# Managed identity (from Azure resource)
az login --identity
```

**SSH key setup:**
```bash
# Generate key pair
ssh-keygen -t ed25519 -C "deploy@project" -f ~/.ssh/azure_deploy

# Copy public key to VM
ssh-copy-id -i ~/.ssh/azure_deploy.pub user@vm-ip

# Or add via Azure CLI
az vm user update \
  --resource-group myResourceGroup \
  --name myVM \
  --username deployuser \
  --ssh-key-value "$(cat ~/.ssh/azure_deploy.pub)"
```

**Store credentials securely:**
```bash
# Create deployment expert config
mkdir -p ~/.deployment-expert
chmod 700 ~/.deployment-expert

# Store Azure config
cat > ~/.deployment-expert/azure-config.json << 'EOF'
{
  "subscription": "subscription-id",
  "resourceGroup": "my-resource-group",
  "vmName": "my-vm",
  "sshKeyPath": "~/.ssh/azure_deploy"
}
EOF
chmod 600 ~/.deployment-expert/azure-config.json
```
</authentication>

<ssh_deployment>
## SSH Deployment

**Basic deployment pattern:**
```bash
# Single command
ssh user@vm.azure.com "cd /var/www/app && git pull && npm install && npm run build && pm2 restart all"

# With deploy script
ssh user@vm.azure.com "cd /var/www/app && ./deploy.sh"
```

**Deploy script on server (`/var/www/app/deploy.sh`):**
```bash
#!/bin/bash
set -e  # Exit on error

APP_DIR="/var/www/app"
BACKUP_DIR="/var/www/backups"

echo "Starting deployment..."

# Backup current version
cp -r $APP_DIR $BACKUP_DIR/$(date +%Y%m%d_%H%M%S)

# Pull latest code
cd $APP_DIR
git fetch origin
git reset --hard origin/main

# Install dependencies
npm ci --production

# Build
npm run build

# Run migrations
npm run migrate

# Restart app
pm2 restart ecosystem.config.js

# Health check
sleep 5
curl -f http://localhost:3000/health || (echo "Health check failed" && exit 1)

echo "Deployment complete!"
```

**SSH config for easier access:**
```bash
# ~/.ssh/config
Host azure-prod
    HostName 52.123.45.67
    User deployuser
    IdentityFile ~/.ssh/azure_deploy
    StrictHostKeyChecking accept-new

Host azure-staging
    HostName 52.123.45.68
    User deployuser
    IdentityFile ~/.ssh/azure_deploy
```

**Use:**
```bash
ssh azure-prod "cd /app && ./deploy.sh"
```
</ssh_deployment>

<azure_cli_deployment>
## Azure CLI Deployment

**Run command on VM:**
```bash
az vm run-command invoke \
  --resource-group myResourceGroup \
  --name myVM \
  --command-id RunShellScript \
  --scripts "cd /var/www/app && ./deploy.sh"
```

**Run with script file:**
```bash
az vm run-command invoke \
  --resource-group myResourceGroup \
  --name myVM \
  --command-id RunShellScript \
  --scripts @deploy-remote.sh
```

**Get command output:**
```bash
az vm run-command invoke \
  --resource-group myResourceGroup \
  --name myVM \
  --command-id RunShellScript \
  --scripts "systemctl status nginx" \
  --query 'value[0].message' -o tsv
```

**List VMs:**
```bash
az vm list --resource-group myResourceGroup --output table
az vm list-ip-addresses --resource-group myResourceGroup --output table
```

**Start/stop VM:**
```bash
az vm start --resource-group myResourceGroup --name myVM
az vm stop --resource-group myResourceGroup --name myVM
az vm deallocate --resource-group myResourceGroup --name myVM
```
</azure_cli_deployment>

<docker_deployment>
## Docker Deployment

**Docker Compose on VM:**
```bash
ssh azure-prod << 'EOF'
cd /var/www/app
git pull origin main
docker compose down
docker compose pull
docker compose up -d --build
docker compose ps
EOF
```

**Deploy script for Docker:**
```bash
#!/bin/bash
set -e

APP_DIR="/var/www/app"
cd $APP_DIR

echo "Pulling latest code..."
git fetch origin main
git reset --hard origin/main

echo "Pulling images..."
docker compose pull

echo "Stopping containers..."
docker compose down

echo "Building and starting..."
docker compose up -d --build

echo "Cleaning up..."
docker image prune -f

echo "Checking status..."
docker compose ps

echo "Health check..."
sleep 10
curl -f http://localhost:80/health || (docker compose logs && exit 1)

echo "Deployment complete!"
```

**docker-compose.yml example:**
```yaml
version: '3.8'
services:
  app:
    build: .
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - DATABASE_URL=${DATABASE_URL}
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - /etc/letsencrypt:/etc/letsencrypt:ro
    depends_on:
      - app
    restart: unless-stopped
```
</docker_deployment>

<cron_deployment>
## Cron-Based Deployment

**Auto-deploy on git push (server-side cron):**
```bash
# /etc/cron.d/deploy-app
*/5 * * * * deployuser /var/www/app/scripts/check-and-deploy.sh >> /var/log/deploy.log 2>&1
```

**check-and-deploy.sh:**
```bash
#!/bin/bash
set -e

APP_DIR="/var/www/app"
DEPLOY_BRANCH="production"
LOCK_FILE="/tmp/deploy.lock"

# Prevent concurrent deploys
if [ -f "$LOCK_FILE" ]; then
    echo "Deploy already in progress"
    exit 0
fi

cd $APP_DIR

# Check for new commits
git fetch origin $DEPLOY_BRANCH
LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse origin/$DEPLOY_BRANCH)

if [ "$LOCAL" = "$REMOTE" ]; then
    echo "No changes detected"
    exit 0
fi

echo "New commits detected, deploying..."

# Create lock
touch $LOCK_FILE
trap "rm -f $LOCK_FILE" EXIT

# Deploy
git reset --hard origin/$DEPLOY_BRANCH
./deploy.sh

echo "Deploy complete at $(date)"
```

**Webhook alternative (more immediate):**
```bash
# Simple webhook receiver
# /var/www/webhook/server.js
const http = require('http');
const { exec } = require('child_process');

http.createServer((req, res) => {
  if (req.method === 'POST' && req.url === '/deploy') {
    exec('/var/www/app/deploy.sh', (err, stdout, stderr) => {
      console.log(stdout);
      if (err) console.error(stderr);
    });
    res.writeHead(200);
    res.end('Deploy triggered');
  }
}).listen(9000);
```
</cron_deployment>

<environment_variables>
## Environment Variables

**Set on VM:**
```bash
ssh azure-prod << 'EOF'
# Add to .env file
cat >> /var/www/app/.env << 'ENVEOF'
DATABASE_URL=postgresql://user:pass@host:5432/db
API_KEY=secret-key-here
ENVEOF

# Or set system-wide
echo 'export DATABASE_URL="postgresql://..."' >> /etc/environment
EOF
```

**Sync from local:**
```bash
# Copy .env.production to server
scp .env.production azure-prod:/var/www/app/.env

# Set permissions
ssh azure-prod "chmod 600 /var/www/app/.env"
```

**Docker environment:**
```bash
# Create .env on server
ssh azure-prod "cat > /var/www/app/.env" < .env.production

# Docker compose uses it automatically
# Or specify in docker-compose.yml:
# env_file:
#   - .env
```

**Azure Key Vault integration:**
```bash
# Store secret
az keyvault secret set --vault-name myVault --name "DatabaseUrl" --value "postgresql://..."

# Retrieve in deploy script
DATABASE_URL=$(az keyvault secret show --vault-name myVault --name "DatabaseUrl" --query value -o tsv)
```
</environment_variables>

<monitoring>
## Monitoring and Logs

**Check application logs:**
```bash
# PM2 logs
ssh azure-prod "pm2 logs --lines 100"

# Docker logs
ssh azure-prod "docker compose logs --tail 100 app"

# System logs
ssh azure-prod "journalctl -u myapp -n 100"
```

**Check resource usage:**
```bash
# CPU/Memory
ssh azure-prod "htop"
ssh azure-prod "free -h && df -h"

# Docker stats
ssh azure-prod "docker stats --no-stream"
```

**Azure Monitor:**
```bash
# Get metrics
az monitor metrics list \
  --resource /subscriptions/{sub}/resourceGroups/{rg}/providers/Microsoft.Compute/virtualMachines/{vm} \
  --metric "Percentage CPU" \
  --interval PT1H
```
</monitoring>

<troubleshooting>
## Troubleshooting

**SSH connection issues:**
```bash
# Test connection
ssh -v azure-prod

# Check key permissions
chmod 600 ~/.ssh/azure_deploy
chmod 700 ~/.ssh

# Check NSG rules
az network nsg rule list --resource-group myRG --nsg-name myNSG -o table
```

**Deploy fails:**
```bash
# Check disk space
ssh azure-prod "df -h"

# Check memory
ssh azure-prod "free -h"

# Check logs
ssh azure-prod "tail -100 /var/log/deploy.log"

# Manual deploy with verbose
ssh azure-prod "cd /var/www/app && bash -x ./deploy.sh"
```

**App not responding:**
```bash
# Check process
ssh azure-prod "pm2 status"
ssh azure-prod "docker compose ps"

# Check ports
ssh azure-prod "netstat -tlnp | grep 3000"
ssh azure-prod "ss -tlnp | grep 3000"

# Check firewall
ssh azure-prod "sudo ufw status"

# Test locally on server
ssh azure-prod "curl http://localhost:3000/health"
```

**Rollback:**
```bash
# Git rollback
ssh azure-prod << 'EOF'
cd /var/www/app
git log --oneline -5  # Find previous commit
git reset --hard HEAD~1
./deploy.sh
EOF

# Backup rollback
ssh azure-prod << 'EOF'
LATEST_BACKUP=$(ls -t /var/www/backups | head -1)
rm -rf /var/www/app
cp -r /var/www/backups/$LATEST_BACKUP /var/www/app
cd /var/www/app && ./deploy.sh
EOF
```
</troubleshooting>

<security>
## Security Best Practices

1. **Use SSH keys, not passwords** - Disable password auth in sshd_config
2. **Restrict SSH access** - Use NSG to allow only specific IPs
3. **Use deploy user** - Don't deploy as root
4. **Rotate keys regularly** - Update SSH keys quarterly
5. **Audit access** - Check `/var/log/auth.log` for SSH attempts
6. **Use Azure Bastion** - For private VMs without public IPs
7. **Enable MFA** - Azure AD MFA for az login
8. **Secrets in Key Vault** - Not in code or .env files in git
</security>
