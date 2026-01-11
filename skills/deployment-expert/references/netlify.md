<overview>
Complete Netlify CLI expertise for deploying sites, managing environment variables, forms, functions, and build configurations. Covers authentication, site linking, production deploys, and troubleshooting.
</overview>

<cli_installation>
## Installing Netlify CLI

```bash
# Via npm (recommended)
npm install -g netlify-cli

# Via Homebrew (macOS)
brew install netlify-cli

# Verify installation
netlify --version
```
</cli_installation>

<authentication>
## Authentication

**Interactive login (browser-based):**
```bash
netlify login
```

**Token-based (CI/CD or headless):**
```bash
# Set token as environment variable
export NETLIFY_AUTH_TOKEN="your-token-here"

# Or pass directly
netlify deploy --auth $NETLIFY_AUTH_TOKEN
```

**Get personal access token:**
1. Go to https://app.netlify.com/user/applications
2. Create new personal access token
3. Store in `~/.deployment-expert/netlify-token` (chmod 600)

**Check auth status:**
```bash
netlify status
```
</authentication>

<site_management>
## Site Management

**Link existing site:**
```bash
# Interactive (prompts for site)
netlify link

# By site ID
netlify link --id site-id-here

# By site name
netlify link --name my-site-name
```

**Create new site:**
```bash
# Interactive
netlify sites:create

# With name
netlify sites:create --name my-new-site

# In specific team
netlify sites:create --name my-site --account-slug team-name
```

**List sites:**
```bash
netlify sites:list
netlify sites:list --json  # For parsing
```

**Get site info:**
```bash
netlify status
netlify api getSite --data '{"site_id": "site-id"}'
```
</site_management>

<deployment>
## Deployment Commands

**Production deploy:**
```bash
# Deploy from build output
netlify deploy --prod

# Specify directory
netlify deploy --prod --dir=dist

# With build command
netlify deploy --prod --build

# Open site after deploy
netlify deploy --prod --open
```

**Draft/preview deploy:**
```bash
# Create preview URL (not production)
netlify deploy

# Returns draft URL for testing
```

**Deploy specific directory:**
```bash
netlify deploy --prod --dir=build
netlify deploy --prod --dir=public
netlify deploy --prod --dir=.next  # Next.js
netlify deploy --prod --dir=out    # Static export
```

**Deploy with functions:**
```bash
netlify deploy --prod --functions=netlify/functions
```

**Deploy output:**
```
Deploying to main site URL...
✔ Finished hashing
✔ CDN requesting 12 files
✔ Finished uploading 12 assets
✔ Deploy is live!

Logs:              https://app.netlify.com/sites/my-site/deploys/abc123
Unique Deploy URL: https://abc123--my-site.netlify.app
Website URL:       https://my-site.netlify.app
```
</deployment>

<environment_variables>
## Environment Variables

**List all variables:**
```bash
netlify env:list
netlify env:list --json  # For parsing
```

**Set variable:**
```bash
# Single value
netlify env:set API_KEY "value-here"

# From file
netlify env:import .env.production
```

**Get specific variable:**
```bash
netlify env:get API_KEY
```

**Unset variable:**
```bash
netlify env:unset API_KEY
```

**Clone from another site:**
```bash
netlify env:clone --from site-id-source
```

**Scoped variables (deploy contexts):**
```bash
# Production only
netlify env:set API_KEY "prod-value" --context production

# Branch deploys
netlify env:set API_KEY "staging-value" --context branch-deploy

# Deploy previews
netlify env:set API_KEY "preview-value" --context deploy-preview
```

**Sync from .env.production:**
```bash
# Parse and set each variable
while IFS='=' read -r key value; do
  [[ -z "$key" || "$key" =~ ^# ]] && continue
  netlify env:set "$key" "$value"
done < .env.production
```
</environment_variables>

<netlify_forms>
## Netlify Forms

**Enable forms:**
Add `data-netlify="true"` to form HTML:
```html
<form name="contact" method="POST" data-netlify="true">
  <input type="text" name="name" />
  <input type="email" name="email" />
  <textarea name="message"></textarea>
  <button type="submit">Send</button>
</form>
```

**List form submissions:**
```bash
netlify forms:list
```

**Check forms are detected:**
After deploy, verify in CLI output:
```
Form detected: contact
Form detected: newsletter
```

**Spam filtering:**
Add honeypot field:
```html
<form name="contact" data-netlify="true" netlify-honeypot="bot-field">
  <input name="bot-field" style="display:none" />
  <!-- real fields -->
</form>
```

