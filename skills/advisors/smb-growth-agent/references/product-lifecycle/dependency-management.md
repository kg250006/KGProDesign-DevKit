<overview>
Dependency management guidance for maintaining product health. Keeping dependencies current reduces security risk and technical debt.
</overview>

<update_strategy>

<category name="security-patches">
Priority: CRITICAL - Update immediately
Timeline: Within 24-72 hours of disclosure
Scope: Any patch addressing CVE or security issue
Process:
1. Assess severity (CVSS score)
2. Test in development environment
3. Deploy to production
4. Verify fix
Exceptions: Only if patch breaks critical functionality - then isolate exposure
</category>

<category name="minor-updates">
Priority: MEDIUM - Regular maintenance
Timeline: Monthly review, update quarterly
Scope: Bug fixes, small improvements, compatible changes
Process:
1. Review changelog
2. Run test suite
3. Deploy to staging
4. Monitor for issues
5. Deploy to production
Risk: Generally low, but accumulate quickly if ignored
</category>

<category name="major-updates">
Priority: PLANNED - Evaluate and schedule
Timeline: Evaluate quarterly, update as needed
Scope: Breaking changes, API changes, significant new features
Process:
1. Review migration guide
2. Assess breaking changes
3. Estimate effort
4. Plan migration sprint
5. Test thoroughly
6. Stage deployment
7. Monitor closely
Risk: Higher - may require code changes
</category>

<category name="framework-updates">
Priority: STRATEGIC - Annual planning
Timeline: Evaluate annually, plan strategically
Scope: Major framework versions (React, Next.js, Django, etc.)
Process:
1. Evaluate at major release + 3 months (let others find bugs)
2. Review breaking changes
3. Assess community adoption
4. Plan upgrade project
5. Budget appropriately
6. Execute with care
Risk: Highest - plan carefully
</category>

</update_strategy>

<risk_assessment>

<factor name="breaking-changes">
Questions to ask:
- Does the changelog mention breaking changes?
- Are there API changes?
- Are there removed features we use?
- Are there renamed/moved exports?
Lower Risk: Patch versions (x.x.PATCH)
Medium Risk: Minor versions (x.MINOR.x)
Higher Risk: Major versions (MAJOR.x.x)
</factor>

<factor name="test-coverage">
Assessment:
- High coverage: More confident in updates
- Low coverage: Higher risk of undetected regressions
- No tests: Manual testing required, highest risk
Before updating: Improve test coverage for affected areas
</factor>

<factor name="package-maturity">
Considerations:
- Well-established package: Generally safe
- New package: More volatility expected
- Unmaintained package: Consider alternatives
- Single maintainer: Bus factor risk
</factor>

<factor name="usage-extent">
Questions:
- How deeply integrated is this package?
- How many files import it?
- Is it used in critical paths?
- Can it be isolated?
More usage = more risk from changes
</factor>

</risk_assessment>

<rollback_procedures>

<step name="preparation">
Before any update:
1. Record current versions (package-lock.json, requirements.txt)
2. Commit current state
3. Tag release if production
4. Document rollback procedure
</step>

<step name="npm-rollback">
For npm/Node.js:
1. Revert package.json and package-lock.json to previous commit
2. Run: npm ci
3. Verify: npm ls [package-name]
4. Test
5. Deploy
</step>

<step name="pip-rollback">
For Python:
1. Revert requirements.txt to previous commit
2. Run: pip install -r requirements.txt
3. Verify: pip show [package-name]
4. Test
5. Deploy
</step>

<step name="production-rollback">
If update causes production issues:
1. Immediate: Roll back deployment to previous version
2. Investigate: Identify cause in non-production
3. Fix: Address issue
4. Re-deploy: After fix verified
</step>

</rollback_procedures>

<monitoring>

<tool name="dependabot">
Platform: GitHub
Features:
- Automatic PR for updates
- Security vulnerability alerts
- Configurable update frequency
- Version constraints
Setup: .github/dependabot.yml
Recommendation: Enable for all repositories
</tool>

<tool name="npm-audit">
Platform: npm
Features:
- Security vulnerability scanning
- Severity ratings
- Fix suggestions
- CI/CD integration
Usage: npm audit, npm audit fix
Frequency: Every build, weekly scheduled
</tool>

<tool name="snyk">
Platform: Multiple ecosystems
Features:
- Vulnerability database
- License compliance
- Container scanning
- IDE integration
Usage: snyk test
Consideration: Free tier available
</tool>

<tool name="renovate">
Platform: Multiple git platforms
Features:
- Automatic dependency updates
- Sophisticated update rules
- Grouping related updates
- Schedule control
Comparison: More configurable than Dependabot
</tool>

</monitoring>

<smb_recommendations>

<recommendation name="keep-current">
Don't let dependencies become too outdated:
- 1-2 minor versions behind: Acceptable
- 3+ minor versions behind: Catch up soon
- Major version behind: Plan upgrade
- Multiple major versions behind: Technical debt emergency
</recommendation>

<recommendation name="automate-where-safe">
Let automation handle low-risk updates:
- Enable Dependabot for patch updates
- Require tests pass before merge
- Review weekly, merge in batches
- Manually review major/breaking changes
</recommendation>

<recommendation name="schedule-maintenance">
Regular maintenance windows:
- Monthly: Review and apply security updates
- Quarterly: Apply accumulated minor updates
- Annually: Evaluate major version upgrades
- Continuously: Monitor for critical security issues
</recommendation>

<recommendation name="document-decisions">
When you don't update:
- Document why (incompatibility, risk, etc.)
- Set reminder to revisit
- Track exposure if security-related
- Plan alternative mitigation
</recommendation>

</smb_recommendations>

<common_pitfalls>

<pitfall name="update-everything-at-once">
Problem: Updating all packages simultaneously
Risk: Can't identify which update caused issues
Fix: Update in small batches, test between
</pitfall>

<pitfall name="ignore-until-broken">
Problem: Only updating when something breaks
Risk: Security vulnerabilities, accumulated technical debt
Fix: Regular maintenance schedule
</pitfall>

<pitfall name="no-lock-file">
Problem: Missing package-lock.json or equivalent
Risk: Non-reproducible builds, unexpected updates
Fix: Always commit lock files
</pitfall>

<pitfall name="wide-version-ranges">
Problem: package.json with "*" or "^latest"
Risk: Breaking changes on install
Fix: Pin to specific versions or narrow ranges
</pitfall>

</common_pitfalls>
