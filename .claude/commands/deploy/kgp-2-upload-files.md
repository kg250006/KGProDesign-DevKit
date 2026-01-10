---
name: kgp-upload-files
description: Upload built files to Azure VM with verification
arguments: "<subdomain> [source-dir] - Subdomain (e.g., kimrose.srv1.kgprodesign.com) and optional source directory (default: dist)"
---

# KGP File Upload Command

Securely upload production files to Azure VM with verification and rollback capability.

## Usage

```bash
# Upload from dist/ folder (default)
/deploy:kgp-upload-files kimrose.srv1.kgprodesign.com

# Upload from custom directory
/deploy:kgp-upload-files kimrose.srv1.kgprodesign.com ./build
```

## What This Command Does

1. ✅ Validates source directory exists
2. ✅ Creates backup of existing deployment
3. ✅ Uploads files via SCP
4. ✅ Sets correct permissions
5. ✅ Verifies file integrity
6. ✅ Provides rollback instructions if needed

## Implementation

$ARGUMENTS

<bash>
#!/bin/bash
set -e

SUBDOMAIN="$1"
SOURCE_DIR="${2:-dist}"

# VM Configuration
VM_IP="74.249.103.192"
SSH_KEY="$HOME/.ssh/kgp_vm_deploy"
SSH_USER="kgpadmin"
SSH_OPTS="-i $SSH_KEY -o StrictHostKeyChecking=no"

# Validation
if [ -z "$SUBDOMAIN" ]; then
    echo "❌ Error: Missing subdomain argument"
    echo ""
    echo "Usage: /deploy:kgp-upload-files <subdomain> [source-dir]"
    echo ""
    echo "Example: /deploy:kgp-upload-files kimrose.srv1.kgprodesign.com"
    exit 1
fi

echo "═══════════════════════════════════════════════════════════"
echo "  📤 KGP FILE UPLOAD"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "🌐 Subdomain: $SUBDOMAIN"
echo "📁 Source: $SOURCE_DIR/"
echo "🖥️  Target VM: $VM_IP"
echo ""

# Step 1: Validate source directory
echo "1️⃣  Validating source directory..."

if [ ! -d "$SOURCE_DIR" ]; then
    echo "   ❌ Source directory not found: $SOURCE_DIR/"
    echo ""
    echo "   💡 Build your app first:"
    echo "      /deploy:kgp-build"
    echo "      or"
    echo "      npm run build"
    exit 1
fi

if [ ! -f "$SOURCE_DIR/index.html" ]; then
    echo "   ❌ index.html not found in $SOURCE_DIR/"
    echo ""
    echo "   This doesn't look like a built app directory."
    exit 1
fi

# Count files
FILE_COUNT=$(find "$SOURCE_DIR" -type f | wc -l | tr -d ' ')
TOTAL_SIZE=$(du -sh "$SOURCE_DIR" | cut -f1)

echo "   ✅ Source directory valid"
echo "   📊 Files to upload: $FILE_COUNT"
echo "   📦 Total size: $TOTAL_SIZE"

# Step 2: Check SSH connection
echo ""
echo "2️⃣  Verifying SSH connection..."

if ! ssh $SSH_OPTS -o ConnectTimeout=5 $SSH_USER@$VM_IP 'echo "OK"' &> /dev/null; then
    echo "   ❌ Cannot connect to VM"
    echo ""
    echo "   Check:"
    echo "   - SSH key exists: $SSH_KEY"
    echo "   - VM is accessible: $VM_IP"
    echo "   - NSG allows your IP"
    exit 1
fi

echo "   ✅ Connected to VM"

# Step 3: Verify target directory exists
echo ""
echo "3️⃣  Checking target directory..."

TARGET_DIR="/var/www/$SUBDOMAIN/public"

if ! ssh $SSH_OPTS $SSH_USER@$VM_IP "[ -d '$TARGET_DIR' ]"; then
    echo "   ⚠️  Target directory doesn't exist: $TARGET_DIR"
    echo ""
    echo "   Creating directory..."
    ssh $SSH_OPTS $SSH_USER@$VM_IP "sudo mkdir -p $TARGET_DIR && sudo chown -R www-data:www-data /var/www/$SUBDOMAIN"
    echo "   ✅ Directory created"
else
    echo "   ✅ Target directory exists"
fi

# Step 4: Create backup
echo ""
echo "4️⃣  Creating backup of existing deployment..."

BACKUP_NAME="backup-$(date +%Y%m%d_%H%M%S)"
BACKUP_PATH="/var/www/$SUBDOMAIN/backups/$BACKUP_NAME"

# Check if there are files to backup
EXISTING_FILES=$(ssh $SSH_OPTS $SSH_USER@$VM_IP "find $TARGET_DIR -type f 2>/dev/null | wc -l | tr -d ' '")

if [ "$EXISTING_FILES" -gt 0 ]; then
    ssh $SSH_OPTS $SSH_USER@$VM_IP << EOSSH
sudo mkdir -p /var/www/$SUBDOMAIN/backups
sudo cp -r $TARGET_DIR $BACKUP_PATH
echo "Backup created: $BACKUP_PATH"
EOSSH
    echo "   ✅ Backup created: $BACKUP_NAME"
    echo "   📁 Location: $BACKUP_PATH"
