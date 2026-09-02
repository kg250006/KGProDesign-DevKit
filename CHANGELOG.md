# Changelog

All notable changes to KGProDesign-DevKit.

## [2.8.0] - 2026-09-01

Desktop utilities ship. `tools/` was untracked, so neither of the two tray tools existed anywhere but one machine. This release tracks the directory, adds a scheduler to it, documents both, and closes the validation gap that let a version bump go unverified.

### Added
- **`tools/` directory now tracked and shipped.** Two standalone desktop utilities:
  - **CronLike** (`tools/CronLike/`) — system tray scheduler. Runs commands on a human-readable JSON schedule at `~/.cronlike/schedule.json`. Windows and macOS. Catch-up windows for runs missed while the machine was asleep, hot config reload, single-instance locking, per-job threads with per-job timeouts, and a four-state tray icon. Command resolution wraps Windows `.cmd`/`.bat` shims through `COMSPEC`, which is the failure that killed the previous automation.
  - **MouseJiggler** (`tools/MouseJiggler/`) — existing tray utility, now tracked rather than local-only.
- **`tools/CronLike/README.md`** — install, launch, the tray menu item by item, how the scheduler works, log layout, and a troubleshooting table.
- **`tools/CronLike/SCHEDULE.md`** — the complete configuration reference. Every field the parser accepts, the three composition rules, worked examples for every schedule shape, the catch-up semantics, what is deliberately unsupported, and all 48 error messages with a fix for each. It is the contract: `schedule_config.py` must not raise a message absent from it. This is the file to load before adding or editing a job.
- **`json_get()`, `json_len()`, `json_has()`, `json_has_item()`** in `scripts/tests/test-static-validation.sh` — JSON readers that prefer `jq` and fall back to Python. Every JSON assertion now runs without `jq`.
- **Tools sections in `README.md` and `CLAUDE.md`**, both framing these as user-facing utilities rather than agent orchestration, plus a `tools/` line in the directory-structure block.

### Changed
- **`scripts/tests/test-static-validation.sh`** — the three `command -v jq` guards are replaced by `_json_have_reader`, which is satisfied by either `jq` or Python. Assertion count rises from 80 to 90 on a machine without `jq`, and the skip count falls from 4 groups to 0. `validate_json` now accepts `python` as well as `python3`.
- **`INSTALL.md`** — component counts corrected, and a Tools row added.
- Version literals across `plugin.json`, `marketplace.json` (both fields), `test-static-validation.sh`, and `README.md`.

### Fixed
- **The validation suite's `jq` blind spot.** Ten assertions, including all three version invariants, the keyword assertions, the description sweep, and the hook-event checks, sat behind `command -v jq` and reported SKIP on any machine without it. This is how `plugin.json` was allowed to drift from 2.3.0 to 2.5.0 while the suite printed "All static validation checks passed." v2.7.0 made the skips visible; this release makes them run. Verified by injecting a wrong `metadata.version` and confirming the suite fails.
- **`.gitignore` had no Python, OS, editor, or secrets rules.** Added before Python entered the tree, so `__pycache__/` and `.pyc` never became a tracking problem.
- **12 committed `.DS_Store` files** were shipping inside the plugin payload. Untracked. A gitignore rule alone does not untrack an already-tracked file.
- **`.gitignore` now excludes `tools/**/.gates-*.md`.** The PRP gate records are working artifacts and were not covered by any existing rule, so `git add tools/` would have committed them.
- **`INSTALL.md` component counts were stale** — 11 agents, 25 commands, and 18 skills against an actual 12, 26, and 19.
- **`INSTALL.md` now documents why `/plugin update` no-ops after a same-version push.** The plugin cache is keyed by version, so without a bump the updater has no new directory to resolve and silently does nothing. The uninstall, cache-delete, reinstall procedure is recorded, with the PowerShell equivalent for the delete step.
- **`tools/MouseJiggler/install.bat` told the user to start the tool with `run.bat`, which does not exist.** Its launchers are `run-MouseJiggler.vbs` and `run-debug.bat`. CronLike's installer was copied from this file and had the same defect corrected during its own build, but the source file was never fixed, so the broken instruction would have shipped on the tool's first release. Both installers now name their real launchers in matching wording.

