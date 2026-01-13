<overview>
Compliance deadline tracking and reminder system for ongoing business obligations.
</overview>

<annual_obligations>

<obligation name="delaware-annual-report">
Applies to: C-Corps and LLCs formed in Delaware
Deadline: March 1 annually
Fee: $225 (LLC), $225+ (Corp based on shares)
Penalty: Late fee + potential dissolution
Action: File online at corp.delaware.gov
Reminder: 60, 30, 7 days before
</obligation>

<obligation name="delaware-franchise-tax">
Applies to: C-Corps formed in Delaware
Deadline: March 1 annually
Fee: Minimum $175, based on shares or assumed par value
Penalty: Interest + late fees
Action: Calculate and pay via corp.delaware.gov
Reminder: 60, 30, 7 days before
</obligation>

<obligation name="california-annual-report">
Applies to: LLCs and Corps operating in California
Deadline: Within 90 days of anniversary of formation
Fee: $25 (LLC), $25 (Corp)
Penalty: Suspension of entity
Action: File Statement of Information with CA SOS
Reminder: 90, 60, 30 days before
</obligation>

<obligation name="california-franchise-tax">
Applies to: LLCs and Corps operating in California
Deadline: 15th day of 4th month after year end
Fee: Minimum $800/year
Penalty: Interest + penalties
Action: Pay via CA FTB
Reminder: 30, 14, 7 days before
</obligation>

<obligation name="registered-agent-renewal">
Applies to: All entities using commercial registered agent
Deadline: Varies by provider (usually annual)
Fee: $50-300/year typically
Penalty: Loss of registered agent, potential dissolution
Action: Pay renewal invoice
Reminder: 30, 14 days before
</obligation>

<obligation name="annual-privacy-policy-review">
Applies to: All businesses collecting personal data
Deadline: Annual (recommend anniversary of last update)
Fee: None (unless attorney review)
Penalty: Regulatory risk, lawsuit exposure
Action: Review and update privacy policy
Reminder: 30 days before
</obligation>

<obligation name="annual-terms-of-service-review">
Applies to: All businesses with ToS
Deadline: Annual (recommend anniversary of last update)
Fee: None (unless attorney review)
Penalty: Outdated protections
Action: Review and update ToS
Reminder: 30 days before
</obligation>

<obligation name="board-annual-meeting">
Applies to: Corporations
Deadline: Within 13 months of last annual meeting
Fee: None
Penalty: Governance issues
Action: Hold meeting, document minutes
Reminder: 60, 30 days before
</obligation>

</annual_obligations>

<quarterly_obligations>

<obligation name="estimated-tax-payments">
Applies to: Most businesses
Deadlines: April 15, June 15, September 15, January 15
Fee: Varies based on tax liability
Penalty: Interest + underpayment penalty
Action: Calculate and pay estimated taxes
Reminder: 14, 7 days before each
</obligation>

<obligation name="quarterly-compliance-review">
Applies to: All businesses (recommended)
Deadline: End of each quarter
Fee: None
Penalty: None (but catches issues early)
Action: Review compliance status, pending deadlines
Reminder: First week of each quarter
</obligation>

</quarterly_obligations>

<monthly_obligations>

<obligation name="sales-tax-remittance">
Applies to: Businesses collecting sales tax
Deadline: Usually 20th of following month (varies by state)
Fee: Collected tax amount
Penalty: Interest + penalties
Action: Calculate, file, and pay sales tax
Reminder: 7, 3 days before
</obligation>

<obligation name="payroll-tax-deposits">
Applies to: Businesses with employees
Deadline: Semi-weekly or monthly based on deposit schedule
Fee: Withheld taxes + employer portion
Penalty: Significant penalties for late deposits
Action: Deposit payroll taxes
Reminder: Per deposit schedule
</obligation>

</monthly_obligations>

<trigger_based_obligations>

<obligation name="form-1099-filing">
Trigger: Paid $600+ to independent contractor
Deadline: January 31 to contractor, January 31 to IRS (e-file)
Action: Prepare and file Form 1099-NEC
</obligation>

<obligation name="form-w2-filing">
Trigger: Have employees
Deadline: January 31 to employees, January 31 to SSA
Action: Prepare and file Form W-2
</obligation>

<obligation name="beneficial-ownership-report">
Trigger: New company formation or changes in ownership
Deadline: Within 30 days of formation or change (per FinCEN BOI)
Action: File Beneficial Ownership Information Report
</obligation>

<obligation name="contract-renewal-review">
Trigger: Contract approaching renewal date
Deadline: Per contract notice period (typically 30-90 days)
Action: Review terms, decide to renew or terminate
</obligation>

<obligation name="trademark-renewal">
Trigger: Trademark registration anniversary
Deadline: Section 8/9 at 5-6 years, renewal at 9-10 years
Action: File maintenance documents with USPTO
</obligation>

</trigger_based_obligations>

<industry_specific>

<industry name="healthcare">
- HIPAA training: Annual for all staff handling PHI
- BAA review: Annual review of business associate agreements
- Security risk assessment: Annual (required by HIPAA)
- Breach notification: Within 60 days of breach discovery
</industry>

<industry name="financial-services">
- PCI-DSS assessment: Annual self-assessment or audit
- SAR filing: Within 30 days of suspicious activity
- Currency transaction reports: Same day for $10K+ cash
</industry>

<industry name="saas">
- SOC 2 audit: Annual if maintaining certification
- Security policy review: Annual
- Incident response plan review: Annual
</industry>

</industry_specific>

<calendar_template>

<format>
YAML structure for tracking deadlines:

compliance_calendar:
  - obligation: "Delaware Annual Report"
    entity: "Example Tech LLC"
    deadline: "2025-03-01"
    reminder_days: [60, 30, 7]
    status: "pending"
    notes: "File online at corp.delaware.gov"

  - obligation: "Quarterly Estimated Tax"
    entity: "Example Tech LLC"
    deadline: "2025-01-15"
    reminder_days: [14, 7]
    status: "pending"
    notes: "Q4 payment due"
</format>

</calendar_template>

<automation_recommendations>
Calendar integration:
- Add deadlines to shared calendar
- Set recurring reminders
- Include action links in reminder

Spreadsheet tracking:
- Maintain master compliance tracker
- Sort by upcoming deadline
- Track completion status

Review process:
- Weekly: Check next 14 days
- Monthly: Review next 60 days
- Quarterly: Audit full calendar
</automation_recommendations>