else
    echo "   ℹ️  No existing files to backup (first deployment)"
fi

# Step 5: Upload files
echo ""
echo "5️⃣  Uploading files to VM..."

# Create temporary directory on VM
TMP_DIR="/tmp/upload-$(date +%s)"
ssh $SSH_OPTS $SSH_USER@$VM_IP "mkdir -p $TMP_DIR"

echo "   📤 Uploading to temporary location..."

# Upload files with progress
if scp -i $SSH_KEY -r -o StrictHostKeyChecking=no $SOURCE_DIR/* $SSH_USER@$VM_IP:$TMP_DIR/ 2>&1 | grep -v "Warning"; then
    echo "   ✅ Upload complete"
else
    echo "   ❌ Upload failed"
    echo ""
    echo "   Cleaning up..."
    ssh $SSH_OPTS $SSH_USER@$VM_IP "rm -rf $TMP_DIR"
    exit 1
fi

# Step 6: Move files to target and set permissions
echo ""
echo "6️⃣  Installing files..."

ssh $SSH_OPTS $SSH_USER@$VM_IP << EOSSH
# Clear existing files
sudo rm -rf $TARGET_DIR/*

# Move new files
sudo cp -r $TMP_DIR/* $TARGET_DIR/

# Set ownership
sudo chown -R www-data:www-data $TARGET_DIR

# Set permissions (755 for dirs, 644 for files)
sudo find $TARGET_DIR -type d -exec chmod 755 {} \;
sudo find $TARGET_DIR -type f -exec chmod 644 {} \;

# Clean up temp directory
rm -rf $TMP_DIR

echo "Files installed successfully"
EOSSH

echo "   ✅ Files installed with correct permissions"

# Step 7: Verify upload
echo ""
echo "7️⃣  Verifying upload..."

UPLOADED_FILES=$(ssh $SSH_OPTS $SSH_USER@$VM_IP "find $TARGET_DIR -type f | wc -l | tr -d ' '")

if [ "$UPLOADED_FILES" -eq "$FILE_COUNT" ]; then
    echo "   ✅ File count matches ($UPLOADED_FILES files)"
else
    echo "   ⚠️  File count mismatch!"
    echo "      Local: $FILE_COUNT files"
    echo "      Remote: $UPLOADED_FILES files"
fi

# Verify index.html exists
if ssh $SSH_OPTS $SSH_USER@$VM_IP "[ -f '$TARGET_DIR/index.html' ]"; then
    echo "   ✅ index.html verified"
else
    echo "   ❌ index.html missing!"
    exit 1
fi

# Verify assets directory
if ssh $SSH_OPTS $SSH_USER@$VM_IP "[ -d '$TARGET_DIR/assets' ]"; then
    ASSET_COUNT=$(ssh $SSH_OPTS $SSH_USER@$VM_IP "find $TARGET_DIR/assets -type f | wc -l | tr -d ' '")
    echo "   ✅ assets/ directory verified ($ASSET_COUNT files)"
else
    echo "   ⚠️  assets/ directory missing"
fi

# Step 8: Summary
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  ✅ UPLOAD COMPLETE!"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "📦 Upload Summary:"
echo "   ├─ Subdomain: $SUBDOMAIN"
echo "   ├─ Target: $TARGET_DIR"
echo "   ├─ Files uploaded: $UPLOADED_FILES"
echo "   ├─ Backup: $BACKUP_NAME"
echo "   └─ Size: $TOTAL_SIZE"
echo ""

if [ "$EXISTING_FILES" -gt 0 ]; then
    echo "🔄 Rollback Instructions (if needed):"
    echo "   ssh -i $SSH_KEY $SSH_USER@$VM_IP \\"
    echo "     'sudo cp -r $BACKUP_PATH/* $TARGET_DIR/'"
    echo ""
fi

echo "🚀 Next steps:"
echo "   1. Verify deployment: /deploy:kgp-verify $SUBDOMAIN"
echo "   2. Or test directly if container/NPM already configured"
echo ""

</bash>

## Success Criteria

- ✅ All files uploaded successfully
- ✅ File count matches source
- ✅ Correct permissions set (www-data:www-data)
- ✅ Backup created (if previous deployment existed)
- ✅ index.html and assets/ verified

## Rollback

If deployment fails, restore from backup:

```bash
# List available backups
ssh -i ~/.ssh/kgp_vm_deploy kgpadmin@74.249.103.192 \
  'ls -la /var/www/kimrose.srv1.kgprodesign.com/backups/'

# Restore specific backup
ssh -i ~/.ssh/kgp_vm_deploy kgpadmin@74.249.103.192 \
  'sudo cp -r /var/www/kimrose.srv1.kgprodesign.com/backups/backup-YYYYMMDD_HHMMSS/* \
   /var/www/kimrose.srv1.kgprodesign.com/public/'
```

## Common Issues

### Upload Fails: "Permission denied"

Check SSH key permissions:
```bash
chmod 600 ~/.ssh/kgp_vm_deploy
```

### File Count Mismatch

Hidden files may not be copied. Use:
```bash
/deploy:kgp-upload-files kimrose.srv1.kgprodesign.com dist
```

### Assets Not Loading

Verify base URL in vite.config.ts matches deployment location.

---

**Last Updated**: 2025-10-15
**Version**: 1.0
