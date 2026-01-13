<overview>
Data models and context management for maintaining business profile, products, contracts, and compliance obligations.
</overview>

<data_models>

<model name="business-profile">
Core business information maintained across conversations.

<fields>
business_name: [Legal entity name]
dba_names: [Any "doing business as" names]
entity_type: [LLC | C-Corp | S-Corp | Sole Prop | Partnership]
formation_state: [State of formation]
formation_date: [Date formed]
ein: [Federal Tax ID - handle securely]
industry: [Primary industry vertical]
business_model: [Product | Service | SaaS | Marketplace | etc.]

founders:
  - name: [Founder name]
    ownership_percentage: [Percentage]
    role: [CEO | CTO | etc.]
    is_employee: [true | false]

location:
  headquarters: [City, State]
  operating_states: [List of states where operating]
  international: [Countries if applicable]

size:
  employee_count: [Number]
  annual_revenue: [Range]
  funding_stage: [Bootstrapped | Seed | Series A | etc.]
</fields>

<yaml_example>
business_profile:
  business_name: "Example Tech LLC"
  entity_type: "LLC"
  formation_state: "Delaware"
  formation_date: "2023-06-15"
  industry: "SaaS"
  founders:
    - name: "Jane Smith"
      ownership_percentage: 60
      role: "CEO"
    - name: "John Doe"
      ownership_percentage: 40
      role: "CTO"
  location:
    headquarters: "Austin, TX"
    operating_states: ["TX", "CA", "NY"]
  size:
    employee_count: 5
    annual_revenue: "$500K-1M"
    funding_stage: "Seed"
</yaml_example>
</model>

<model name="product">
Individual products or services offered by the business.

<fields>
product_id: [Unique identifier]
name: [Product name]
type: [SaaS | Mobile App | Physical | Digital | Service | Marketplace]
status: [Planning | Development | Beta | Live | Growth | Mature | Sunset]
launch_date: [When launched or expected]
description: [Brief description]

compliance_requirements:
  - [HIPAA | PCI-DSS | GDPR | CCPA | SOC2 | etc.]

legal_documents:
  terms_of_service:
    version: [Version number]
    last_updated: [Date]
  privacy_policy:
    version: [Version number]
    last_updated: [Date]
  other_policies: [List]

data_handling:
  collects_pii: [true | false]
  processes_phi: [true | false]
  handles_payment_data: [true | false]
  data_storage_locations: [US | EU | etc.]
</fields>

<yaml_example>
products:
  - product_id: "prod_001"
    name: "HealthTracker Pro"
    type: "SaaS"
    status: "Live"
    launch_date: "2024-01-15"
    compliance_requirements:
      - "HIPAA"
      - "SOC2"
    legal_documents:
      terms_of_service:
        version: "2.0"
        last_updated: "2024-03-01"
      privacy_policy:
        version: "2.1"
        last_updated: "2024-03-15"
    data_handling:
      collects_pii: true
      processes_phi: true
      handles_payment_data: false
      data_storage_locations: ["US"]
</yaml_example>
</model>

<model name="contract">
Contracts and agreements the business is party to.

<fields>
contract_id: [Unique identifier]
type: [NDA | Service Agreement | Employment | Contractor | Vendor | Customer | Partnership]
counterparty: [Other party name]
role: [Customer | Vendor | Partner | Employee | Contractor]
status: [Draft | Active | Expired | Terminated]

dates:
  effective_date: [Start date]
  expiration_date: [End date if applicable]
  auto_renewal: [true | false]
  renewal_notice_days: [Days before renewal for notice]

terms:
  value: [Contract value if applicable]
  payment_terms: [Net 30 | etc.]
  term_length: [Duration]

key_provisions:
  limitation_of_liability: [Summary]
  indemnification: [Who indemnifies whom]
  ip_ownership: [Summary]
  termination: [Termination rights]
  governing_law: [Jurisdiction]

obligations:
  - description: [Obligation]
    deadline: [If time-bound]
    recurring: [true | false]
</fields>
</model>

<model name="compliance-obligation">
Regulatory and compliance requirements.

<fields>
obligation_id: [Unique identifier]
requirement: [What's required]
authority: [Regulatory body or law]
applies_to: [Business | Product | Both]
category: [Data Privacy | Financial | Employment | Industry | Corporate]

deadline:
  type: [One-time | Annual | Quarterly | Monthly | Ongoing]
  next_due: [Date if applicable]
  reminder_days: [Days before to remind]

status: [Compliant | In Progress | At Risk | Non-Compliant]

evidence:
  documentation: [What documents prove compliance]
  last_verified: [Date last confirmed]

penalty:
  description: [What happens if not compliant]
  severity: [Low | Medium | High | Critical]
</fields>
</model>

</data_models>

<context_persistence>
Using Claude Code's memory system:

<storage_approach>
Store business context in project files:
- .legal-context/business-profile.yaml
- .legal-context/products/
- .legal-context/contracts/
- .legal-context/compliance/

Benefits:
- Persists across conversations
- Can be version controlled
- User maintains ownership
- Easy to update and review
</storage_approach>

<usage_pattern>
At start of conversation:
1. Check if context files exist
2. Load relevant context
3. Verify context is current

During conversation:
1. Reference context in responses
2. Update context when information changes
3. Flag outdated information

End of conversation:
1. Save any updated context
2. Note what changed
</usage_pattern>

</context_persistence>

<context_validation>
Regularly verify context accuracy:

<verification_prompts>
- "I have [business name] on file as a [entity type]. Is this still accurate?"
- "Your product [name] shows as [status]. Has anything changed?"
- "I see your annual report is due in [X days]. Should I add this to reminders?"
</verification_prompts>

<update_triggers>
- New product launch
- Entity restructuring
- New compliance requirement
- Contract renewal
- Change in business model
</update_triggers>

</context_validation>
