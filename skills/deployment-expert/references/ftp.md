<overview>
FTP and SFTP deployment for PHP applications, static websites, and legacy hosting environments. Covers connection setup, file synchronization, and automation scripts.
</overview>

<when_to_use>
## When to Use FTP Deployment

**Appropriate for:**
- Traditional shared hosting (GoDaddy, Bluehost, HostGator)
- PHP applications without SSH access
- Static websites on basic hosting
- Client sites on their existing hosting
- WordPress and similar CMS deployments

**Consider alternatives when:**
- You have SSH access (use rsync instead)
- Modern hosting available (use Netlify, Vercel)
- Need atomic deploys (FTP is not atomic)
- Large number of files (FTP is slow)
</when_to_use>

<prerequisites>
## Prerequisites

**CLI tools:**
```bash
# lftp (recommended - best for scripted deploys)
brew install lftp  # macOS
apt install lftp   # Ubuntu/Debian

# ncftp (alternative)
brew install ncftp

# Standard ftp (usually pre-installed)
ftp --version

# SFTP (SSH-based, more secure)
sftp --version  # Part of OpenSSH
```

**Connection details needed:**
- FTP host (ftp.example.com)
- Username
- Password (or SSH key for SFTP)
- Remote path (/public_html, /var/www, etc.)
- Protocol (FTP, FTPS, or SFTP)
</prerequisites>

<credentials_setup>
## Credentials Setup

**Secure storage:**
```bash
# Create config directory
mkdir -p ~/.deployment-expert
chmod 700 ~/.deployment-expert

# Store FTP credentials
cat > ~/.deployment-expert/ftp-credentials.json << 'EOF'
{
  "sites": {
    "client-site": {
      "host": "ftp.example.com",
      "user": "username",
      "protocol": "sftp",
      "remotePath": "/public_html"
    }
  }
}
EOF
chmod 600 ~/.deployment-expert/ftp-credentials.json

# Password in separate file (never in JSON)
echo "password-here" > ~/.deployment-expert/ftp-client-site.pass
chmod 600 ~/.deployment-expert/ftp-client-site.pass
```

**For SFTP with SSH keys:**
```bash
# Generate key
ssh-keygen -t ed25519 -f ~/.ssh/ftp_deploy -C "deploy@project"

# Copy to server (if SSH access available)
ssh-copy-id -i ~/.ssh/ftp_deploy.pub user@ftp.example.com

# Or provide public key to hosting provider
cat ~/.ssh/ftp_deploy.pub
```

**.netrc file (for automatic login):**
```bash
# ~/.netrc
machine ftp.example.com
login username
password secretpassword

# Secure permissions (required)
chmod 600 ~/.netrc
```
</credentials_setup>

<lftp_deployment>
## lftp Deployment (Recommended)

**Basic mirror (upload):**
```bash
lftp -u user,password ftp.example.com << 'EOF'
mirror -R ./dist /public_html
quit
EOF
```

**SFTP connection:**
```bash
lftp -u user sftp://ftp.example.com << 'EOF'
mirror -R ./dist /public_html
quit
EOF
```

**Full deploy script:**
```bash
#!/bin/bash
set -e

# Configuration
HOST="ftp.example.com"
USER="ftpuser"
REMOTE_PATH="/public_html"
LOCAL_PATH="./dist"
PASS=$(cat ~/.deployment-expert/ftp-site.pass)

echo "Building project..."
npm run build

echo "Deploying to $HOST..."
lftp -u "$USER","$PASS" "sftp://$HOST" << EOF
set ssl:verify-certificate no
set ftp:ssl-allow yes
set mirror:use-pget-n 5
mirror -R --verbose --delete --parallel=5 "$LOCAL_PATH" "$REMOTE_PATH"
quit
EOF

echo "Deployment complete!"
```

**lftp options explained:**
```bash
mirror -R              # Reverse mirror (upload)
       --delete        # Delete remote files not in local
       --verbose       # Show progress
       --parallel=5    # Upload 5 files simultaneously
       --exclude .git  # Exclude patterns
       --only-newer    # Only upload changed files
```

