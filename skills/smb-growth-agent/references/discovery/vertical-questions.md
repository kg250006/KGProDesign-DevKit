<overview>
Industry-specific discovery questions for different verticals. Use these after general intake to gather specialized context.
</overview>

<healthcare_questions>

<category name="patient-data">
Understanding PHI handling:
- Do you currently collect or store patient health information?
- What EHR system do you use (Epic, Cerner, Allscripts, athenahealth)?
- Do you need to integrate with existing EHR systems?
- What patient data would the solution need to access?
- Where is patient data currently stored?
- Do you have a HIPAA compliance officer or consultant?
</category>

<category name="clinical-workflow">
Understanding care delivery context:
- What clinical setting is this for (hospital, clinic, private practice)?
- Who are the primary users (physicians, nurses, front desk, patients)?
- What is the typical patient volume per day?
- What are the busiest times and biggest bottlenecks?
- How are appointments currently scheduled and managed?
- What happens when the system is down?
</category>

<category name="payer-integration">
Insurance and billing considerations:
- Do you need to verify insurance eligibility?
- What billing system do you use?
- Do you need to submit claims electronically?
- What clearinghouse do you use?
- Do you accept multiple payers or primarily one?
</category>

<category name="compliance-current">
Existing compliance status:
- Have you had a HIPAA risk assessment in the last year?
- Do you have Business Associate Agreements with current vendors?
- Have you had any HIPAA incidents or breaches?
- Do you have documented privacy and security policies?
- Is your staff trained on HIPAA requirements?
</category>

<category name="telehealth">
Remote care considerations:
- Do you offer telehealth services?
- What platform do you use for video visits?
- How do you handle patient identity verification remotely?
- Do you need to support multiple states (licensing issues)?
</category>

</healthcare_questions>

<digital_products_questions>

<category name="product-definition">
Understanding what's being built:
- Is this a customer-facing product or internal tool?
- What problem does this product solve for users?
- Who is the target user (B2B, B2C, internal)?
- What is the revenue model (subscription, one-time, freemium)?
- What competitive products exist?
</category>

<category name="technical-architecture">
Technical context:
- Do you have existing technical infrastructure?
- What is your preferred technology stack (or open)?
- Do you need mobile apps, web apps, or both?
- What scale do you anticipate (users, transactions)?
- Do you have technical resources to maintain this?
</category>

<category name="data-handling">
Data and privacy considerations:
- What user data will be collected?
- Will you collect any sensitive data (PII, financial, health)?
- What data privacy regulations apply (GDPR, CCPA)?
- Do you need data export or portability features?
- What are your data retention requirements?
</category>

<category name="integrations">
External system connections:
- What third-party services need to integrate?
- Do you need payment processing?
- Do you need authentication (social login, SSO)?
- What APIs do you need to connect to?
- Do you need to provide APIs for partners?
</category>

<category name="launch-timeline">
Go-to-market considerations:
- What is your target launch date?
- Is there an MVP or phased approach planned?
- How will you acquire initial users?
- What metrics will define success at launch?
- Do you have marketing/sales resources ready?
</category>

</digital_products_questions>

<general_smb_questions>

<category name="operations">
Day-to-day business operations:
- How many locations do you operate?
- Do employees work in-office, remote, or hybrid?
- What are your hours of operation?
- Do you have seasonal peaks?
- What does a typical customer interaction look like?
</category>

<category name="customer-management">
Customer relationship handling:
- How do you track customer information today?
- What is your sales process?
- How do you handle customer support?
- Do you have repeat customers or mostly one-time?
- How do you communicate with customers (email, phone, SMS)?
</category>

<category name="financial-operations">
Money handling:
- How do customers pay (cash, card, invoice)?
- What accounting software do you use?
- Who handles bookkeeping?
- Do you need inventory tracking?
- Do you have cash flow challenges?
</category>

<category name="marketing-current">
Current marketing approach:
- How do people find your business?
- Do you have a website?
- Are you active on social media?
- Do you do any paid advertising?
- Do you have an email list?
</category>

<category name="technology-comfort">
Assessing technical readiness:
- How comfortable is your team with technology?
- Who would use a new system day-to-day?
- What has worked well with technology changes before?
- What resistance to change do you anticipate?
- How much training time is realistic?
</category>

</general_smb_questions>

<vertical_detection>

<signals name="healthcare">
Trigger phrases:
- "patient", "clinic", "practice", "EHR", "HIPAA"
- "medical records", "appointments", "insurance"
- "physician", "nurse", "front desk staff"
- "telehealth", "PHI", "protected health information"
Action: Switch to healthcare discovery questions
</signals>

<signals name="digital-products">
Trigger phrases:
- "SaaS", "app", "platform", "subscription"
- "users", "onboarding", "churn"
- "API", "integration", "database"
- "launch", "MVP", "product-market fit"
Action: Switch to digital products discovery questions
</signals>

<signals name="general-smb">
Trigger phrases:
- "local business", "store", "shop"
- "customers", "appointments", "scheduling"
- "invoicing", "payments", "inventory"
- No specific healthcare or tech product indicators
Action: Use general SMB discovery questions
</signals>

</vertical_detection>