### Notes
- These tools are user-facing utilities, not agent orchestration. The Execution Philosophy constraints in `CLAUDE.md` are scoped to PRP execution and do not apply to them: CronLike has no notion of agents, tasks, PRPs, iteration, or retries.
- **No new commands, agents, skills, or hooks.** Counts stay at 26, 12, 19, and the registered hook event count stays at 3.
- No git tag. This repository has never used them.

## [2.7.0] - 2026-08-31

Communication-style control. A new skill generates and installs a tailored, model-agnostic
communication ruleset into any repository, so replies stay concise and plainly worded
without restating the preference every conversation.

### Added
- **Tracked-vs-personal install choice** — the wizard's FIRST question is whether the rule should be tracked by the repository, and it **defaults to personal**. A communication ruleset is a preference; committing one makes everyone who clones the repo inherit how one person likes to be spoken to. Personal writes `.claude/rules/communication.local.md` and excludes it via `.git/info/exclude`, leaving `git status` completely empty. Shared writes `.claude/rules/communication.md` to be committed and reviewed in a PR. User scope writes `~/.claude/rules/communication.md` and touches nothing in the repo. `tweak` moves an install between modes.
- **`.claude/rules/*.md` as the load mechanism, verified against the CLI binary** — no `@` import line is written anywhere. Rule files auto-load, so an import would load the content a second time. Confirmed by four independent strings in `claude.exe` v2.1.234: the literal `rules/*.md` glob, a prompt listing `.claude/rules/*.md` among always-loaded files, a settings schema offering `"**/some-dir/.claude/rules/**"` exclusions, and `function vCt(){return join(claudeHome(),"rules")}` for the user-level directory.
- **`communication-style` skill** (`skills/communication-style/`) — router with a detect-then-ask wizard. Four references (`base-ruleset.md` for the model-neutral L1/L2 text, `model-tics.md` for the per-model banned-phrase overlays, `conflict-resolution.md` for the T1–T5 conflict catalogue and detection commands, `mechanisms.md` for install mechanics and the two rejected approaches), four workflows (`setup`, `review`, `tweak`, `remove`), and one artifact template. Skill count 18 → 19.
- **`/KGP:comm-style` command** (`commands/comm-style.md`) — `setup` / `review` / `tweak` / `remove` / `user`. Command count 25 → 26.
- **`expand-alias.sh` hook** (`scripts/hooks/expand-alias.sh`) — UserPromptSubmit. Expands a prompt that is exactly `scr`, `eli`, `foc`, or `ref`. Separate from `suggest-skill.sh` because that script exits for prompts under six words and every alias is one word.
- **`comm-style-default.sh` hook** (`scripts/hooks/comm-style-default.sh`) — SessionStart, opt-in behind `KGP_COMM_STYLE_DEFAULT=1`, and silent whenever a project or user artifact already exists. Off by default because it fires in every repo and costs input tokens every session.
- **Dogfood rule** (`.claude/rules/communication.local.md`) — this repo runs its own ruleset in personal mode: git-excluded, invisible to anyone who clones, and leaving no diff in any tracked file. Contributors get the `/KGP:comm-style` capability, not the maintainer's preference.
- **Tracking regression guards** (`scripts/tests/test-static-validation.sh`) — four assertions that fail if a personal rule becomes exclude-exempt or git-tracked, if a redundant `@` import appears for an auto-loaded rule file, or if a bogus `.claude.local.md` is ever written.

### Changed
- **`hooks/hooks.json`** — two new entries added *inside* the existing `UserPromptSubmit` and `SessionStart` events. The registered event count stays at 3, which is what `test-static-validation.sh` asserts.
- **`scripts/hooks/suggest-skill.sh`** — new verbosity-intent branch appended as the last `elif`, so the existing deploy > debug > design > PRP priority cascade is unchanged.
- **`scripts/tests/test-static-validation.sh`** — new YAML and REQUIRED targets, both new hook scripts added to the executable and malformed-input loops, plus a positive alias-expansion check.
- Counts and versions across `README.md`, `CLAUDE.md`, `plugin.json`, `marketplace.json`, and `commands/help.md`.

### Fixed
- **`scripts/tests/test-static-validation.sh` version invariant** — pinned to `2.3.0` while `plugin.json` had moved to `2.5.0`. The mismatch was invisible on machines without `jq`, since the assertion sits inside a `command -v jq` guard. Now asserts `2.6.0`.
- **`scripts/tests/test-static-validation.sh` silent skips** — 21 assertions behind `jq` guards vanished without a word while the suite still printed "All static validation checks passed." A `Skipped: N` field and per-group `SKIP` lines now report what was not measured. Skips still exit 0, so CI behavior is unchanged.
- **`README.md`** — the directory-structure block described "11 specialized agents" while the feature list said 12. There are 12.