**Exclude files:**
```bash
lftp << 'EOF'
mirror -R --verbose \
  --exclude .git \
  --exclude .gitignore \
  --exclude node_modules \
  --exclude .env \
  --exclude .env.local \
  --exclude "*.log" \
  ./dist /public_html
EOF
```
</lftp_deployment>

<ncftp_deployment>
## ncftp Deployment

**Interactive session:**
```bash
ncftp -u user -p pass ftp.example.com
# Then: cd /public_html
# Then: put -R ./dist/*
```

**Scripted upload:**
```bash
ncftpput -R -v -u user -p pass ftp.example.com /public_html ./dist/*
```

**ncftpput options:**
```bash
-R           # Recursive
-v           # Verbose
-m           # Mirror (delete remote files not in local)
-f file      # Read credentials from file
```

**Bookmark for repeated access:**
```bash
# Save bookmark
ncftp -u user ftp.example.com
# In ncftp: bookmark save mysite

# Use bookmark
ncftp mysite
```
</ncftp_deployment>

<sftp_deployment>
## SFTP Deployment (SSH-based)

**Interactive:**
```bash
sftp user@ftp.example.com
# sftp> cd /public_html
# sftp> put -r ./dist/*
```

**Batch mode:**
```bash
sftp -b - user@ftp.example.com << 'EOF'
cd /public_html
put -r dist/*
EOF
```

**With SSH key:**
```bash
sftp -i ~/.ssh/ftp_deploy user@ftp.example.com << 'EOF'
cd /public_html
put -r dist/*
EOF
```

**rsync over SSH (best for SFTP):**
```bash
rsync -avz --delete ./dist/ user@ftp.example.com:/public_html/
```
</sftp_deployment>

<php_deployment>
## PHP Application Deployment

**Complete PHP deploy script:**
```bash
#!/bin/bash
set -e

HOST="ftp.example.com"
USER="ftpuser"
REMOTE_PATH="/public_html"
PASS=$(cat ~/.deployment-expert/ftp-site.pass)

echo "Preparing files..."
# Exclude dev files
rsync -av --delete \
  --exclude 'node_modules' \
  --exclude '.git' \
  --exclude 'tests' \
  --exclude '.env' \
  --exclude 'composer.lock' \
  ./ ./deploy-staging/

echo "Uploading to server..."
lftp -u "$USER","$PASS" "ftp://$HOST" << EOF
mirror -R --verbose --delete \
  --exclude .htaccess.local \
  --parallel=5 \
  ./deploy-staging $REMOTE_PATH
quit
EOF

echo "Running remote commands..."
# If you have SSH access
ssh user@host << 'REMOTE'
cd /public_html
composer install --no-dev --optimize-autoloader
php artisan migrate --force
php artisan config:cache
php artisan route:cache
REMOTE

rm -rf ./deploy-staging
echo "Done!"
```

**WordPress deployment:**
```bash
#!/bin/bash
# Deploy wp-content only (core files managed by WP)

lftp -u "$USER","$PASS" "ftp://$HOST" << EOF
mirror -R --verbose --delete \
  --exclude uploads \
  --exclude cache \
  --exclude upgrade \
  ./wp-content /public_html/wp-content
quit
EOF
```
</php_deployment>

<static_site_deployment>
## Static Site Deployment

**Simple HTML/CSS/JS:**
```bash
#!/bin/bash
# Deploy static site build output

BUILD_DIR="./dist"
REMOTE_PATH="/public_html"

# Build first
npm run build

# Deploy
lftp -u "$USER","$PASS" "ftp://$HOST" << EOF
mirror -R --verbose --delete "$BUILD_DIR" "$REMOTE_PATH"
quit
EOF

echo "Site deployed to https://example.com"
```

**With index.html fallback (.htaccess):**
```apache
# .htaccess for SPA routing
<IfModule mod_rewrite.c>
  RewriteEngine On
  RewriteBase /
  RewriteRule ^index\.html$ - [L]
  RewriteCond %{REQUEST_FILENAME} !-f
  RewriteCond %{REQUEST_FILENAME} !-d
  RewriteRule . /index.html [L]
</IfModule>
```
</static_site_deployment>

<automation>
## Automation and CI/CD

