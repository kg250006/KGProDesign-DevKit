---
description: Precision fix command for targeted, minimal changes
argument-hint: "[description of what needs fixing]"
---

# /fix — Claude Code slash command for precise, minimal changes

## Role & Objective
You are Claude Code executing a Precision Fix Protocol. Make only the essential changes needed to address the user's specific issue. Maintain surgical precision—no scope creep, no opportunistic refactors, no unrelated modifications.

## Single Input Format
```
/fix "<concise description of what needs fixing>"
```

## Immediate Clarification (if needed)
Ask only essential questions:
1. **Context needed?** (error messages, file paths, reproduction steps)
2. **Constraints?** (files to avoid, breaking changes forbidden, timeline)
3. **Verification method?** (how to confirm fix works)

If no response, proceed with conservative defaults.

## Protocol: Plan → Gate → Execute → Verify

### 1. Plan (Planning Phase)
Create a focused plan in markdown format:

```markdown
## Fix Plan

**Problem:** <root cause in one sentence>

**Solution:** <fix approach in one sentence>

**Files to Change:**
- `path/to/file1.js` - <what changes here>
- `path/to/file2.css` - <what changes here>

**Components Affected:**
- ComponentName - <how it's affected>
- FeatureName - <impact description>

**Risk Assessment:** LOW/MEDIUM/HIGH
- **Blast radius:** <what could break if this goes wrong>
- **Mitigation:** <how to minimize risk>

**Alternative Approaches:**
1. **Option A:** <approach> - Risk: <level>
2. **Option B:** <approach> - Risk: <level>

**Chosen Approach:** <selected option with brief justification>

**Verification Plan:**
- [ ] <automated test to run>
- [ ] <manual check to perform>
- [ ] <regression test if needed>
```

### 2. Scope Gate (Boundary Check)
**Hard Boundaries:**
- Changes must stay within the immediate problem area
- No touching shared APIs, global styles, or cross-cutting concerns
- No new dependencies or build system changes
- No files outside the specific feature/component affected

**Escalation Required For:**
- Backend API changes
- Shared component modifications
- Database schema changes
- Cross-service impacts

### 3. Execute (Minimal Implementation)
**Core Principles:**
- Smallest possible diff to solve the problem
- Remove any temporary code, unused imports, or dead code introduced
- Preserve existing behavior for all unrelated functionality
- One logical change per execution

**Output Format:**
```diff
// File: path/to/changed/file.js
- problematic_line
+ fixed_line

// Cleanup
- unused_import
```

### 4. Verify (Targeted Testing)
Report verification results in markdown:

```markdown
## Verification Results

**Automated Tests:**
- ✅ `npm test ComponentName` - passed
- ✅ `npm run lint` - no new issues

**Manual Checks:**
- ✅ UI flow works as expected
- ✅ No visual regressions
- ✅ Performance unchanged

**Regression Check:**
- ✅ Related features still work
- ✅ No console errors
```

## Default Behavior (No Additional Context)
- Assume issue is isolated to the most obvious location
- Prefer component-level fixes over system-wide changes
- Use inline solutions over new abstractions
- Add minimal test coverage for the specific fix
- Clean up only what your change touches

## Quality Gates
✅ **Before committing:**
- [ ] Fix addresses the exact problem described
- [ ] No unrelated code changes
- [ ] All temporary/debug code removed
- [ ] Unused imports/variables cleaned up
- [ ] Change is easily reversible

## Output Templates

### Success Summary
```markdown
## ✅ Fix Complete

**Problem Fixed:** <problem description>
**Files Modified:** <file count> files
**Scope:** <component/feature affected>
**Risk Level:** <level> - <mitigation if any>
**Verification:** <test method used>

### Changed Files:
- `path/to/file1.js` - <brief description of change>
- `path/to/file2.css` - <brief description of change>

### Cleanup Performed:
- Removed unused import: `oldLibrary`
- Deleted temporary variable: `debugFlag`
```

### Rollback Instructions
```markdown
## 🔄 Rollback Instructions

To revert this fix:
```bash
git revert <commit-hash>
```

Or manually restore these files:
- `path/to/file1.js`
- `path/to/file2.js`
```

## Commit Message Format
```
fix: <concise problem + solution>

- Modified: <files>
- Risk: <level>
- Cleanup: removed <unused items>
```

## Error Recovery
If fix breaks something outside intended scope:
1. **Immediate rollback** to previous state
2. **Reassess** with broader context
3. **Propose** breaking into smaller, safer fixes
4. **Never expand scope** to fix secondary issues

---

**Remember: Better to make 3 small, safe fixes than 1 large, risky one.**

---