### Notes
- Whether a rule file actually loaded cannot be confirmed from inside the session that writes it, since rules load at session start. The wizard says so rather than reporting the install as verified on file existence alone.
- **Verify load paths against the installed binary, not against prose.** Three separate sources were wrong about these paths during development: two research passes claimed `.claude/rules/` did not exist (it does) and named `CLAUDE.local.md` where the loader disagreed, and Anthropic's own `claude-md-management` plugin documents `./.claude.local.md` as the personal memory file in two places. That dotted filename has **zero** occurrences in `claude.exe`; the real one is `CLAUDE.local.md`, uppercase, a first-class memory type in the loader. Grepping the binary settled every one of these in minutes.
- Output styles are deprecated upstream. Anthropic's own `explanatory-output-style` plugin exists to recreate one as a SessionStart hook, and names that pattern as the CLAUDE.md-equivalent that plugins can distribute. This feature therefore uses CLAUDE.md `@` imports plus SessionStart injection, never an output style.
- `.claude/rules/` was evaluated and rejected as unverified: zero hits across the entire official plugin marketplace. See `skills/communication-style/references/mechanisms.md`.

## [2.6.0] - 2026-08-25

Corporate Hardening Pass — the v2.5.0 accessibility artifacts grow into a full five-stage,
idempotent, stack-agnostic hardening pipeline in `deployment-expert`, generated from
`PRDs/PRD-corporate-network-hardening.md` via the `software-architect` PRD→PRP pipeline.

### Added
- **`software-architect` — hardening capability knowledge** (`skills/software-architect/references/corporate-hardening.md`) — distilled, reusable knowledge (M1–M7, the 5-stage pass, Tier-1/Tier-2 vendor split, idempotent state, best-effort caveat, authoring guidance) so the architect knows the capability when authoring PRDs/PRPs. Points at `PRDs/PRD-corporate-network-hardening.md` as the canonical example. Indexed in the skill's `<references_index>`.
- **`deployment-expert` — hardening stage workflows** (`skills/deployment-expert/workflows/hardening-assess.md`, `hardening-remediate.md`, `hardening-reputation.md`, `hardening-verify-record.md`) — the five-stage pass: Assess (detect stack/host, score M1–M7 read-only), Remediate (approval-gated idempotent header + self-hosted-asset + HSTS fixes, staged never deployed), Reputation (tiered vendor lookup/submission with captcha/login human-gate), Verify+Record (custom-domain re-assertion, corporate-like render, compliance record + caveat).
- **`deployment-expert` — vendor roster as data** (`skills/deployment-expert/references/reputation-vendors.md`) — filter-vendor roster (tier, lookup/submission URLs, suggested category) editable without touching workflow logic (NF4). Zscaler flagged tier-2 login-gated → client-IT routing.
- **`deployment-expert` — assess probe** (`skills/deployment-expert/scripts/assess-hardening.sh`) — reuses `detect-platform.sh`; detects build type + header mechanism, flags shared-subdomain URLs as BLOCKERs, probes live headers/HTTPS/HSTS. Read-only.
- **PRD + PRP artifacts** — `PRDs/PRD-corporate-network-hardening.md` (portable v1.0 PRD) and `PRPs/PRP-corporate-hardening.md` (generated PRP, 100% F1–F11 / NF1–NF5 coverage).

### Changed
- **`deployment-expert` — `corporateAccessibility` state block** (`templates/deployment-profile.json`): extended into the full hardening-state model — per-mitigation verdicts (M1–M7), `externalResourceAllowlist` entries now `{host, resourceType, disposition, reason}`, a `vendorLedger[]` (replacing the flat `categorizationSubmitted` map), and run metadata (`overallStatus`, `detectedStack`, `detectedHost`, `lastRunAt`). Backward-compatible keys retained.
- **`deployment-expert` — `corporate-accessibility-hardening.md`** is now a thin idempotent orchestrator routing through the five stage workflows (states F10 idempotency + F11 no-auto-deploy up front); AC1–AC7 checklist retained.
- **`deployment-expert` — `SKILL.md`**: intake/routing enriched for the pass; the four stage workflows, `reputation-vendors.md`, and `assess-hardening.sh` wired into the indices.

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