**GitHub Actions example:**
```yaml
name: Deploy via FTP
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: Install and Build
        run: |
          npm ci
          npm run build

      - name: Deploy via FTP
        uses: SamKirkland/FTP-Deploy-Action@4.3.0
        with:
          server: ${{ secrets.FTP_HOST }}
          username: ${{ secrets.FTP_USER }}
          password: ${{ secrets.FTP_PASS }}
          local-dir: ./dist/
          server-dir: /public_html/
```

**Local deploy script with profile:**
```bash
#!/bin/bash
# deploy-ftp.sh - reads from .deployment-profile.json

PROFILE=".deployment-profile.json"

if [ ! -f "$PROFILE" ]; then
    echo "No deployment profile found"
    exit 1
fi

HOST=$(jq -r '.ftp.host' $PROFILE)
USER=$(jq -r '.ftp.user' $PROFILE)
REMOTE=$(jq -r '.ftp.remotePath' $PROFILE)
LOCAL=$(jq -r '.build.output' $PROFILE)
PASS=$(cat ~/.deployment-expert/ftp-$(basename $PWD).pass)

echo "Deploying to $HOST:$REMOTE..."
lftp -u "$USER","$PASS" "sftp://$HOST" << EOF
mirror -R --verbose --delete "$LOCAL" "$REMOTE"
quit
EOF
```
</automation>

<troubleshooting>
## Troubleshooting

**Connection refused:**
```bash
# Test basic connectivity
telnet ftp.example.com 21  # FTP
telnet ftp.example.com 22  # SFTP

# Check if passive mode needed
lftp -e "set ftp:passive-mode on" ftp://...
```

**Authentication failed:**
```bash
# Verify credentials
ftp ftp.example.com  # Interactive test

# Check for special characters in password
# May need URL encoding or quotes
```

**Permission denied:**
```bash
# Check remote directory permissions
# Via FTP:
ls -la /public_html

# May need to contact hosting provider
```

**SSL/TLS errors:**
```bash
# For self-signed certs
lftp -e "set ssl:verify-certificate no" ...

# For FTPS (explicit)
lftp ftps://ftp.example.com

# For FTPS (implicit, port 990)
lftp ftps://ftp.example.com:990
```

**Timeout errors:**
```bash
# Increase timeout
lftp -e "set net:timeout 60; set net:max-retries 3" ...
```

**Files not updated:**
```bash
# Force overwrite
lftp -e "set mirror:overwrite on" ...

# Check timestamps
# Some servers use different timezones
```
</troubleshooting>

<best_practices>
## Best Practices

1. **Use SFTP over FTP** - Encrypted, more reliable
2. **Never store passwords in scripts** - Use separate credential files
3. **Exclude sensitive files** - .env, config files with secrets
4. **Use --delete carefully** - Can remove server files permanently
5. **Test with --dry-run first** - lftp supports `--dry-run`
6. **Keep backups** - FTP has no rollback
7. **Deploy during low traffic** - FTP isn't atomic
8. **Use .htaccess for maintenance** - Show maintenance page during deploy
9. **Verify after deploy** - curl the site to confirm it works
</best_practices>

<maintenance_mode>
## Maintenance Mode During Deploy

**maintenance.html:**
```html
<!DOCTYPE html>
<html>
<head><title>Maintenance</title></head>
<body>
<h1>Site Under Maintenance</h1>
<p>We'll be back shortly.</p>
</body>
</html>
```

**Enable maintenance (.htaccess):**
```apache
RewriteEngine On
RewriteCond %{REMOTE_ADDR} !^123\.456\.789\.000  # Your IP
RewriteCond %{REQUEST_URI} !maintenance.html
RewriteRule .* /maintenance.html [R=302,L]
```

**Deploy script with maintenance:**
```bash
#!/bin/bash

echo "Enabling maintenance mode..."
lftp << 'EOF'
put .htaccess-maintenance /public_html/.htaccess
EOF

echo "Uploading files..."
lftp << 'EOF'
mirror -R ./dist /public_html
EOF

echo "Disabling maintenance mode..."
lftp << 'EOF'
put .htaccess-normal /public_html/.htaccess
EOF

echo "Done!"
```
</maintenance_mode>
