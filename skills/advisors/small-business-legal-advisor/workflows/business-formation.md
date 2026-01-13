<objective>
Guide users through entity selection and business formation decisions with jurisdiction-specific recommendations.
</objective>

<required_reading>
@references/business-context.md
@references/entity-types.md
@config/jurisdictions.yaml
</required_reading>

<process>

<step_1 name="gather-context">
Understand the business situation:

Founder Information:
- How many founders/owners?
- Are founders US citizens/residents?
- Will founders be employees?

Business Model:
- Product, service, or SaaS?
- B2B or B2C?
- Revenue model (subscription, one-time, etc.)?

Funding Plans:
- Self-funded (bootstrapped)?
- Friends and family?
- Angel investors?
- Venture capital plans?

Liability Concerns:
- High liability industry (healthcare, finance)?
- Physical products with injury risk?
- Professional services with malpractice exposure?

Location:
- Where will you operate?
- Where are customers?
- Where are founders located?
</step_1>

<step_2 name="recommend-entity">
Based on context, recommend entity type:

<decision_tree>
IF planning venture capital funding:
  → C-Corporation (likely Delaware)
  Reason: VCs require C-Corp structure for investment terms

ELSE IF seeking pass-through taxation AND liability protection:
  IF single owner:
    → Single-member LLC
  ELSE IF multiple owners with different equity:
    → Multi-member LLC with operating agreement
  Reason: Flexibility and tax efficiency

ELSE IF high-liability business with employees:
  → LLC or S-Corporation
  Reason: Liability protection and potential tax savings

ELSE IF very small side project:
  → Sole proprietorship (consider LLC later)
  Reason: Simplest to start, but limited protection
</decision_tree>

Present recommendation with:
- Why this entity type fits their situation
- Key advantages for their specific case
- Important considerations
- When they might need to change later
</step_2>

<step_3 name="jurisdiction-selection">
Recommend formation state:

<considerations>
Delaware:
- Best for: Companies seeking VC funding, complex cap tables
- Advantages: Business-friendly courts, established case law
- Disadvantages: Need registered agent, franchise tax, may need foreign qualification

Home State:
- Best for: Local businesses, simple structures
- Advantages: No foreign qualification, local bank relationships
- Disadvantages: May have less favorable laws

Wyoming:
- Best for: Privacy-focused LLCs
- Advantages: No state income tax, strong privacy, low fees
- Disadvantages: May need foreign qualification

Nevada:
- Best for: Privacy, no franchise tax
- Disadvantages: Annual fees, less established than Delaware
</considerations>

Recommendation formula:
- Planning to raise VC? → Delaware C-Corp
- Local service business? → Home state LLC
- Remote/digital business, privacy important? → Wyoming LLC
- Complex but no VC plans? → Delaware LLC
</step_3>

<step_4 name="formation-checklist">
Generate state-specific formation steps:

<checklist>
1. Choose business name
   - Check availability in formation state
   - Consider trademark search
   - Reserve name if needed

2. Appoint registered agent
   - In-state address for legal documents
   - Can use service or attorney

3. File formation documents
   - Articles of Incorporation (Corp)
   - Certificate of Formation (LLC)
   - Pay filing fees

4. Create governing documents
   - Bylaws (Corp)
   - Operating Agreement (LLC)
   - Equity/ownership documentation

5. Obtain EIN (Federal Tax ID)
   - Free from IRS
   - Required for bank accounts

6. Open business bank account
   - Separate from personal
   - Maintain for liability protection

7. Register for state taxes
   - Sales tax if applicable
   - Employer withholding if employees

8. Foreign qualification (if needed)
   - Register in states where operating
   - Typically where physical presence exists

9. Business licenses
   - Local business license
   - Industry-specific permits
   - Professional licenses if required

10. Initial organizational meeting
    - Adopt bylaws/operating agreement
    - Issue stock/membership interests
    - Elect officers/managers
</checklist>
</step_4>

</process>

<templates_to_generate>
- Formation checklist customized to entity type and state
- Operating agreement outline (LLC)
- Bylaws outline (Corp)
- Initial resolutions template
</templates_to_generate>

<disclaimer>
This guidance is for informational purposes only and does not constitute legal advice. Consult with a licensed attorney for specific legal matters.
</disclaimer>

<success_criteria>
<criterion>Entity type recommended with clear rationale</criterion>
<criterion>Jurisdiction selected based on business needs</criterion>
<criterion>Formation checklist generated with state-specific details</criterion>
<criterion>Next steps clearly identified</criterion>
<criterion>Disclaimer included in output</criterion>
</success_criteria>
