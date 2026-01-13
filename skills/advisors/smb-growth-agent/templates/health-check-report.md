<template name="health-check-report">
Use this template to format health check results for client communication.

<report_header>
  <product_name>[PRODUCT_NAME]</product_name>
  <product_id>[PRODUCT_ID]</product_id>
  <client>[CLIENT_NAME]</client>
  <check_date>[DATE]</check_date>
  <overall_status>[healthy | attention_needed | critical]</overall_status>
  <next_review>[DATE - typically 90 days]</next_review>
</report_header>

<executive_summary>
[One paragraph summary of findings. Include:]
- Overall health status
- Key findings count (X issues, Y warnings)
- Most important action items
- Recommended next steps
</executive_summary>

<dependency_status>
  <security_vulnerabilities>
    <count>[TOTAL]</count>
    <critical>[N]</critical>
    <high>[N]</high>
    <moderate>[N]</moderate>
    <low>[N]</low>
  </security_vulnerabilities>

  <critical_vulnerabilities>
  [List any critical vulnerabilities requiring immediate attention]
  - Package: [name], Severity: Critical, Action: [required action]
  </critical_vulnerabilities>

  <outdated_packages>
    <count>[N]</count>
    <notable>
    [List packages significantly behind]
    - [package]: [current] → [latest] (X major versions behind)
    </notable>
  </outdated_packages>

  <dependency_health>[good | moderate | poor]</dependency_health>
</dependency_status>

<compliance_status>
  <requirement name="[HIPAA/PCI-DSS/ADA]" status="[pass|fail|warning]">
    <summary>[Brief status summary]</summary>
    <issues>
    [List issues found]
    - [Issue description]
    </issues>
    <actions>
    [Required actions to remediate]
    - [Action 1]
    </actions>
  </requirement>
</compliance_status>

<performance_summary>
  <availability>
  [If monitoring data available]
  - Uptime: [X%] over past [period]
  - Incidents: [N] in past [period]
  </availability>

  <response_time>
  [If performance data available]
  - Average: [X ms]
  - 95th percentile: [X ms]
  - Trend: [improving | stable | degrading]
  </response_time>

  <resource_usage>
  [If infrastructure data available]
  - Database: [X% of capacity]
  - Storage: [X% used]
  - Notes: [any concerns]
  </resource_usage>
</performance_summary>

<recommendations>
  <recommendation priority="[critical|high|medium|low]">
    <action>[What needs to be done]</action>
    <rationale>[Why this matters]</rationale>
    <effort>[S|M|L|XL]</effort>
    <timeline>[When this should be done]</timeline>
  </recommendation>

  <recommendation priority="[critical|high|medium|low]">
    <action>[What needs to be done]</action>
    <rationale>[Why this matters]</rationale>
    <effort>[S|M|L|XL]</effort>
    <timeline>[When this should be done]</timeline>
  </recommendation>
</recommendations>

<growth_opportunities>
  <opportunity>
    <title>[Enhancement title]</title>
    <description>[What the enhancement would do]</description>
    <business_value>[Expected benefit - be specific]</business_value>
    <effort>[S|M|L|XL]</effort>
    <prerequisites>[What needs to be in place first]</prerequisites>
  </opportunity>
</growth_opportunities>

<action_items>
  <item owner="[Client|Provider]" due="[DATE]" priority="[1-3]">
  [Specific action to take]
  </item>
</action_items>

<next_steps>
1. [Immediate action if critical issues]
2. [Schedule follow-up if needed]
3. [Next regular review date]
</next_steps>

</template>

<usage_notes>
Status Definitions:
- healthy: No critical issues, minor maintenance only
- attention_needed: Issues require action within 30 days
- critical: Issues require immediate action

Priority Definitions:
- critical: Security risk or compliance violation - act now
- high: Should be addressed within 2 weeks
- medium: Address within 1-2 months
- low: Address when convenient, or defer to next cycle

Effort Definitions:
- S (Small): Less than 1 day of work
- M (Medium): 1-3 days of work
- L (Large): 1-2 weeks of work
- XL (Extra Large): More than 2 weeks
</usage_notes>
