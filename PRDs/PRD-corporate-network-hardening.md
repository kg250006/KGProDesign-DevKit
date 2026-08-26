# PRD — Corporate-Network Hardening & Reputation Onboarding

A portable, codebase-agnostic runbook for making **any** website — in development or
already live — render correctly and pass through enterprise/corporate web filters. Run it
against a project to produce an assessment, apply the automatable fixes, drive the
domain-reputation vendor submissions (pausing for the human-only captcha steps), verify,
and emit a compliance record plus a client-facing best-effort caveat.

> **Not KG-ProDesign-specific.** No file paths, framework names, or hosting platform are
> assumed. The pipeline auto-detects the stack (static/SPA/SSR, Netlify/Vercel/nginx/
> Apache/Azure VM/FTP) and adapts. Drop this PRD into any project and run it.

---

```xml
<prd name="corporate-network-hardening" version="1.0">

<metadata>
  <created>2026-08-25</created>
  <author>KG (KG ProDesign)</author>
  <status>approved</status>
  <stakeholders>
    <stakeholder role="Owner / Operator">KG</stakeholder>
    <stakeholder role="Implementing Engineer">Any (stack-agnostic)</stakeholder>
    <stakeholder role="Client IT (external)">Visitor-side filter operator (out of our control)</stakeholder>
  </stakeholders>
  <reviewers>
    <reviewer>Client stakeholder receiving the hardened site</reviewer>
  </reviewers>
</metadata>

<executive-summary>
  <problem>
    A site can render perfectly on a consumer network yet appear broken, unstyled, or be
    fully blocked on a corporate/enterprise network. This is not a code defect — it is how
    enterprise web filters and proxies (Zscaler, Cisco Umbrella/Talos, Palo Alto,
    Forcepoint, Symantec/Broadcom BlueCoat, Netskope, DNSFilter, Fortinet, Trend Micro)
    treat brand-new domains and certain hosting patterns. Clients' boards, corporate
    donors, grant offices, and B2B buyers routinely review sites from locked-down work
    machines, so this silently undermines otherwise-finished work and costs deals.

    Three root causes:
    (1) Uncategorized / new-domain reputation — filters default new domains to
        "uncategorized" and block or degrade them; when degraded, HTML loads but
        sub-resources are stripped → the "loads but unstyled" symptom.
    (2) Shared-host / free-subdomain distrust — *.netlify.app, *.vercel.app, *.web.app,
        *.github.io, *.pages.dev namespaces are blocked wholesale regardless of content.
    (3) Missing / weak security posture — no standard security headers, no valid TLS/HSTS,
        or many third-party external resources lowers reputation-engine trust and gives
        strict filters more surface to strip or flag.

    Today this is caught only after a client reports it, one project at a time, with no
    repeatable process.
  </problem>

  <solution>
    A single runnable pipeline — "Corporate Hardening Pass" — executable against any
    project. It has five stages:

      Stage A — ASSESS: auto-detect stack + hosting; audit domain type, live security
                headers, TLS/HSTS, and every external resource on the critical render path;
                produce a scored gap report.
      Stage B — REMEDIATE (automatable): apply the code/config fixes — hardened security
                headers, self-hosted fonts + bundled render-path resources, HSTS with full
                directives, and (where the presented URL is a shared subdomain) flag the
                custom-domain blocker.
      Stage C — REPUTATION ONBOARDING (semi-automated): for each Tier-1 vendor, perform an
                automated lookup of the current category; where the vendor exposes only a
                captcha-bound / login-gated submission form, PAUSE and present the operator
                a pre-filled, click-through checklist; resume and log confirmations.
      Stage D — VERIFY: re-assert headers/TLS from the custom domain and confirm a
                corporate-like render (filtering proxy / locked-down machine / simulator);
                fully-styled + unblocked = pass.
      Stage E — RECORD: write a hardening record (which mitigations applied, vendor
                submission dates/links, verification result) and emit the "best effort, not
                a warranty" caveat into the deploy log and the client proposal/SOW.

    The pipeline is idempotent: re-running on an already-hardened site reports "compliant"
    and makes no changes. It never deploys automatically — deployment stays an explicit,
    separate operator action.
  </solution>

  <success-metrics>
    <metric name="Assessment Coverage">
      <target>100% of the 7 mitigation checks (M1–M7) evaluated on every run</target>
      <measurement>Gap report enumerates M1–M7 each with pass/fail/manual status</measurement>
    </metric>
    <metric name="Automatable Fix Application">
      <target>Code/config mitigations (M2, M3, M4) applied with zero visual regression</target>
      <measurement>Post-run: full header set present in built output; zero render-path
      external-host references; before/after visual diff shows no unintended change</measurement>
    </metric>
    <metric name="Reputation Onboarding Completion">
      <target>Every Tier-1 vendor either auto-looked-up-and-clean or submitted, with a
      logged date/reference</target>
      <measurement>Vendor ledger has a terminal status (clean | submitted | client-IT) for
      each Tier-1 vendor</measurement>
    </metric>
    <metric name="Corporate Render Pass">
      <target>Site renders fully styled and unblocked from a corporate-like environment
      before client handoff</target>
      <measurement>M6 verification result recorded = pass</measurement>
    </metric>
    <metric name="Reusability">
      <target>Runs unmodified across at least 3 distinct stacks/hosts</target>
      <measurement>Successful runs logged on static, SPA, and SSR/server-hosted projects</measurement>
    </metric>
  </success-metrics>

  <scope>
    <in-scope>
      <item>Stack + hosting auto-detection (static / SPA / SSR; Netlify / Vercel / nginx /
      Apache / Azure VM / FTP / GitHub-production).</item>
      <item>Audit of: presented-domain type, security-header set, TLS + HSTS directives,
      and all external hosts on the critical render path (fonts, icon fonts, CDN CSS/JS,
      analytics, embedded widgets, image CDNs).</item>
      <item>Automatable remediation: security headers, font self-hosting, render-path
      resource bundling, HSTS strengthening, CSP tightening where safe.</item>
      <item>Semi-automated vendor reputation onboarding for the Tier-1 list, with a
      human-gate pause for captcha/login-bound steps.</item>
      <item>Corporate-like verification step and a written compliance record + caveat.</item>
      <item>Idempotent re-runs and a machine-readable hardening state block.</item>
    </in-scope>
    <out-of-scope>
      <item>Provisioning DNS or binding a custom domain (the pipeline DETECTS and flags a
      shared-subdomain blocker but does not register domains).</item>
      <item>Deploying / shipping the site (explicit separate operator action).</item>
      <item>Overriding a visitor organization's internal filter policy — impossible by
      design; handled via the client-IT allowlist backstop and the no-guarantee caveat.</item>
      <item>Bypassing, defeating, or evading any security control. This is a legitimacy /
      reputation pass, not evasion.</item>
      <item>Full CSP authoring beyond safe removal of now-unused allowances (untuned CSP is
      a separate phase-2 task).</item>
      <item>Deep performance/SEO/accessibility audits (adjacent, separate runbooks).</item>
    </out-of-scope>
  </scope>
</executive-summary>

<user-stories>

  <story id="US1" priority="P0" persona="operator (agency owner)">
    <narrative>
      As the operator, I want to run one hardening pass against any project I own,
      so that the site is corporate-network-ready without me remembering each manual step.
    </narrative>
    <acceptance-criteria>
      <criterion id="AC1.1">
        Given a project directory, when I run the pass, then the pipeline auto-detects the
        stack and hosting platform and prints them before doing anything.
      </criterion>
      <criterion id="AC1.2">
        Given detection is complete, when the pass proceeds, then it produces a gap report
        covering all of M1–M7 with a per-item pass/fail/manual verdict.
      </criterion>
      <criterion id="AC1.3">
        Given automatable gaps exist, when I approve remediation, then the pipeline applies
        the code/config fixes and reports exactly which files changed.
      </criterion>
    </acceptance-criteria>
    <edge-cases>
      <case id="EC1.1">
        <scenario>Project stack/host cannot be confidently auto-detected.</scenario>
        <expected-behavior>Pause and ask the operator to confirm stack + hosting from a
        short menu; never guess silently.</expected-behavior>
      </case>
      <case id="EC1.2">
        <scenario>Site is already fully hardened.</scenario>
        <expected-behavior>Report "compliant — no changes"; make no edits; still refresh
        the verification timestamp if re-verified.</expected-behavior>
      </case>
    </edge-cases>
  </story>

  <story id="US2" priority="P0" persona="operator">
    <narrative>
      As the operator, I want the fonts and other render-path resources self-hosted
      automatically without changing how the site looks,
      so that strict filters have nothing external to strip and the site never appears
      unstyled on a work computer.
    </narrative>
    <acceptance-criteria>
      <criterion id="AC2.1">
        Given the site loads fonts/CSS/JS from third-party hosts on the render path, when
        remediation runs, then those assets are downloaded, served first-party from the
        site's own origin, and the external references removed.
      </criterion>
      <criterion id="AC2.2">
        Given fonts are self-hosted, when the build completes, then a scan of the built
        output shows ZERO render-path references to known font/asset CDNs.
      </criterion>
      <criterion id="AC2.3">
        Given the swap is done, when the site is compared before/after, then the typefaces,
        icons, and visual appearance are unchanged (same family names, same glyphs).
      </criterion>
    </acceptance-criteria>
    <edge-cases>
      <case id="EC2.1">
        <scenario>An external resource is genuinely required and cannot be self-hosted
        (e.g. a payment iframe, a CAPTCHA widget, an analytics beacon).</scenario>
        <expected-behavior>Keep it, record it on an explicit allowlist WITH a reason; do
        not break required third-party integrations. Only render-path styling/asset hosts
        must be internalized.</expected-behavior>
      </case>
      <case id="EC2.2">
        <scenario>A downloaded asset is an HTML error page, not the real binary.</scenario>
        <expected-behavior>Validate each downloaded asset by magic bytes / size; fail loudly
        and try an alternate source rather than shipping a corrupt file.</expected-behavior>
      </case>
      <case id="EC2.3">
        <scenario>A variable/icon font (e.g. Material Symbols) requires specific axes.</scenario>
        <expected-behavior>Self-host the variable font and replicate the vendor CSS base
        rule so ligatures/icons render identically; verify visually.</expected-behavior>
      </case>
    </edge-cases>
  </story>

  <story id="US3" priority="P0" persona="operator">
    <narrative>
      As the operator, I want the pipeline to check and submit my domain to the reputation
      vendors as far as it can automatically, and pause for me only where a human is truly
      required,
      so that new-domain "uncategorized" blocks are cleaned up without me hunting down each
      vendor form.
    </narrative>
    <acceptance-criteria>
      <criterion id="AC3.1">
        Given a custom domain, when reputation onboarding runs, then for each Tier-1 vendor
        the pipeline performs (or drives) a category lookup and records the current category.
      </criterion>
      <criterion id="AC3.2">
        Given a vendor reports "uncategorized" or an incorrect category, when the vendor
        offers a machine-reachable submission, then the pipeline submits the suggested
        category (Business / Professional Services) and logs the confirmation.
      </criterion>
      <criterion id="AC3.3">
        Given a vendor's submission is captcha-bound or login-gated, when onboarding reaches
        it, then the pipeline PAUSES and presents a pre-filled checklist (domain + suggested
        category + direct link) for the operator to complete by hand, then resumes and
        records the operator-supplied confirmation.
      </criterion>
      <criterion id="AC3.4">
        Given a vendor is customer-login-only (e.g. Zscaler Site Review), when onboarding
        reaches it, then it is marked N/A-global with a note to route via the client's IT
        if that specific client is blocked — not treated as a failure.
      </criterion>
    </acceptance-criteria>
    <edge-cases>
      <case id="EC3.1">
        <scenario>A vendor's public form has moved behind a login since last run.</scenario>
        <expected-behavior>Detect the gate, reclassify the vendor Tier-1→Tier-2 for this
        run, log the change, and fall back to the manual/client-IT path — do not stall.</expected-behavior>
      </case>
      <case id="EC3.2">
        <scenario>The operator is running headless / unattended.</scenario>
        <expected-behavior>Complete all automatable lookups/submissions, then emit a
        deferred manual-action checklist and exit cleanly rather than blocking forever on a
        human gate.</expected-behavior>
      </case>
    </edge-cases>
  </story>

  <story id="US4" priority="P1" persona="operator">
    <narrative>
      As the operator, I want a corporate-like verification and a written compliance record
      with a no-guarantee caveat,
      so that I can prove best effort to the client and set correct expectations.
    </narrative>
    <acceptance-criteria>
      <criterion id="AC4.1">
        Given remediation is applied and deployed, when verification runs, then the full
        header set + valid HTTPS/HSTS are asserted from the CUSTOM domain and the result
        recorded.
      </criterion>
      <criterion id="AC4.2">
        Given a corporate-like environment is available, when the site is loaded through it,
        then a fully-styled, unblocked render is confirmed and logged.
      </criterion>
      <criterion id="AC4.3">
        Given the pass completes, when the record is written, then it lists which of M1–M7
        were applied, all vendor submission dates/links, the verification result, and the
        best-effort caveat text for the proposal/SOW.
      </criterion>
    </acceptance-criteria>
    <edge-cases>
      <case id="EC4.1">
        <scenario>No corporate-like environment is available to the operator.</scenario>
        <expected-behavior>Record M6 as "not verified — pending"; do not mark the pass fully
        complete; surface it as the outstanding item.</expected-behavior>
      </case>
    </edge-cases>
  </story>

  <story id="US5" priority="P2" persona="client stakeholder">
    <narrative>
      As a client reviewing the site from my corporate laptop,
      I want the site to load fully styled and not be blocked,
      so that I trust the vendor's work.
    </narrative>
    <acceptance-criteria>
      <criterion id="AC5.1">
        Given the hardening pass completed successfully, when I open the site on a filtered
        corporate network, then the page renders with correct fonts/icons/styles.
      </criterion>
      <criterion id="AC5.2">
        Given my organization still blocks the domain by internal policy, when I report it,
        then there is a documented client-IT allowlist path and a caveat that set this
        expectation up front.
      </criterion>
    </acceptance-criteria>
  </story>

</user-stories>

<requirements>

  <functional>

    <requirement id="F1" priority="P0" category="core">
      <title>Stack &amp; Hosting Auto-Detection</title>
      <description>
        System shall detect the project's build type (static, SPA, SSR/server-rendered) and
        hosting/header mechanism (platform config file, reverse proxy, web-server vhost, or
        static-host header file) before assessment, and confirm with the operator when
        detection is not confident.
      </description>
      <rationale>Header application and build scanning differ per stack; the runbook must
      adapt to be portable.</rationale>
      <acceptance-criteria>
        <criterion>Detected stack and header mechanism are reported before any change.</criterion>
        <criterion>Ambiguous detection triggers an operator confirmation menu, not a guess.</criterion>
      </acceptance-criteria>
    </requirement>

    <requirement id="F2" priority="P0" category="core">
      <title>Mitigation Gap Assessment (M1–M7)</title>
      <description>
        System shall evaluate all seven mitigations and emit a gap report with a per-item
        verdict of pass / fail / manual-required:
        M1 custom domain (not a shared free-host subdomain);
        M2 hardened security-header set;
        M3 self-hosted fonts + no third-party render-path resources;
        M4 valid HTTPS with full HSTS directives;
        M5 vendor reputation categorization;
        M6 corporate-like render verification;
        M7 compliance record + no-guarantee caveat.
      </description>
      <rationale>A consistent, complete checklist is the core value; nothing is silently skipped.</rationale>
      <acceptance-criteria>
        <criterion>Every run outputs a verdict for each of M1–M7.</criterion>
        <criterion>Verdicts are derived from live/actual inspection, not assumed.</criterion>
      </acceptance-criteria>
    </requirement>

    <requirement id="F3" priority="P0" category="core">
      <title>Shared-Subdomain Blocker Detection (M1)</title>
      <description>
        System shall detect when the presented/public URL is a shared free-host subdomain
        (e.g. *.netlify.app, *.vercel.app, *.web.app, *.github.io, *.pages.dev) and raise it
        as a BLOCKER, instructing that a custom domain be bound before handoff. System shall
        not itself register or bind the domain.
      </description>
      <rationale>Shared namespaces are blocked wholesale (root cause #2); no amount of
      header/asset work fixes it.</rationale>
      <acceptance-criteria>
        <criterion>A shared-subdomain presented URL yields a loud BLOCKER, not a soft warning.</criterion>
        <criterion>A custom-domain presented URL passes M1.</criterion>
      </acceptance-criteria>
      <dependencies>
        <dependency ref="F8">Custom domain is the assertion target for verification.</dependency>
      </dependencies>
    </requirement>

    <requirement id="F4" priority="P0" category="core">
      <title>Security-Header Remediation (M2)</title>
      <description>
        System shall ensure the site serves the baseline hardened header set on all routes,
        applied via the detected mechanism (platform config, proxy/vhost config, or
        static-host header file): X-Frame-Options DENY; X-Content-Type-Options nosniff;
        X-XSS-Protection 1; mode=block; Referrer-Policy strict-origin-when-cross-origin;
        Strict-Transport-Security max-age=31536000; includeSubDomains; preload;
        Permissions-Policy locking down camera/microphone/geolocation (plus payment allow-list
        only where the site actually takes payments).
      </description>
      <rationale>Raises reputation-engine trust (root cause #3); baseline hygiene.</rationale>
      <acceptance-criteria>
        <criterion>All baseline headers are present in the live response after deploy.</criterion>
        <criterion>Headers are applied idempotently (re-run does not duplicate them).</criterion>
      </acceptance-criteria>
    </requirement>

    <requirement id="F5" priority="P0" category="core">
      <title>Render-Path Resource Internalization (M3)</title>
      <description>
        System shall scan the built output for external hosts on the critical render path,
        self-host or bundle each (fonts especially, following a self-hosting recipe:
        download the exact weights/axes in use, declare local @font-face, remove the CDN
        reference), and keep an allowlist of resources that must remain external with a
        recorded reason. Visual appearance must not change.
      </description>
      <rationale>A strict filter strips third-party sub-resources → "loads but unstyled";
      first-party assets remove the surface entirely.</rationale>
      <acceptance-criteria>
        <criterion>Post-build scan shows zero render-path references to font/asset CDNs.</criterion>
        <criterion>Each downloaded asset validated as a real binary (magic bytes/size).</criterion>
        <criterion>Before/after visual comparison shows no unintended change.</criterion>
      </acceptance-criteria>
      <dependencies>
        <dependency ref="F4">Self-hosted assets should also be reflected in any CSP directive.</dependency>
      </dependencies>
    </requirement>

    <requirement id="F6" priority="P1" category="core">
      <title>TLS &amp; HSTS Confirmation (M4)</title>
      <description>
        System shall confirm the site is served over valid HTTPS and that HSTS is present
        with the full directive set (max-age plus includeSubDomains and preload). If TLS is
        not yet live on a fresh domain, flag certificate provisioning as a prerequisite.
      </description>
      <rationale>Baseline trust; blocks downgrade; contributes to reputation score.</rationale>
      <acceptance-criteria>
        <criterion>Live response over HTTPS carries the full HSTS directive string.</criterion>
        <criterion>Missing TLS is surfaced as a prerequisite, not silently passed.</criterion>
      </acceptance-criteria>
    </requirement>

    <requirement id="F7" priority="P0" category="integration">
      <title>Semi-Automated Vendor Reputation Onboarding (M5)</title>
      <description>
        System shall, for each Tier-1 vendor, look up the domain's current category (driving
        the vendor's public lookup where one exists), and: submit the suggested category
        automatically where a machine-reachable submission exists; PAUSE with a pre-filled
        click-through checklist where the submission is captcha-bound; mark customer-login-only
        vendors as N/A-global with a client-IT routing note. All results are written to a
        vendor ledger with dates and confirmation references. Suggested category:
        Business / Professional Services (matched to the site's actual purpose).
      </description>
      <rationale>Directly fixes the "uncategorized new-domain" default (root cause #1) while
      respecting that vendor forms are captcha/login-gated and shift over time.</rationale>
      <acceptance-criteria>
        <criterion>Each Tier-1 vendor reaches a terminal status: clean | submitted | manual-done | client-IT.</criterion>
        <criterion>Captcha/login-gated vendors trigger a human-gate pause with a pre-filled checklist.</criterion>
        <criterion>Vendor ledger records date + reference/link for every submission.</criterion>
      </acceptance-criteria>
      <dependencies>
        <dependency ref="F3">Submissions use the custom domain, not a shared subdomain.</dependency>
      </dependencies>
    </requirement>

    <requirement id="F8" priority="P1" category="core">
      <title>Verification (M6)</title>
      <description>
        System shall re-assert the full header set + HTTPS/HSTS from the custom domain, and
        confirm a corporate-like render (via a filtering proxy/VPN, a locked-down test
        machine, or a filter-simulation service). A fully-styled, unblocked render is a pass.
      </description>
      <rationale>Catches the symptom before the client does; proves the mitigations worked.</rationale>
      <acceptance-criteria>
        <criterion>All baseline headers assert present from the custom domain.</criterion>
        <criterion>Corporate-like render result (pass/fail/pending) is recorded.</criterion>
      </acceptance-criteria>
    </requirement>

    <requirement id="F9" priority="P1" category="core">
      <title>Compliance Record &amp; Caveat (M7)</title>
      <description>
        System shall write a hardening record listing which of M1–M7 were applied, the
        vendor ledger, and the verification result; and emit the client-facing "best effort,
        not a warranty" caveat for inclusion in the deploy log and the proposal/SOW.
      </description>
      <rationale>Sets expectations and provides proof of best effort; corporate policy is
      outside our control.</rationale>
      <acceptance-criteria>
        <criterion>A durable record file/section is produced per run.</criterion>
        <criterion>The no-guarantee caveat text is included verbatim and ready to paste into an SOW.</criterion>
      </acceptance-criteria>
    </requirement>

    <requirement id="F10" priority="P1" category="core">
      <title>Idempotency &amp; State</title>
      <description>
        System shall persist a machine-readable hardening-state block (per project) capturing
        each mitigation's status, the external-resource allowlist, the vendor ledger, and the
        last verification timestamp; and shall make re-runs idempotent (no duplicate edits,
        "compliant" when nothing to do).
      </description>
      <rationale>Enables safe re-runs, audit trail, and cross-project reporting.</rationale>
      <acceptance-criteria>
        <criterion>Re-running on a hardened project changes nothing and reports compliant.</criterion>
        <criterion>State block round-trips: a later run reads prior vendor submissions and skips redundant work.</criterion>
      </acceptance-criteria>
    </requirement>

    <requirement id="F11" priority="P0" category="core">
      <title>No Auto-Deploy</title>
      <description>
        System shall never deploy or ship the site as part of the pass. It stages changes and
        reports which artifacts need deployment; deployment is an explicit, separate operator action.
      </description>
      <rationale>Deployment is a deliberate, gated action across all of this operator's projects.</rationale>
      <acceptance-criteria>
        <criterion>No deploy command is invoked by the pass.</criterion>
        <criterion>The pass lists the exact files/artifacts to deploy for the operator to ship manually.</criterion>
      </acceptance-criteria>
    </requirement>

  </functional>

  <non-functional>

    <requirement id="NF1" category="portability">
      <title>Stack &amp; Host Agnostic</title>
      <description>Runs against any project regardless of framework or host.</description>
      <metric>Executes on static, SPA, and SSR projects and on at least Netlify, nginx/proxy,
      and one static/FTP host without code changes to the runbook.</metric>
      <measurement>Successful documented runs across ≥3 stacks and ≥3 host types.</measurement>
    </requirement>

    <requirement id="NF2" category="safety">
      <title>Non-Destructive &amp; Reversible</title>
      <description>Only additive/replacing config and asset changes; no data loss; each
      change is diffable and revertable.</description>
      <metric>Every change is a reviewable diff; no change is applied without operator approval
      of the remediation stage.</metric>
      <measurement>Operator can `git diff` and revert any single change.</measurement>
    </requirement>

    <requirement id="NF3" category="security">
      <title>Legitimacy, Not Evasion</title>
      <description>The pass improves genuine trust signals (real headers, real TLS,
      first-party assets, honest categorization). It must never fingerprint filters to serve
      them different content, cloak, or otherwise evade a security control.</description>
      <compliance>No cloaking / no filter-evasion. Vendor submissions state the site's true
      category and purpose.</compliance>
    </requirement>

    <requirement id="NF4" category="maintainability">
      <title>Vendor List Is Data, Not Code</title>
      <description>The vendor roster, their tier (public vs gated), submission URLs, and
      suggested categories are maintained as editable data so the runbook survives vendors
      moving forms behind logins.</description>
      <metric>Adding/retiering a vendor requires only a data edit, no logic change.</metric>
      <measurement>A vendor can be moved Tier-1↔Tier-2 by editing the roster entry.</measurement>
    </requirement>

    <requirement id="NF5" category="usability">
      <title>Clear Human-Gate Handoff</title>
      <description>When a manual step is required, the operator receives an unambiguous,
      pre-filled, copy-paste-ready instruction (domain, suggested category, exact link) and a
      clean way to record the result and resume.</description>
      <metric>Each manual gate presents domain + category + link + a place to log the confirmation.</metric>
    </requirement>

  </non-functional>

</requirements>

<technical-design>

  <data-model>
    <entity name="HardeningRun">
      <description>One execution of the pass against one project/domain.</description>
      <attributes>
        <attribute name="id" type="unique-identifier" required="true"/>
        <attribute name="project" type="string" required="true"/>
        <attribute name="domain" type="string" required="true"/>
        <attribute name="detected_stack" type="enum" constraints="values:static,spa,ssr"/>
        <attribute name="detected_host" type="string" required="true"/>
        <attribute name="started_at" type="datetime" required="true"/>
        <attribute name="completed_at" type="datetime" required="false"/>
        <attribute name="overall_status" type="enum" constraints="values:compliant,remediated,blocked,pending-manual"/>
      </attributes>
      <relationships>
        <relationship entity="MitigationResult" cardinality="one-to-many" name="mitigations"/>
        <relationship entity="VendorSubmission" cardinality="one-to-many" name="vendor_ledger"/>
        <relationship entity="ExternalResource" cardinality="one-to-many" name="allowlist"/>
      </relationships>
      <business-rules>
        <rule>overall_status is not "compliant" while any P0 mitigation is failing.</rule>
      </business-rules>
    </entity>

    <entity name="MitigationResult">
      <description>Status of one mitigation (M1–M7) for a run.</description>
      <attributes>
        <attribute name="mitigation" type="enum" required="true" constraints="values:M1,M2,M3,M4,M5,M6,M7"/>
        <attribute name="verdict" type="enum" required="true" constraints="values:pass,fail,manual-required,not-applicable"/>
        <attribute name="detail" type="string" required="false"/>
        <attribute name="evidence" type="string" required="false"/>
      </attributes>
    </entity>

    <entity name="VendorSubmission">
      <description>One vendor's reputation onboarding state for a run.</description>
      <attributes>
        <attribute name="vendor" type="string" required="true"/>
        <attribute name="tier" type="enum" required="true" constraints="values:tier-1-public,tier-2-gated"/>
        <attribute name="current_category" type="string" required="false"/>
        <attribute name="suggested_category" type="string" required="true" constraints="default:Business/Professional Services"/>
        <attribute name="status" type="enum" required="true" constraints="values:clean,submitted,manual-done,client-IT,skipped"/>
        <attribute name="submitted_at" type="datetime" required="false"/>
        <attribute name="reference" type="string" required="false"/>
      </attributes>
    </entity>

    <entity name="ExternalResource">
      <description>A third-party host found on the render path.</description>
      <attributes>
        <attribute name="host" type="string" required="true"/>
        <attribute name="resource_type" type="enum" constraints="values:font,icon-font,css,js,image,widget,analytics,payment,captcha"/>
        <attribute name="disposition" type="enum" required="true" constraints="values:internalized,allowlisted,pending"/>
        <attribute name="reason" type="string" required="false"/>
      </attributes>
      <business-rules>
        <rule>A resource with disposition "allowlisted" must have a non-empty reason.</rule>
      </business-rules>
    </entity>
  </data-model>

  <api-contracts>
    <!-- Conceptual command surface; implementable as a CLI, skill, or CI job in any stack. -->
    <endpoint name="Assess">
      <method>INVOKE</method>
      <path>hardening:assess</path>
      <description>Detect stack/host and produce the M1–M7 gap report without changing anything.</description>
      <authentication>none (local project context)</authentication>
      <request>
        <body content-type="application/json">
          <field name="project_path" type="string" required="true">Project root to assess.</field>
          <field name="domain" type="string" required="false">Public/custom domain; inferred if omitted.</field>
        </body>
      </request>
      <responses>
        <response status="200" description="Gap report produced">
          <field name="run" type="HardeningRun"/>
          <field name="mitigations" type="array[MitigationResult]"/>
          <field name="blockers" type="array[string]"/>
        </response>
      </responses>
    </endpoint>

    <endpoint name="Remediate">
      <method>INVOKE</method>
      <path>hardening:remediate</path>
      <description>Apply automatable fixes (M2, M3, M4/config, safe CSP tightening). Stages changes; never deploys.</description>
      <authorization>Operator approval required before edits.</authorization>
      <request>
        <body content-type="application/json">
          <field name="run_id" type="unique-identifier" required="true"/>
          <field name="approve" type="boolean" required="true">Explicit go-ahead to edit files.</field>
        </body>
      </request>
      <responses>
        <response status="200" description="Fixes applied">
          <field name="changed_files" type="array[string]"/>
          <field name="visual_regression" type="enum">none|detected</field>
        </response>
        <response status="409" description="Blocker prevents remediation (e.g. shared subdomain)"/>
      </responses>
    </endpoint>

    <endpoint name="OnboardReputation">
      <method>INVOKE</method>
      <path>hardening:reputation</path>
      <description>Look up + submit domain across Tier-1 vendors; pause at captcha/login gates.</description>
      <request>
        <body content-type="application/json">
          <field name="run_id" type="unique-identifier" required="true"/>
          <field name="unattended" type="boolean" required="false">If true, skip human gates and emit a deferred checklist instead of blocking.</field>
        </body>
      </request>
      <responses>
        <response status="200" description="Onboarding complete or deferred">
          <field name="vendor_ledger" type="array[VendorSubmission]"/>
          <field name="manual_actions" type="array[string]">Pre-filled checklist for gated vendors.</field>
        </response>
        <response status="202" description="Paused at human gate awaiting operator input"/>
      </responses>
    </endpoint>

    <endpoint name="VerifyAndRecord">
      <method>INVOKE</method>
      <path>hardening:verify</path>
      <description>Assert headers/TLS from custom domain, capture corporate-like render result, write record + caveat.</description>
      <responses>
        <response status="200" description="Verified and recorded">
          <field name="headers_present" type="boolean"/>
          <field name="corporate_render" type="enum">pass|fail|pending</field>
          <field name="record_path" type="string"/>
          <field name="caveat_text" type="string"/>
        </response>
      </responses>
    </endpoint>
  </api-contracts>

  <integrations>
    <integration name="Filter-Vendor Reputation Services">
      <description>Zscaler, Cisco Talos/Umbrella, Palo Alto, Forcepoint, Symantec/Broadcom
      (BlueCoat), Netskope, DNSFilter, Fortinet (FortiGuard), Trend Micro.</description>
      <type>API|web-form</type>
      <direction>outbound</direction>
      <data-exchanged>Domain, suggested category, contact email; back: current category + confirmation.</data-exchanged>
      <failure-handling>If a public form is now gated/captcha'd, reclassify Tier-1→Tier-2,
      fall back to human gate or client-IT routing, and log the reclassification. Never stall.</failure-handling>
    </integration>
    <integration name="Font / Asset Sources">
      <description>Upstream font repos or webfont-helper services to fetch woff2 for self-hosting.</description>
      <type>API|file</type>
      <direction>inbound</direction>
      <data-exchanged>Font binaries (woff2) for the exact families/weights/axes in use.</data-exchanged>
      <failure-handling>Validate each file (magic bytes/size); try alternate source on 404 or corrupt payload.</failure-handling>
    </integration>
    <integration name="Corporate-Like Verification Environment">
      <description>Filtering VPN/proxy, locked-down test machine, or filter-simulation service.</description>
      <type>manual|service</type>
      <direction>outbound</direction>
      <data-exchanged>Live site load; back: rendered/blocked observation.</data-exchanged>
      <failure-handling>If unavailable, record M6 pending and surface as outstanding.</failure-handling>
    </integration>
  </integrations>

</technical-design>

<edge-cases>
  <category name="Detection">
    <case id="E1">
      <scenario>Multiple hosting mechanisms present (e.g. both a platform config and a proxy vhost).</scenario>
      <handling>Prefer the one that actually serves production; confirm with operator; apply headers there.</handling>
    </case>
  </category>
  <category name="Resource Internalization">
    <case id="E2">
      <scenario>External hosts appear only in blog/content text (hyperlinks), not as render-path resources.</scenario>
      <handling>Ignore — only critical-render-path asset hosts count. Do not rewrite editorial links.</handling>
    </case>
    <case id="E3">
      <scenario>A required third-party (payment iframe, CAPTCHA) is on the page.</scenario>
      <handling>Allowlist with reason; ensure any CSP still permits it; never break the integration.</handling>
    </case>
  </category>
  <category name="Vendor Onboarding">
    <case id="E4">
      <scenario>Vendor form moved behind login since the roster was authored.</scenario>
      <handling>Reclassify to Tier-2, log it, route to human gate / client-IT. Roster is data, easily updated.</handling>
      <retry-policy>Re-attempt public lookup next run; no automated retries against a login wall.</retry-policy>
    </case>
    <case id="E5">
      <scenario>Domain is legitimately new and every vendor is uncategorized.</scenario>
      <handling>Submit to all reachable vendors; expect propagation lag (days); record pending and re-check on a later run.</handling>
    </case>
  </category>
  <category name="Policy Limits">
    <case id="E6">
      <scenario>A specific client's internal policy blocks the site regardless of categorization.</scenario>
      <handling>Provide the client-IT allowlist path; rely on the M7 caveat. No site config can override this.</handling>
      <user-communication>Caveat was set up front in the SOW; provide a short IT allowlist request template.</user-communication>
    </case>
  </category>
</edge-cases>

<security-considerations>
  <threat id="S1">
    <description>Self-hosted font/asset fetched from a compromised or spoofed source.</description>
    <mitigation>Fetch from trusted upstreams; validate binaries by magic bytes/size before use; keep the source URL in the record.</mitigation>
  </threat>
  <threat id="S2">
    <description>Header/CSP change breaks a legitimate integration (payments, CAPTCHA, analytics).</description>
    <mitigation>Only tighten from the actual resource inventory; keep required hosts allowlisted; verify the site still functions before marking pass.</mitigation>
  </threat>
  <threat id="S3">
    <description>Misuse of filter-submission techniques for cloaking/evasion.</description>
    <mitigation>Explicit non-goal (NF3): honest categorization only; no serving filters different content; no defeating controls.</mitigation>
  </threat>
  <data-classification>
    <classification type="public">Domain name, site category, security headers (all public).</classification>
    <classification type="sensitive">Operator contact email used in vendor submissions — do not expose in the public record.</classification>
  </data-classification>
</security-considerations>

<release-strategy>
  <phases>
    <phase name="Pilot">
      <audience>Operator's own flagship site (validate end-to-end on a real domain).</audience>
      <features>Full A–E pipeline; manual gates exercised live.</features>
      <success-criteria>One site taken from assessment → remediated → vendor-submitted → verified → recorded.</success-criteria>
    </phase>
    <phase name="Fleet">
      <audience>All of the operator's client projects.</audience>
      <features>Idempotent re-runs; cross-project state; roster-as-data maintenance.</features>
      <success-criteria>Runs unmodified across ≥3 stacks/hosts; hardening record on every client site.</success-criteria>
    </phase>
    <phase name="Standardized">
      <audience>Default step in the operator's launch checklist for every new site.</audience>
      <features>Wired into the pre-handoff / pre-launch gate; SOW caveat auto-included.</features>
    </phase>
  </phases>
  <rollback-plan>
    <trigger>A remediation causes a visual regression or breaks an integration.</trigger>
    <procedure>Revert the specific staged diff (changes are additive/replacing and diffable); re-run assessment; re-apply selectively.</procedure>
  </rollback-plan>
</release-strategy>

<appendix>
  <references>
    <reference>deployment-expert skill → references/corporate-accessibility.md (root causes, header set, vendor list)</reference>
    <reference>deployment-expert skill → workflows/corporate-accessibility-hardening.md (M1–M7 procedure)</reference>
    <reference>kgprodesign-branding skill → references/typography.md (font self-hosting recipe)</reference>
    <reference>small-business-legal-advisor skill → service-agreement §6.4 Corporate Network Accessibility (client-facing caveat)</reference>
  </references>
  <glossary>
    <term name="M1–M7">The seven corporate-hardening mitigations: custom domain, security headers, self-hosted render-path assets, HTTPS/HSTS, vendor categorization, corporate-like verification, record + caveat.</term>
    <term name="Tier-1 vendor">A reputation vendor with a publicly reachable lookup/submission (no login).</term>
    <term name="Tier-2 vendor">A reputation vendor whose submission is captcha-bound or login-gated; handled via a human gate or the client's own IT.</term>
    <term name="Human gate">A pause point where the pipeline hands the operator a pre-filled manual action and waits (or, unattended, emits a deferred checklist).</term>
    <term name="Best effort, not a warranty">The standing caveat that corporate filters are operated by the visitor's IT and cannot be guaranteed by any site configuration.</term>
  </glossary>
  <revision-history>
    <revision version="1.0" date="2026-08-25" author="Kenrick Goldson">
      Initial portable PRD, generalized from the kgprodesign.com hardening pass (fonts
      self-hosted, HSTS strengthened, CSP tightened, Tier-1/Tier-2 vendor split discovered
      when Zscaler Site Review went customer-login-only).
    </revision>
  </revision-history>
</appendix>

</prd>
```
