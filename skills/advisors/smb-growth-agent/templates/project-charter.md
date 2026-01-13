<template name="project-charter">
Use this template to document new project kickoffs and ensure complete context capture.

<project_overview>
  <name>[PROJECT_NAME]</name>
  <client>[CLIENT_NAME]</client>
  <vertical>[healthcare | digital_products | general_smb]</vertical>
  <created_date>[DATE]</created_date>
  <primary_contact>[CONTACT_NAME and EMAIL]</primary_contact>
</project_overview>

<business_context>
  <problem_statement>
  [What problem are we solving? Be specific about the pain point and who experiences it.]
  </problem_statement>

  <current_state>
  [How is this problem handled today? What tools, processes, or workarounds exist?]
  </current_state>

  <business_value>
  [How will solving this problem create value? Include estimated ROI if possible.]
  - Time saved: [X hours/week]
  - Revenue impact: [$ or qualitative]
  - Risk reduction: [what risks are mitigated]
  - Other benefits: [list additional value]
  </business_value>

  <success_metrics>
  [How will we measure success? Be specific and quantifiable.]
  - Primary metric: [e.g., reduce processing time from 2 hours to 15 minutes]
  - Secondary metric: [e.g., 95% user adoption within 30 days]
  </success_metrics>
</business_context>

<constraints>
  <budget>
  Total budget: $[AMOUNT]
  Payment structure: [upfront | milestone | monthly]
  Flexibility: [fixed | negotiable if value demonstrated]
  </budget>

  <timeline>
  Target completion: [DATE]
  Hard deadlines: [list any immovable dates and why]
  Phases: [if phased approach, list phase targets]
  </timeline>

  <resources>
  Client availability: [hours/week for meetings, feedback]
  Client technical resources: [who maintains after launch]
  Decision makers: [who approves what]
  </resources>
</constraints>

<technical_scope>
  <technology_stack>
  [List proposed technologies]
  - Frontend: [e.g., React, Next.js]
  - Backend: [e.g., Node.js, Python]
  - Database: [e.g., PostgreSQL, MongoDB]
  - Hosting: [e.g., Vercel, AWS, Azure]
  - Other: [list additional technologies]
  </technology_stack>

  <integrations>
  [List systems that need to integrate]
  - [System 1]: [integration approach, e.g., API, file import]
  - [System 2]: [integration approach]
  </integrations>

  <compliance_requirements>
  [Check all that apply]
  - [ ] HIPAA (healthcare data)
  - [ ] PCI-DSS (payment processing)
  - [ ] ADA/WCAG (accessibility)
  - [ ] SOC 2 (security certification)
  - [ ] GDPR (EU data protection)
  - [ ] Other: [specify]
  </compliance_requirements>

  <data_requirements>
  - Data sources: [where does data come from]
  - Data storage: [where will data be stored]
  - Backup requirements: [backup frequency, retention]
  - Privacy considerations: [what sensitive data is handled]
  </data_requirements>
</technical_scope>

<deliverables>
  <in_scope>
  [List what IS included in this project]
  1. [Deliverable 1]
  2. [Deliverable 2]
  3. [Deliverable 3]
  </in_scope>

  <out_of_scope>
  [List what is explicitly NOT included]
  1. [Item 1]
  2. [Item 2]
  </out_of_scope>

  <assumptions>
  [List assumptions that if wrong could change scope]
  1. [Assumption 1]
  2. [Assumption 2]
  </assumptions>
</deliverables>

<maintenance_plan>
  <review_cadence>[quarterly | monthly | as-needed]</review_cadence>

  <support_scope>
  What ongoing support includes:
  - [Bug fixes within X days]
  - [Security updates within X hours for critical]
  - [Quarterly health checks]
  - [Training for new staff]
  </support_scope>

  <handoff>
  - Documentation location: [where docs will live]
  - Code repository: [where code is stored]
  - Access credentials: [how secrets are managed]
  - Emergency contact: [who to reach if system down]
  </handoff>
</maintenance_plan>

<risks>
  <identified_risks>
  [List known risks and mitigation]
  - Risk: [description]
    Likelihood: [high | medium | low]
    Impact: [high | medium | low]
    Mitigation: [how we'll address it]
  </identified_risks>
</risks>

<approvals>
  <client_approval>
  Client Name: ____________________
  Date: ____________________
  Notes: ____________________
  </client_approval>
</approvals>

</template>
