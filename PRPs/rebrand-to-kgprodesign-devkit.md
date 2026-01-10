# PRP: Rebrand Plugin to KGProDesign-DevKit

## Goal

Rebrand the Claude Code plugin from "StartGuides-STAC-DevTool" to "KGProDesign-DevKit" with version 1.0. This is a comprehensive rebranding effort that updates all metadata, documentation, and command descriptions to reflect the new brand identity as a universal development toolkit.

## Why

- **Ownership & Identity**: Establish KGProDesign-DevKit as a personal/universal development toolkit owned by the user
- **Universality**: Position the plugin as applicable to any platform or project (not tied to a specific organization)
- **Clarity**: Remove references to "StartGuides" organization and "STAC Development Team"
- **Consistency**: Ensure all files, metadata, and references align with the new brand

## What

### User-visible behavior changes:
- Plugin name displays as "KGProDesign-DevKit" or "KGP" in all contexts
- All documentation references the new repository URL
- Command descriptions show `[KGP]` prefix instead of `[STAC]`
- All brand messaging emphasizes universal applicability

### Technical requirements:
- Update plugin.json and marketplace.json metadata
- Update all markdown documentation files
- Replace `[STAC]` with `[KGP]` in command descriptions
- Update git repository URL to: https://github.com/kg250006/KGProDesign-DevKit.git

### Success Criteria

- [ ] plugin.json reflects new name, version 1.0, and correct repository URL
- [ ] marketplace.json reflects new brand identity
- [ ] CLAUDE.md fully rebranded with KGProDesign-DevKit references
- [ ] README.md fully rebranded with new installation instructions
- [ ] QUICKSTART.md fully rebranded
- [ ] VERSION_MANIFEST.md reflects new version and branding
- [ ] All 9 command files with `[STAC]` changed to `[KGP]`
- [ ] No remaining references to "StartGuides", "STAC Development Team", or old repo URLs

---

## All Needed Context

### Documentation & References

```yaml
# Official Anthropic Plugin Structure
- url: https://github.com/anthropics/claude-code/blob/main/plugins/README.md
  why: Standard plugin directory structure and plugin.json schema

# Plugin Best Practices
- url: https://code.claude.com/docs/en/plugins
  why: Official documentation for creating Claude Code plugins

# Current Plugin Files to Modify
- file: .claude-plugin/plugin.json
  why: Core metadata file - name, version, repository URL, author

- file: .claude-plugin/marketplace.json
  why: Marketplace metadata - name, owner, description, visibility

- file: CLAUDE.md
  why: Main reference guide - extensive brand references throughout

- file: README.md
  why: Installation guide - repo URLs, brand name, installation paths

- file: QUICKSTART.md
  why: Quick start guide - repo URLs, brand references

- file: VERSION_MANIFEST.md
  why: Version tracking - author, version, changelog
```

### Current Codebase Tree (relevant files)

```
KGProDesign-DevKit/
├── .claude-plugin/
│   ├── plugin.json              # MODIFY: name, version, repository, author
│   └── marketplace.json         # MODIFY: name, owner, description
├── commands/
│   ├── dev/
│   │   ├── prp-create.md        # MODIFY: [STAC] -> [KGP]
│   │   ├── prp-execute.md       # MODIFY: [STAC] -> [KGP]
│   │   └── prp-validate.md      # MODIFY: [STAC] -> [KGP]
│   └── toolkit/
│       ├── create-agent-skill.md    # MODIFY: [STAC] -> [KGP]
│       ├── create-hook.md           # MODIFY: [STAC] -> [KGP]
│       ├── create-meta-prompt.md    # MODIFY: [STAC] -> [KGP]
│       ├── create-plan.md           # MODIFY: [STAC] -> [KGP]
│       ├── create-slash-command.md  # MODIFY: [STAC] -> [KGP]
│       └── create-subagent.md       # MODIFY: [STAC] -> [KGP]
├── CLAUDE.md                    # MODIFY: Full rebrand
├── README.md                    # MODIFY: Full rebrand
├── QUICKSTART.md                # MODIFY: Full rebrand
└── VERSION_MANIFEST.md          # MODIFY: Full rebrand
```

### Brand Mapping Reference

| Old Value | New Value |
|-----------|-----------|
| `StartGuides-STAC-DevTool` | `KGProDesign-DevKit` |
| `STAC` (as name) | `KGP` |
| `[STAC]` (command prefix) | `[KGP]` |
| `STAC Development Team` | `KGProDesign` |
| `stac-dev@startguides.com` | Remove or leave blank |
| `https://github.com/StartGuides/StartGuides-STAC-DevTool.git` | `https://github.com/kg250006/KGProDesign-DevKit.git` |
| `https://github.com/StartGuides-Forge/StartGuides-STAC-DevTool` | `https://github.com/kg250006/KGProDesign-DevKit` |
| `~/.claude/plugins/StartGuides-STAC-DevTool/` | `~/.claude/plugins/KGProDesign-DevKit/` |
| `Built for STAC engineering teams` | `Universal development toolkit for any project` |
| `STAC AI engineers` | `developers` |
| `StartGuides GitHub organization` | `your GitHub account` |
| `#startguides-stac-devtool` | Remove or generalize |

