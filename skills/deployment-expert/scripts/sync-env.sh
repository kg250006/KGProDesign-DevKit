#!/bin/bash
# Syncs environment variables from local file to deployment platform
# Usage: sync-env.sh [env-file] [--dry-run]

set -e

ENV_FILE=${1:-.env.production}
DRY_RUN=false

if [ "$2" = "--dry-run" ]; then
    DRY_RUN=true
fi

# Check profile exists
if [ ! -f ".deployment-profile.json" ]; then
    echo "Error: No deployment profile found"
    exit 1
fi

PLATFORM=$(jq -r '.platform' .deployment-profile.json)

echo "Syncing $ENV_FILE to $PLATFORM..."
if $DRY_RUN; then
    echo "(DRY RUN - no changes will be made)"
fi
echo ""

sync_netlify() {
    if ! command -v netlify &> /dev/null; then
        echo "Error: Netlify CLI not installed"
        exit 1
    fi

    while IFS='=' read -r key value; do
        # Skip comments and empty lines
        [[ -z "$key" || "$key" =~ ^# ]] && continue

        # Remove quotes from value
        value=$(echo "$value" | sed -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//")

        echo "  Setting $key..."
        if ! $DRY_RUN; then
            netlify env:set "$key" "$value" --context production 2>/dev/null || \
            netlify env:set "$key" "$value" 2>/dev/null
        fi
    done < "$ENV_FILE"
}

sync_azure_vm() {
    HOST=$(jq -r '.azureVm.host' .deployment-profile.json)
    USER=$(jq -r '.azureVm.user' .deployment-profile.json)
    KEY=$(jq -r '.azureVm.sshKeyPath' .deployment-profile.json)
    REMOTE_PATH=$(jq -r '.envVars.serverPath // (.azureVm.appPath + "/.env")' .deployment-profile.json)

    # Expand tilde in key path
    KEY="${KEY/#\~/$HOME}"

    echo "  Copying to $USER@$HOST:$REMOTE_PATH"

    if ! $DRY_RUN; then
        scp -i "$KEY" "$ENV_FILE" "$USER@$HOST:$REMOTE_PATH"
        ssh -i "$KEY" "$USER@$HOST" "chmod 600 $REMOTE_PATH"
    fi
}

sync_ftp() {
    HOST=$(jq -r '.ftp.host' .deployment-profile.json)
    USER=$(jq -r '.ftp.user' .deployment-profile.json)
    PROTOCOL=$(jq -r '.ftp.protocol // "sftp"' .deployment-profile.json)
    REMOTE_PATH=$(jq -r '.ftp.remotePath' .deployment-profile.json)

    # Get password
    PROJECT_NAME=$(basename "$PWD")
    PASS_FILE="$HOME/.deployment-expert/ftp-$PROJECT_NAME.pass"

    if [ ! -f "$PASS_FILE" ]; then
        echo "Error: Password file not found: $PASS_FILE"
        exit 1
    fi

    PASS=$(cat "$PASS_FILE")

    echo "  Uploading to $HOST:$REMOTE_PATH/.env"

    if ! $DRY_RUN; then
        lftp -u "$USER","$PASS" "$PROTOCOL://$HOST" << EOF
put "$ENV_FILE" -o "$REMOTE_PATH/.env"
quit
EOF
    fi
}

sync_github_production() {
    echo "  GitHub Production uses GitHub Secrets for environment variables."
    echo ""
    echo "  To sync, use GitHub CLI:"
    echo ""

    while IFS='=' read -r key value; do
        [[ -z "$key" || "$key" =~ ^# ]] && continue
        echo "    gh secret set $key"
    done < "$ENV_FILE"

    echo ""
    echo "  Or set manually at: https://github.com/{owner}/{repo}/settings/secrets/actions"
}

# Route to platform-specific sync
case $PLATFORM in
    netlify)
        sync_netlify
        ;;
    azure-vm)
        sync_azure_vm
        ;;
    ftp)
        sync_ftp
        ;;
    github-production)
        sync_github_production
        ;;
    *)
        echo "Error: Unknown platform: $PLATFORM"
        exit 1
        ;;
esac

echo ""
if $DRY_RUN; then
    echo "Dry run complete. Run without --dry-run to apply changes."
else
    echo "Sync complete!"
fi
