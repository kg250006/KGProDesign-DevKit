<objective>
Assess compliance status and identify risks based on business context, industry, and jurisdiction.
</objective>

<required_reading>
@references/compliance-calendar.md
@config/industries.yaml
@config/jurisdictions.yaml
</required_reading>

<process>

<step_1 name="context-review">
Gather business context:

Business Profile:
- Entity type and jurisdiction
- Industry vertical
- Business model
- Products/services offered

Operations:
- Where do you operate?
- Where are customers located?
- Number of employees
- Types of data collected/processed

Existing Compliance:
- Current certifications
- Compliance policies in place
- Previous audits or assessments
- Known compliance gaps
</step_1>

<step_2 name="identify-requirements">
Determine applicable regulations:

<regulation_mapping>
Data Privacy:
- GDPR: If serving EU customers or EU presence
- CCPA/CPRA: If serving California consumers + revenue/data thresholds
- State privacy laws: Virginia, Colorado, Connecticut, etc.
- HIPAA: If handling protected health information
- Children's data: COPPA if collecting from under 13

Financial:
- PCI-DSS: If processing payment card data
- SOX: If publicly traded
- State money transmitter: If facilitating payments
- SEC: If dealing with securities

Industry-Specific:
- Healthcare: HIPAA, HITECH, state healthcare laws
- Finance: GLBA, state banking regulations
- Education: FERPA for student data
- Telecom: TCPA, CAN-SPAM

Employment:
- Federal employment laws (FLSA, OSHA, EEOC)
- State employment requirements
- Independent contractor classification
- Employee privacy

General Business:
- State corporate compliance
- Tax obligations
- Business licensing
- Professional licensing
</regulation_mapping>
</step_2>

<step_3 name="gap-analysis">
Compare current state to requirements:

<assessment_framework>
For each applicable regulation:

1. Requirement understanding:
   - What does the regulation require?
   - What triggers applicability?
   - What are the key obligations?

2. Current state assessment:
   - Do you meet the requirement?
   - What evidence supports compliance?
   - What gaps exist?

3. Gap categorization:
   - Critical: Non-compliance creates immediate legal risk
   - Important: Should be addressed soon
   - Enhancement: Best practice, not legally required

4. Remediation complexity:
   - Simple: Policy/process change
   - Moderate: Technical implementation needed
   - Complex: Significant investment required
</assessment_framework>

Output gap summary:
| Regulation | Requirement | Current State | Gap | Priority | Effort |
|------------|-------------|---------------|-----|----------|--------|
| [Reg] | [What's required] | [Where you are] | [What's missing] | [H/M/L] | [S/M/L] |
</step_3>

<step_4 name="remediation-plan">
Create prioritized action plan:

<plan_structure>
Immediate Actions (0-30 days):
- Critical compliance gaps
- High-risk items
- Quick wins

Short-Term (30-90 days):
- Important gaps
- Moderate complexity items
- Policy development

Medium-Term (3-6 months):
- Technical implementations
- Certification preparation
- Training programs

Ongoing:
- Monitoring and maintenance
- Regular reviews
- Continuous improvement
</plan_structure>

For each action item:
- Specific task description
- Owner/responsible party
- Timeline
- Resources needed
- Success criteria
- Dependencies
</step_4>

<step_5 name="compliance-calendar">
Align with ongoing obligations:

<calendar_items>
Annual:
- Corporate filings (annual report, franchise tax)
- Policy reviews (privacy policy, ToS)
- Training refreshers
- Insurance renewals

Quarterly:
- Tax payments
- Compliance status reviews
- Access reviews (if required)

Monthly:
- State tax filings (if applicable)
- Employee onboarding compliance

Ongoing:
- Incident monitoring
- Complaint handling
- Record retention
</calendar_items>
</step_5>

</process>

<common_compliance_areas>

<area name="privacy">
Key requirements:
- Privacy policy (accurate and current)
- Consent mechanisms (where required)
- Data subject rights handling
- Breach notification procedures
- Vendor management

Quick wins:
- Update privacy policy
- Implement cookie consent
- Create data inventory
- Designate privacy contact
</area>

<area name="security">
Key requirements:
- Access controls
- Data encryption
- Incident response plan
- Security training
- Vulnerability management

Quick wins:
- Enable MFA
- Document security practices
- Create incident response template
- Implement password policies
</area>

<area name="corporate">
Key requirements:
- Annual filings current
- Board/member meetings documented
- Officer appointments current
- Registered agent maintained
- Good standing status

Quick wins:
- Check filing status
- Update registered agent if needed
- Schedule annual meeting
- Review officer list
</area>

</common_compliance_areas>

<disclaimer>
This compliance assessment is for informational purposes only and does not constitute legal advice. Compliance requirements vary by jurisdiction, industry, and specific circumstances. Consult with qualified legal counsel for specific compliance matters.
</disclaimer>

<success_criteria>
<criterion>Applicable regulations identified</criterion>
<criterion>Gap analysis completed with priority ratings</criterion>
<criterion>Remediation plan created with timelines</criterion>
<criterion>Compliance calendar aligned</criterion>
<criterion>Disclaimer included</criterion>
</success_criteria>