### Known Gotchas

```yaml
# CRITICAL: Plugin name in plugin.json should be short for display
# Use "KGP" as the short name, "KGProDesign-DevKit" as full name in descriptions

# CRITICAL: Version should be "1.0.0" (semver format)

# CRITICAL: Remove SSO authentication references - this is now a personal/public repo

# CRITICAL: Update install paths in all examples to use KGProDesign-DevKit

# CRITICAL: The agents/ directory files have no brand references - no changes needed there

# CRITICAL: The .claude/ directory (internal commands/agents) has no brand references - no changes needed
```

---

## Implementation Blueprint

### Task 1: Update .claude-plugin/plugin.json

**File:** `.claude-plugin/plugin.json`

**Current content to replace:**
```json
{
  "name": "STAC",
  "description": "Unified Claude Code plugin for STAC development team - 8 streamlined agents, 23 essential commands, and PRP workflow integration",
  "version": "1.0.0",
  "author": {
    "name": "STAC Development Team",
    "email": "stac-dev@startguides.com"
  },
  "homepage": "https://github.com/StartGuides-Forge/StartGuides-STAC-DevTool",
  "repository": "https://github.com/StartGuides-Forge/StartGuides-STAC-DevTool",
  ...
}
```

**New content:**
```json
{
  "name": "KGP",
  "description": "Universal Claude Code development toolkit - 8 streamlined agents, 23 essential commands, and PRP workflow integration for any project",
  "version": "1.0.0",
  "author": {
    "name": "KGProDesign"
  },
  "homepage": "https://github.com/kg250006/KGProDesign-DevKit",
  "repository": "https://github.com/kg250006/KGProDesign-DevKit",
  "license": "MIT",
  "keywords": [
    "agents",
    "development",
    "full-stack",
    "devops",
    "qa",
    "documentation",
    "project-management",
    "prp",
    "meta-prompting",
    "universal"
  ]
}
```

### Task 2: Update .claude-plugin/marketplace.json

**File:** `.claude-plugin/marketplace.json`

**New content:**
```json
{
  "name": "KGP",
  "owner": {
    "name": "KGProDesign"
  },
  "metadata": {
    "description": "Universal development toolkit for any project - streamlined from 40 agents to 8, 59 commands to 23",
    "version": "1.0.0",
    "category": "development",
    "visibility": "public"
  },
  "plugins": [
    {
      "name": "KGP",
      "source": "./",
      "description": "8 core agents covering frontend, backend, data, QA, project management, documentation, and DevOps",
      "version": "1.0.0",
      "strict": true
    }
  ]
}
```

### Task 3: Update command files with [STAC] -> [KGP]

**Files to update (9 total):**
1. `commands/dev/prp-create.md` - Line 2
2. `commands/dev/prp-execute.md` - Line 2
3. `commands/dev/prp-validate.md` - Line 2
4. `commands/toolkit/create-agent-skill.md` - Line 2
5. `commands/toolkit/create-hook.md` - Line 2
6. `commands/toolkit/create-meta-prompt.md` - Line 2
7. `commands/toolkit/create-plan.md` - Line 2
8. `commands/toolkit/create-slash-command.md` - Line 2
9. `commands/toolkit/create-subagent.md` - Line 2

**Pattern:** Replace `[STAC]` with `[KGP]` in the description field of each file's YAML frontmatter.

### Task 4: Update CLAUDE.md

**File:** `CLAUDE.md`

**Replacements:**
1. Line 1: `# CLAUDE.md - StartGuides-STAC-DevTool Reference` -> `# CLAUDE.md - KGProDesign-DevKit Reference`
2. Line 3: Replace "StartGuides-STAC-DevTool plugin" with "KGProDesign-DevKit plugin"
3. Line 101: Replace plugin path references
4. Line 483: Replace plugin path references
5. Line 489: `Maintained by: STAC Development Team` -> `Maintained by: KGProDesign`

### Task 5: Update README.md

**File:** `README.md`

**Major sections to update:**
1. Title: `# StartGuides-STAC-DevTool` -> `# KGProDesign-DevKit`
2. Introduction: Update tagline for universal use
3. Prerequisites: Remove StartGuides SSO references
4. Clone commands: Update all git URLs to `https://github.com/kg250006/KGProDesign-DevKit.git`
5. Copy commands: Update all paths from `StartGuides-STAC-DevTool` to `KGProDesign-DevKit`
6. Directory structure: Update plugin path
7. Documentation links: Remove PRD reference if it doesn't exist
8. Footer: Update from "STAC engineering teams" to universal messaging

### Task 6: Update QUICKSTART.md

**File:** `QUICKSTART.md`

