# Changelog

All notable changes to KGProDesign-DevKit.

## [2.5.0] - 2026-08-24

Corporate network accessibility hardening — new sites are hardened against enterprise web
filters by default (from `PRDs/PRD-corporate-network-accessibility.md`). Split across the
three owning skills.

### Added
- **`deployment-expert` — corporate-accessibility reference** (`skills/deployment-expert/references/corporate-accessibility.md`) — knowledge base for why new sites break on corporate networks (three root causes: uncategorized new-domain reputation, shared free-subdomain distrust, weak security posture), the M1–M7 mitigation table, the per-platform baseline security-header set (Netlify/nginx/NPM), font self-hosting pointer, and the filter-vendor categorization list.
- **`deployment-expert` — hardening workflow** (`skills/deployment-expert/workflows/corporate-accessibility-hardening.md`) — ordered runnable checklist: confirm custom domain (M1) → apply security headers (M2) → scan/remove external resources & self-host fonts (M3) → confirm HTTPS+HSTS (M4) → guided filter-vendor categorization submission (M5) → corporate-like verification (M6) → hardening record + no-guarantee caveat (M7). Includes the AC1–AC7 acceptance checklist.
- **`deployment-expert` — security-header templates** (`skills/deployment-expert/templates/security-headers.netlify.template`, `security-headers.nginx.template`) — drop-in hardened header set (`X-Frame-Options`, `X-Content-Type-Options`, `Referrer-Policy`, `Strict-Transport-Security` w/ preload, `Permissions-Policy`, `X-XSS-Protection`, `Cache-Control`) for Netlify (`_headers`/`netlify.toml`) and nginx/NPM.
- **`kgprodesign-branding` — font self-hosting** (`skills/kgprodesign-branding/references/typography.md`) — new `<self_hosting>` section with the Sora `@font-face` recipe (local `woff2`, `font-display: swap`, preload), required for production/corporate-hardened builds instead of the Google Fonts CDN. Cross-linked to `deployment-expert` M3.
- **`small-business-legal-advisor` — best-efforts clause** (`skills/small-business-legal-advisor/templates/contracts/service-agreement-template.md`) — new §6.4 Corporate Network Accessibility (best-efforts, no warranty of access/rendering on third-party corporate networks) plus a `<proposal_language>` snippet (non-technical proposal paragraph + SOW one-liner).

### Changed
- **`deployment-expert` — `post-deploy-health.md`**: new platform-agnostic Step 4.5 asserts the full security-header set + HTTPS from the custom domain via `curl -sS -D -`, and **fails the health check** if any header is missing.
- **`deployment-expert` — `setup-profile.md`**: initializes the `corporateAccessibility` profile block and scaffolds the security-headers template on new-project setup (PRD §5.6 scaffolding folded here rather than a new command).
- **`deployment-expert` — profile schema**: `templates/deployment-profile.json` and the `SKILL.md` inline schema gain a `corporateAccessibility` block (`customDomainRequired`, `securityHeadersApplied`, `externalResourceAllowlist`, `fontsSelfHosted`, `categorizationSubmitted` per-vendor map, `corporateVerified`, `lastVerifiedAt`).
- **`deployment-expert` — `SKILL.md`**: description mentions corporate-accessibility hardening; intake menu (item 10), routing table, `<reference_index>`, `<workflows_index>`, and `<templates_index>` wire the new files. Index hygiene: removed the dangling `references/verification.md` entry, added the previously-unindexed `references/deploy-scripts.md` and `scripts/` helpers.

## [2.4.0] - 2026-08-24

### Added
- **`dev-engineer` agent** (`agents/dev-engineer.md`) — workflow-enforcing orchestrator designed as the Vibe Kanban workspace default (`KGP:dev-engineer`). Every task runs PRP-Create → PRP-Validate → PRP-Execute with no shortcuts; specialist agent dispatch happens automatically inside the executor via each PRP task's `agent=` attribute. Agent count 11 → 12.

### Fixed
- **`dev-engineer` command resolution** (`agents/dev-engineer.md` Step 1) — the PRP command files were located with a hardcoded `**/KGProDesign-DevKit/commands/prp-*.md` glob, a path that exists only in the dev clone. Running from an installed plugin (`~/.claude/plugins/cache/KGP/KGP/<version>/`) or from any Vibe Kanban workspace rooted in another repo, all three lookups missed and the agent halted with "plugin is not available" — i.e. it failed in precisely the environment it is the default agent for, while testing clean from the plugin repo. Resolution is now layered: `${CLAUDE_PLUGIN_ROOT}` first (layout-independent, already the convention in `hooks/hooks.json`), then a `Bash` search of the install roots (`Glob` cannot reach outside the session working directory), then a project-vendored copy. Multiple hits are disambiguated by requiring `agents/dev-engineer.md` in the same tree, which excludes SG-STAC's identically named `prp-create.md`. Halt-and-report now fires only when all three methods fail.