**Form notifications:**
Configure in `netlify.toml`:
```toml
[[plugins]]
  package = "@netlify/plugin-emails"

  [plugins.inputs]
    from = "noreply@example.com"
    to = "admin@example.com"
```
</netlify_forms>

<build_configuration>
## Build Configuration (netlify.toml)

**Basic config:**
```toml
[build]
  command = "npm run build"
  publish = "dist"

[build.environment]
  NODE_VERSION = "20"
  NPM_FLAGS = "--legacy-peer-deps"
```

**Framework-specific:**
```toml
# Next.js
[build]
  command = "npm run build"
  publish = ".next"

# Astro
[build]
  command = "npm run build"
  publish = "dist"

# Vite/React
[build]
  command = "npm run build"
  publish = "dist"
```

**Redirects:**
```toml
[[redirects]]
  from = "/api/*"
  to = "/.netlify/functions/:splat"
  status = 200

[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200
```

**Headers:**
```toml
[[headers]]
  for = "/*"
  [headers.values]
    X-Frame-Options = "DENY"
    X-Content-Type-Options = "nosniff"
```

**Branch deploys:**
```toml
[context.production]
  command = "npm run build"

[context.staging]
  command = "npm run build:staging"

[context.branch-deploy]
  command = "npm run build:preview"
```
</build_configuration>

<functions>
## Netlify Functions

**Create function:**
```bash
netlify functions:create hello-world
```

**List functions:**
```bash
netlify functions:list
```

**Invoke locally:**
```bash
netlify functions:invoke hello-world
netlify functions:invoke hello-world --payload '{"name": "test"}'
```

**Function structure:**
```javascript
// netlify/functions/hello-world.js
exports.handler = async (event, context) => {
  return {
    statusCode: 200,
    body: JSON.stringify({ message: "Hello World" })
  };
};
```

**TypeScript function:**
```typescript
// netlify/functions/hello-world.ts
import { Handler } from '@netlify/functions';

export const handler: Handler = async (event, context) => {
  return {
    statusCode: 200,
    body: JSON.stringify({ message: "Hello World" })
  };
};
```
</functions>

<local_development>
## Local Development

**Start dev server:**
```bash
netlify dev

# With specific port
netlify dev --port 3000

# Live reload
netlify dev --live
```

**Dev server features:**
- Automatic HTTPS
- Environment variables loaded
- Functions available at `/.netlify/functions/`
- Redirects applied
- Forms detection

**Link to specific site for env vars:**
```bash
netlify link
netlify dev  # Now uses site's env vars
```
</local_development>

<troubleshooting>
## Troubleshooting

**Build fails:**
```bash
# Check build logs
netlify deploy --build 2>&1 | tee build.log

# Common issues:
# - Node version mismatch: Add NODE_VERSION to netlify.toml
# - Missing dependencies: Check package.json
# - Build command wrong: Verify in netlify.toml
```

**Deploy fails:**
```bash
# Check status
netlify status

# View deploy logs
netlify open:admin  # Opens Netlify dashboard

# Retry
netlify deploy --prod
```

**Forms not working:**
- Verify `data-netlify="true"` on form
- Check form has `name` attribute
- Ensure form renders in static HTML (not client-only)
- Check Forms tab in Netlify dashboard

**Environment variables not loading:**
```bash
# Verify they exist
netlify env:list

# Check context (production vs preview)
netlify env:get VAR_NAME

# Rebuild after adding vars
netlify deploy --prod --build
```

**Clear cache and redeploy:**
```bash
# In dashboard: Deploys > Trigger deploy > Clear cache and deploy site
# Or via CLI:
netlify build --context production
netlify deploy --prod
```
</troubleshooting>

<verification>
## Post-Deploy Verification

```bash
# Check site is live
curl -I https://my-site.netlify.app

# Verify specific page
curl -s https://my-site.netlify.app | head -20

# Check headers
curl -I https://my-site.netlify.app 2>&1 | grep -E "HTTP|x-"

# Test API endpoint
curl https://my-site.netlify.app/api/health

# Check forms endpoint
curl -X POST https://my-site.netlify.app/ \
  -F "form-name=contact" \
  -F "name=Test" \
  -F "email=test@test.com"
```
</verification>

<best_practices>
## Best Practices

1. **Always use `netlify.toml`** - Version control your build config
2. **Set NODE_VERSION** - Avoid build inconsistencies
3. **Use draft deploys first** - Test before production
4. **Scope sensitive env vars** - Production-only for secrets
5. **Enable form spam protection** - Use honeypot fields
6. **Set up deploy notifications** - Slack/email on success/failure
7. **Use branch deploys** - Staging branch for QA
8. **Lock production deploys** - Require team approval for prod
</best_practices>
