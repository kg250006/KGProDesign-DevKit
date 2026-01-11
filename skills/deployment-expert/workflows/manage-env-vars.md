<required_reading>
Read references/env-vars.md for environment variable patterns.
Read the platform-specific reference for syncing variables.
</required_reading>

<process>
## Step 1: Understand Current State

Check what's configured:

```bash
# Profile configuration
REQUIRED=$(jq -r '.envVars.required[]' .deployment-profile.json 2>/dev/null)
OPTIONAL=$(jq -r '.envVars.optional[]' .deployment-profile.json 2>/dev/null)
SOURCE=$(jq -r '.envVars.source // ".env.production"' .deployment-profile.json)
PLATFORM=$(jq -r '.platform' .deployment-profile.json)

# Local env file
if [ -f "$SOURCE" ]; then
    LOCAL_VARS=$(grep -E "^[A-Z_]+=" "$SOURCE" | cut -d= -f1)
fi

# Platform vars (if accessible)
case $PLATFORM in
    netlify)
        PLATFORM_VARS=$(netlify env:list --json 2>/dev/null | jq -r '.[].key')
        ;;
esac
```

**Report to user:**
```
Environment Variable Status:

Required variables:
  - DATABASE_URL: ✓ Local, ✓ Platform
  - API_KEY: ✓ Local, ✗ Platform (needs sync)
  - JWT_SECRET: ✗ Local, ✗ Platform (missing)

Optional variables:
  - ANALYTICS_ID: ✓ Local, ✓ Platform

What would you like to do?
1. Add missing variables
2. Sync local to platform
3. Sync platform to local
4. View current values (masked)
5. Update specific variable
```

## Step 2: Handle User Choice

### Add Missing Variables

```
Missing variable: JWT_SECRET

This is typically a secret key for JWT token signing.
Common format: 64-character random string

Options:
1. Generate secure random value
2. Enter value manually
3. Skip for now
```

If generate:
```bash
JWT_SECRET=$(openssl rand -base64 48 | tr -d '\n')
echo "Generated JWT_SECRET (first 8 chars): ${JWT_SECRET:0:8}..."
```

Add to local file:
```bash
echo "JWT_SECRET=$JWT_SECRET" >> "$SOURCE"
```

### Sync Local to Platform

**Netlify:**
```bash
echo "Syncing to Netlify..."
while IFS='=' read -r key value; do
    [[ -z "$key" || "$key" =~ ^# ]] && continue
    value=$(echo "$value" | sed -e 's/^"//' -e 's/"$//')
    echo "  Setting $key..."
    netlify env:set "$key" "$value" --context production
done < "$SOURCE"
echo "Sync complete!"
```

**Azure VM:**
```bash
echo "Copying to server..."
scp "$SOURCE" "$USER@$HOST:/var/www/app/.env"
ssh "$USER@$HOST" "chmod 600 /var/www/app/.env"
echo "Sync complete!"
```

**FTP (limited - usually manual):**
```
FTP doesn't support environment variables directly.
For PHP applications, you'll need to:
1. Upload .env file via FTP
2. Or set variables in hosting control panel

Would you like me to upload the .env file?
```

### Sync Platform to Local

**Netlify:**
```bash
echo "Fetching from Netlify..."
netlify env:list --json | jq -r '.[] | "\(.key)=\(.value)"' > "$SOURCE.new"

echo "Variables fetched. Review before replacing:"
diff "$SOURCE" "$SOURCE.new" || true

echo "Replace local file? (y/n)"
```

### View Current Values (Masked)

```bash
echo "Current environment variables:"
echo ""
while IFS='=' read -r key value; do
    [[ -z "$key" || "$key" =~ ^# ]] && continue
    # Mask sensitive values
    if [[ "$key" =~ (SECRET|KEY|PASSWORD|TOKEN) ]]; then
        MASKED="${value:0:4}****${value: -4}"
    else
        MASKED="$value"
    fi
    echo "  $key=$MASKED"
done < "$SOURCE"
```

### Update Specific Variable

```
Which variable would you like to update?

Current variables:
1. DATABASE_URL
2. API_KEY
3. JWT_SECRET
4. Add new variable
```

After selection:
```bash
# Show current value (masked)
CURRENT=$(grep "^$VAR=" "$SOURCE" | cut -d= -f2-)
echo "Current value: ${CURRENT:0:4}****"

echo "Enter new value (or press Enter to keep current):"
read NEW_VALUE

if [ -n "$NEW_VALUE" ]; then
    sed -i "s|^$VAR=.*|$VAR=$NEW_VALUE|" "$SOURCE"
    echo "Updated $VAR in local file"

    echo "Sync to platform? (y/n)"
fi
```

## Step 3: Validate After Changes

```bash
# Re-check required variables
MISSING=()
for var in $REQUIRED; do
    if ! grep -q "^$var=" "$SOURCE"; then
        MISSING+=("$var")
    fi
done

if [ ${#MISSING[@]} -eq 0 ]; then
    echo "All required variables are set!"
else
    echo "Still missing: ${MISSING[*]}"
fi
```

## Step 4: Update Profile

If user added new required/optional variables:

```bash
jq '.envVars.required = ["DATABASE_URL", "API_KEY", "JWT_SECRET"]' \
   .deployment-profile.json > tmp.json && mv tmp.json .deployment-profile.json
```

## Step 5: Security Reminder

```
Reminder: Environment files contain sensitive data.

- .env.production is in .gitignore: ✓
- File permissions are restrictive: $(stat -c %a "$SOURCE")
- Secrets are not logged in deploy output

Ready to deploy with these variables?
```
</process>

<variable_templates>
## Common Variable Templates

**Database:**
```bash
DATABASE_URL=postgresql://user:password@host:5432/database
REDIS_URL=redis://localhost:6379
MONGODB_URI=mongodb://user:password@host:27017/database
```

**Authentication:**
```bash
JWT_SECRET=$(openssl rand -base64 48)
SESSION_SECRET=$(openssl rand -base64 32)
NEXTAUTH_SECRET=$(openssl rand -base64 32)
```

**External Services:**
```bash
STRIPE_SECRET_KEY=sk_live_...
SENDGRID_API_KEY=SG....
AWS_ACCESS_KEY_ID=AKIA...
AWS_SECRET_ACCESS_KEY=...
```

**Application:**
```bash
NODE_ENV=production
PORT=3000
LOG_LEVEL=info
API_URL=https://api.example.com
```
</variable_templates>

<success_criteria>
Environment variable management is complete when:
- [ ] All required variables have values
- [ ] Local and platform are in sync
- [ ] Sensitive values properly masked in output
- [ ] Profile updated with variable requirements
- [ ] User informed of any missing or changed variables
</success_criteria>
