<required_reading>
Read the platform-specific reference authentication section.
</required_reading>

<process>
## Step 1: Identify Platform

```
Which platform would you like to connect?

1. Netlify
2. Azure (VM deployment)
3. FTP/SFTP server
4. GitHub (for production branch deployment)
```

## Step 2: Platform-Specific Setup

### Netlify

**Option A: Interactive login (recommended for local dev):**
```bash
netlify login
```
This opens a browser for OAuth authentication.

**Option B: Token-based (for CI/CD or headless):**
```
To use a personal access token:

1. Go to https://app.netlify.com/user/applications
2. Click "New access token"
3. Give it a descriptive name (e.g., "CLI - MacBook")
4. Copy the token
```

Store the token securely:
```bash
mkdir -p ~/.deployment-expert
echo "YOUR_TOKEN_HERE" > ~/.deployment-expert/netlify-token
chmod 600 ~/.deployment-expert/netlify-token
```

Use in scripts:
```bash
export NETLIFY_AUTH_TOKEN=$(cat ~/.deployment-expert/netlify-token)
netlify deploy --prod
```

**Verify connection:**
```bash
netlify status
netlify sites:list
```

### Azure

**Option A: Interactive login:**
```bash
az login
```

**Option B: Service principal (for automation):**
```bash
# Create service principal
az ad sp create-for-rbac --name "deployment-sp" --role contributor \
    --scopes /subscriptions/{subscription-id}/resourceGroups/{resource-group}

# Store credentials
mkdir -p ~/.deployment-expert
cat > ~/.deployment-expert/azure-sp.json << 'EOF'
{
  "appId": "...",
  "password": "...",
  "tenant": "..."
}
EOF
chmod 600 ~/.deployment-expert/azure-sp.json
```

**SSH key setup for VM access:**
```bash
# Generate dedicated deploy key
ssh-keygen -t ed25519 -C "deploy@myproject" -f ~/.ssh/azure_deploy

# Add to VM
az vm user update \
    --resource-group myResourceGroup \
    --name myVM \
    --username deployuser \
    --ssh-key-value "$(cat ~/.ssh/azure_deploy.pub)"
```

**Verify connection:**
```bash
az account show
ssh -i ~/.ssh/azure_deploy deployuser@vm.azure.com "echo 'Connected!'"
```

### FTP/SFTP

**Gather credentials:**
```
I'll need the following information:

1. FTP hostname (e.g., ftp.example.com)
2. Username
3. Password (will be stored securely)
4. Protocol (FTP, FTPS, or SFTP)
5. Port (default: 21 for FTP, 22 for SFTP)
```

**Store credentials:**
```bash
mkdir -p ~/.deployment-expert
PROJECT_NAME=$(basename $PWD)

# Store password separately
echo "YOUR_PASSWORD" > ~/.deployment-expert/ftp-$PROJECT_NAME.pass
chmod 600 ~/.deployment-expert/ftp-$PROJECT_NAME.pass

# For SFTP with SSH key
ssh-keygen -t ed25519 -C "ftp-deploy" -f ~/.ssh/ftp_$PROJECT_NAME
```

**Test connection:**
```bash
# SFTP
sftp -i ~/.ssh/ftp_$PROJECT_NAME user@ftp.example.com << 'EOF'
pwd
ls
quit
EOF

# FTP
lftp -u user,$(cat ~/.deployment-expert/ftp-$PROJECT_NAME.pass) ftp://ftp.example.com << 'EOF'
pwd
ls
quit
EOF
```

### GitHub

**For push-based deployment, ensure:**
```bash
# Check remote is set
git remote -v

# Check you can push to production branch
git fetch origin production
git checkout production
git checkout -  # Back to previous branch

# Verify GitHub CLI is authenticated
gh auth status
```

**For webhook-based deployment:**
```
To set up a webhook:

1. Go to your repository Settings → Webhooks
2. Add webhook:
   - Payload URL: https://your-server.com:9000/deploy
   - Content type: application/json
   - Secret: [generate a secure secret]
   - Events: Just the push event
   - Active: ✓
```

Store webhook secret:
```bash
WEBHOOK_SECRET=$(openssl rand -hex 32)
echo "$WEBHOOK_SECRET" > ~/.deployment-expert/github-webhook-secret
chmod 600 ~/.deployment-expert/github-webhook-secret

echo "Add this secret to your GitHub webhook configuration:"
echo "$WEBHOOK_SECRET"
```

## Step 3: Update Global Config

```bash
# Create/update global deployment config
mkdir -p ~/.deployment-expert

cat > ~/.deployment-expert/config.json << 'EOF'
{
  "netlify": {
    "tokenPath": "~/.deployment-expert/netlify-token"
  },
  "azure": {
    "credentialsPath": "~/.deployment-expert/azure-sp.json",
    "defaultSubscription": "your-subscription-id"
  },
  "ssh": {
    "defaultKeyPath": "~/.ssh/id_ed25519"
  }
}
EOF
```

## Step 4: Test Full Workflow

```
Account connected! Would you like to:

1. Create a deployment profile for this project
2. Test a deploy now
3. View account details
4. Done for now
```

If test deploy:
→ Route to `workflows/setup-profile.md` then `workflows/deploy.md`
</process>

<security_best_practices>
## Security Best Practices

**Credential storage:**
- Use `chmod 600` for all credential files
- Store in `~/.deployment-expert/` (not in project)
- Never commit tokens/passwords to git
- Rotate credentials periodically

**SSH keys:**
- Use separate keys per service
- Use ed25519 algorithm (more secure, shorter)
- Add passphrase for extra security
- Audit authorized_keys on servers

**Tokens:**
- Use scoped tokens when possible
- Set expiration dates
- Revoke unused tokens

**Multi-factor auth:**
- Enable MFA on all platform accounts
- Use hardware keys for production access
</security_best_practices>

<success_criteria>
Account connection is complete when:
- [ ] Credentials obtained and stored securely
- [ ] Connection tested successfully
- [ ] Permissions verified (can deploy)
- [ ] Global config updated
- [ ] User informed of next steps
</success_criteria>