**Major sections to update:**
1. Line 3: Update plugin name
2. Lines 8, 16-28: Remove SSO references, update git URLs
3. Lines 35-47: Update copy paths
4. Line 57: Update verification message

### Task 7: Update VERSION_MANIFEST.md

**File:** `VERSION_MANIFEST.md`

**Updates:**
1. Title: `# StartGuides-STAC-DevTool Version Manifest` -> `# KGProDesign-DevKit Version Manifest`
2. Author field: `STAC Development Team` -> `KGProDesign`
3. Upgrade notes: Remove references to old systems
4. Support section: Generalize or update

---

## Validation Loop

### Level 1: Verify No Remaining Old Brand References

```bash
# Search for any remaining STAC references (should return 0 matches)
grep -r "STAC" --include="*.md" --include="*.json" . | grep -v "node_modules" | grep -v ".git"

# Search for any remaining StartGuides references (should return 0 matches)
grep -r "StartGuides" --include="*.md" --include="*.json" . | grep -v "node_modules" | grep -v ".git"

# Search for old repository URLs (should return 0 matches)
grep -r "StartGuides-Forge" --include="*.md" --include="*.json" . | grep -v "node_modules" | grep -v ".git"
```

### Level 2: Verify New Brand Presence

```bash
# Verify new brand is present in key files
grep -l "KGProDesign-DevKit" CLAUDE.md README.md QUICKSTART.md VERSION_MANIFEST.md

# Verify plugin.json has correct name
grep '"name": "KGP"' .claude-plugin/plugin.json

# Verify new repository URL
grep "kg250006/KGProDesign-DevKit" .claude-plugin/plugin.json README.md
```

### Level 3: Verify JSON Validity

```bash
# Validate plugin.json is valid JSON
python3 -c "import json; json.load(open('.claude-plugin/plugin.json'))" && echo "plugin.json: Valid"

# Validate marketplace.json is valid JSON
python3 -c "import json; json.load(open('.claude-plugin/marketplace.json'))" && echo "marketplace.json: Valid"
```

### Level 4: Verify Command Descriptions Updated

```bash
# Check all toolkit commands have [KGP] prefix
grep -l "\[KGP\]" commands/toolkit/*.md | wc -l
# Expected: 6

# Check all dev commands have [KGP] prefix
grep -l "\[KGP\]" commands/dev/prp-*.md | wc -l
# Expected: 3
```

---

## Final Validation Checklist

- [ ] All tests pass: `grep -r "STAC\|StartGuides" . --include="*.md" --include="*.json"` returns empty
- [ ] plugin.json valid: `python3 -c "import json; json.load(open('.claude-plugin/plugin.json'))"`
- [ ] marketplace.json valid: `python3 -c "import json; json.load(open('.claude-plugin/marketplace.json'))"`
- [ ] New repo URL present in plugin.json
- [ ] All 9 command files have `[KGP]` prefix
- [ ] CLAUDE.md header updated
- [ ] README.md title and all paths updated
- [ ] QUICKSTART.md fully rebranded
- [ ] VERSION_MANIFEST.md author and title updated

---

## Anti-Patterns to Avoid

- Don't change any code logic - this is purely a branding update
- Don't modify files in the `.claude/` directory (internal agents/commands) - they have no brand references
- Don't modify files in the `agents/` directory - they have no brand references
- Don't modify template files unless they contain brand references
- Don't add new features or functionality
- Don't change the directory structure
- Preserve all existing formatting and indentation in markdown files
- Don't remove the PRD reference from README.md even if file doesn't exist (user may add it later)

---

## Execution Order

1. **Task 1**: Update `.claude-plugin/plugin.json`
2. **Task 2**: Update `.claude-plugin/marketplace.json`
3. **Task 3**: Update all 9 command files with `[STAC]` -> `[KGP]`
4. **Task 4**: Update `CLAUDE.md` (most complex, extensive replacements)
5. **Task 5**: Update `README.md` (extensive replacements)
6. **Task 6**: Update `QUICKSTART.md` (moderate replacements)
7. **Task 7**: Update `VERSION_MANIFEST.md` (simple replacements)
8. **Validation**: Run all validation checks

---

## PRP Quality Score: 9/10

**Confidence Level for One-Pass Implementation: HIGH**

**Justification:**
- All files to modify are explicitly identified
- Exact string replacements are documented
- Brand mapping table provides clear reference
- Validation commands are executable
- No complex logic changes required
- Anti-patterns clearly defined to prevent scope creep

**Potential Risks:**
- Minor: Some edge case references might be missed in markdown prose (mitigated by validation grep commands)
- Minor: Formatting preservation requires attention (mitigated by using Edit tool for targeted replacements)

---

**Sources:**
- [Claude Code Plugins Documentation](https://code.claude.com/docs/en/plugins)
- [Anthropic Claude Code Plugin Repository](https://github.com/anthropics/claude-code/blob/main/plugins/README.md)
- [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)
