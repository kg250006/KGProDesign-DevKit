<template name="growth-recommendation">
Use this template to present enhancement opportunities to clients.

<recommendation_header>
  <title>[RECOMMENDATION_TITLE]</title>
  <product>[RELATED_PRODUCT]</product>
  <client>[CLIENT_NAME]</client>
  <date>[DATE]</date>
  <prepared_by>[PREPARER]</prepared_by>
</recommendation_header>

<opportunity>
  <description>
  [What enhancement is being recommended - 2-3 sentences]
  </description>

  <trigger>
  [What prompted this recommendation]
  - Health check finding
  - Client request
  - Market opportunity
  - Technical advancement
  - Competitive pressure
  </trigger>

  <alignment>
  [How this aligns with client's business goals]
  </alignment>
</opportunity>

<business_case>
  <current_state>
  [How things work now]
  - Process: [describe current workflow]
  - Pain points: [list current frustrations]
  - Costs: [time, money, opportunity cost of current state]
  </current_state>

  <proposed_state>
  [How things would work after enhancement]
  - Process: [describe improved workflow]
  - Benefits: [list improvements]
  - Experience: [how it feels different for users]
  </proposed_state>

  <value_quantification>
  [Be specific - use numbers]

  Time Savings:
  - Current: [X hours/week on this task]
  - After: [Y hours/week]
  - Savings: [X-Y hours/week = Z hours/year]
  - Value: [Z hours × $hourly_rate = $annual_savings]

  Revenue Impact:
  - [How this affects revenue - be specific]
  - Example: "Reduce checkout abandonment from 30% to 20% = $X additional revenue"

  Cost Reduction:
  - [Direct cost savings]
  - [Avoided costs]

  Risk Reduction:
  - [What risks are mitigated]
  - [Cost of risk if not mitigated]

  Total Estimated Annual Value: $[AMOUNT]
  </value_quantification>

  <roi_analysis>
  Investment: $[IMPLEMENTATION_COST]
  Annual Value: $[ANNUAL_VALUE]
  Payback Period: [X months]
  3-Year ROI: [X%]
  </roi_analysis>
</business_case>

<implementation_overview>
  <approach>
  [High-level implementation approach - 3-5 bullet points]
  - Phase 1: [description]
  - Phase 2: [description]
  </approach>

  <effort>
  Size: [S|M|L|XL]
  Estimated Duration: [X weeks]
  </effort>

  <dependencies>
  [What needs to be in place first]
  - [Dependency 1]
  - [Dependency 2]
  </dependencies>

  <risks>
  [Implementation risks and mitigation]
  - Risk: [description] | Mitigation: [approach]
  </risks>

  <team_requirements>
  - Client involvement: [hours/week, what decisions needed]
  - Technical resources: [what's needed]
  </team_requirements>
</implementation_overview>

<comparison>
  <options>
  [If there are multiple approaches, compare them]

  <option name="[Option 1]">
  Description: [what this option involves]
  Pros: [list advantages]
  Cons: [list disadvantages]
  Cost: $[amount]
  Timeline: [duration]
  </option>

  <option name="[Option 2]">
  Description: [what this option involves]
  Pros: [list advantages]
  Cons: [list disadvantages]
  Cost: $[amount]
  Timeline: [duration]
  </option>

  <recommendation>[Which option is recommended and why]</recommendation>
  </options>
</comparison>

<next_steps>
  <step order="1">
  [First action to take]
  Owner: [who]
  By: [date]
  </step>

  <step order="2">
  [Second action to take]
  Owner: [who]
  By: [date]
  </step>

  <step order="3">
  [Third action to take]
  Owner: [who]
  By: [date]
  </step>
</next_steps>

<appendix>
  <supporting_data>
  [Include any supporting data, screenshots, examples]
  </supporting_data>

  <references>
  [Links to relevant documentation, industry benchmarks, case studies]
  </references>
</appendix>

</template>

<usage_notes>
Best Practices:
- Lead with business value, not technical features
- Use client's language and terminology
- Include specific numbers whenever possible
- Show ROI clearly - this drives decisions
- Keep it concise - executives don't read long documents
- Include clear next steps

Value Quantification Tips:
- Time savings: hours × hourly rate
- Revenue: conversion improvement × transaction value × volume
- Risk: probability × impact
- Efficiency: before/after comparison with concrete numbers
</usage_notes>
