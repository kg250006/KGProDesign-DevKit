<overview>
Product health check protocol for proactive support and maintenance of solutions created for SMB clients. Regular health checks identify issues before they become problems.
</overview>

<triggers>

<trigger name="time-based">
Standard Review Cadence:
- Quarterly: Recommended for active products
- 90 days since last review: Automatic trigger
- Semi-annually: Minimum for stable products
Calendar reminders should be set at product registration.
</trigger>

<trigger name="event-based">
Triggered by external events:
- Major dependency update released (e.g., new React version)
- Security vulnerability announced in stack
- Compliance regulation change
- Platform deprecation notice
- Significant usage change (up or down)
</trigger>

<trigger name="client-initiated">
Client requests review for:
- New feature planning
- Performance concerns
- Preparing for growth
- Budget planning
- Annual renewal discussions
</trigger>

</triggers>

<check_components>

<component name="dependency-audit">
Purpose: Identify outdated packages and security vulnerabilities
Checks:
- npm audit / pip audit / equivalent
- Compare installed versions to latest
- Identify deprecated dependencies
- Check for known CVEs
Output: List of vulnerable packages, recommended updates
Script: scripts/dependency_audit.py
</component>

<component name="compliance-scan">
Purpose: Verify ongoing compliance with requirements
Checks:
- HIPAA technical safeguards (if applicable)
- PCI-DSS requirements (if applicable)
- Accessibility basics
- Privacy policy currency
- Certificate expiration
Output: Compliance status by requirement
Script: scripts/compliance_scan.py
</component>

<component name="performance-review">
Purpose: Assess system performance and reliability
Checks:
- Uptime/availability (if monitored)
- Response time trends
- Error rate trends
- Resource utilization
- Database performance
Output: Performance summary and trends
Method: Review monitoring dashboards, logs
</component>

<component name="security-posture">
Purpose: Evaluate current security status
Checks:
- SSL certificate expiration
- Password policies
- Access review (who has access)
- Recent security logs
- Backup status
Output: Security findings and recommendations
</component>

<component name="feature-gap-analysis">
Purpose: Identify enhancement opportunities
Checks:
- User feedback review
- Competitor analysis
- Technology capability changes
- Business goal alignment
- Technical debt assessment
Output: Prioritized enhancement opportunities
</component>

</check_components>

<process>

<step order="1" name="prepare">
Before running health check:
- Pull product from registry
- Review previous health check notes
- Gather access credentials
- Identify project location
- Review compliance requirements
</step>

<step order="2" name="automated-checks">
Run automated scripts:
- python scripts/health_check.py [product_id]
- Review dependency audit output
- Review compliance scan output
- Note any failures or warnings
</step>

<step order="3" name="manual-review">
Items requiring human judgment:
- Code quality assessment
- Architecture evaluation
- Performance analysis
- Security posture
- Feature gap analysis
</step>

<step order="4" name="generate-report">
Compile findings into report:
- Use templates/health-check-report.md
- Include all findings
- Prioritize recommendations
- Identify growth opportunities
- Note any blockers or urgent issues
</step>

<step order="5" name="update-registry">
Record health check completion:
- Update last_reviewed date
- Add notes if significant findings
- Schedule next review
- Set reminders for action items
</step>

<step order="6" name="communicate-findings">
Share results appropriately:
- Critical issues: Immediate notification
- Important findings: Schedule discussion
- Minor issues: Include in regular update
- Growth opportunities: Frame as recommendations
</step>

</process>

<report_structure>

<section name="executive-summary">
One paragraph summary:
- Overall health status (healthy/attention needed/critical)
- Key findings count
- Urgent action items
- Recommended next steps
</section>

<section name="dependency-status">
Package and security findings:
- Critical vulnerabilities
- High vulnerabilities
- Outdated packages
- Recommended updates
</section>

<section name="compliance-status">
By requirement type:
- HIPAA status (if applicable)
- PCI-DSS status (if applicable)
- Accessibility status
- Privacy/data protection
- Issues and remediation
</section>

<section name="performance-summary">
System health indicators:
- Availability metrics
- Performance trends
- Resource utilization
- Error rates
</section>

<section name="recommendations">
Prioritized action items:
- Critical (do now)
- High (do soon)
- Medium (plan for)
- Low (consider)
With effort estimate and rationale.
</section>

<section name="growth-opportunities">
Enhancement possibilities:
- Feature suggestions
- Integration opportunities
- Efficiency improvements
- Business value potential
</section>

</report_structure>

<follow_up_actions>

<action_type name="critical">
Response: Within 24-48 hours
Examples:
- Active security vulnerability
- System down
- Data breach indicator
- Compliance violation
Process: Immediate notification, remediation plan, implement fix
</action_type>

<action_type name="high">
Response: Within 1-2 weeks
Examples:
- Security patches needed
- Expiring certificates
- Performance degradation
- Compliance gaps
Process: Schedule work, implement, verify
</action_type>

<action_type name="medium">
Response: Within 1-3 months
Examples:
- Package updates
- Minor improvements
- Technical debt
- Documentation gaps
Process: Add to backlog, prioritize, schedule
</action_type>

<action_type name="low">
Response: As opportunity allows
Examples:
- Nice-to-have enhancements
- Optimization opportunities
- Future planning items
Process: Document, review at next check
</action_type>

</follow_up_actions>

<success_metrics>

<metric name="coverage">
Goal: 100% of registered products have recent health check
Measure: Products with review in last 90 days / Total products
</metric>

<metric name="issue-discovery">
Goal: Find issues before they become incidents
Measure: Issues found in health check vs. found by users/outages
</metric>

<metric name="remediation-rate">
Goal: Act on findings promptly
Measure: Critical/High issues resolved within SLA
</metric>

<metric name="client-satisfaction">
Goal: Clients value proactive support
Measure: Client feedback, retention, expansion
</metric>

</success_metrics>