## [2.3.0] - 2026-07-21

Modernization sweep against the July 2026 Claude Code capability set.

### Added
- **Auto-invocation hooks** (`hooks/hooks.json` + `scripts/hooks/`):
  - `UserPromptSubmit` — detects deploy/debug/design/feature-sized prompts and injects a one-line hint pointing at the matching KGP command or skill.
  - `SessionStart` — surfaces PRP files and in-flight execution state so fresh sessions know what's active.
  - `PostToolUse` (Edit|Write) — suggests the matching auditor agent after SKILL.md / command / agent file edits.
- **Design-first frontend PRPs**: `/KGP:prp-create` emits a `Phase 0: Design Foundation` (design tokens → component inventory → design-skill directives) for UI-bearing PRPs, plus a `verify="visual"` integration criterion.
- **Adversarial verification**: `/KGP:prp-execute` supports `verify="adversarial"` success criteria — an independent qa-engineer verifier attempts to refute the claim before it counts as met.
- **Visual QA gate** in `/KGP:prp-execute`: UI-bearing PRPs run the screenshot-critique-refine loop (ui-visual-testing) before emitting completion promises.
- **Sizing & design advisories** in `/KGP:prp-validate`: warns on >5,000-line / >40-task PRPs (compaction risk) and on UI PRPs missing a Design Foundation phase or visual QA gate.
- **Remote monitoring guidance**: prp-execute/help/README document attaching to long runs from claude.ai/code or mobile via remote control.
- **Model strategy**: docs and prp-create reports recommend Sonnet 5 / Opus 4.8 (1M context) for execution, Opus 4.8 / Fable 5 for planning, Haiku 4.5 for mechanical agents, `/fast` for time-critical output.
- `CHANGELOG.md` (this file).

### Changed
- **ui-visual-testing skill**: now routes to Chrome DevTools MCP / claude-in-chrome first (snapshots, console, network, performance traces, Lighthouse); Puppeteer retained as the headless-CI fallback. Replaced deprecated `headless: 'new'` with `headless: true` throughout.
- **templates/prp_base.md**: replaced the legacy non-XML v2 template with the XML v3 structure (intent-anchors, decisions, Design Foundation phase, verify attributes) — now consistent with prp-create/validate/execute.
- **software-architect skill**: template gains `<intent-anchors>`, `<context><decisions>`, and `verify` attributes; added Design-First principle.
- **prp-execute**: reduced auto-compaction reliance — context hygiene via subagent delegation is the primary strategy; `/rewind` documented for mid-run recovery; Workflow tool recommended for deterministic fan-out phases.
- Model references updated everywhere: `Opus 4.7 / Sonnet 4.6` → `Sonnet 5 / Opus 4.8 / Fable 5 / Haiku 4.5`.
- Normalized legacy command frontmatter (`context-prime`, `dev/run-plan`) to `description`/`argument-hint`/`allowed-tools`.
- Removed deprecated `MultiEdit` from agent tool lists.
- Fixed skill `name` ↔ directory mismatches (`iphone-apps`, `macos-apps`); removed non-standard `triggers:`/`allowed-tools:` keys from agent-teams SKILL frontmatter (trigger phrases folded into the description).
- Corrected counts and metadata: 11 agents / 25 commands / 18 skills; README footer version; INSTALL.md leftover `/SG-STAC:` prefixes.

### Removed
- **`commands/toolkit/`** (6 commands) — duplicates of `/KGP:core:create-*` and `/KGP:dev:create-plan`. Use those instead.
- Dead documentation: `prp_runner.py` script docs, and references to commands that never shipped in v2.x (`/create`, `/commit`, `/pr`, `/review`, `/consider`, `/onboard`, `/handoff`, `/resolve-conflicts`), `QUICKSTART.md`, `VERSION_MANIFEST.md`.
- Stale `--isolated` mutex references (flag was removed in v2.2.0).

## [2.2.0] - 2026-07

- **Breaking**: simplified PRP execution to the native single-session `/KGP:prp-execute` command accepting multiple PRP paths. Removed `/KGP:prp-execute-batch` and `/KGP:prp-execute-isolated`.

## [2.1.1] - 2026-06

- Fixed Ralph Loop plugin name to `ralph-loop`.

## [2.1.0] - 2026-06

- **Breaking**: replaced forked Ralph Loop with marketplace delegation; added experimental Agent Teams (`/KGP:team-invoke`, `--team`).

## [1.9.1] and earlier

- See git history.
