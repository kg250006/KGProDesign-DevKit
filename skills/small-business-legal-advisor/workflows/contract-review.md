<objective>
Analyze contracts, highlight risks, and provide negotiation recommendations with plain language summaries.
</objective>

<required_reading>
@references/legal-concepts.md
</required_reading>

<process>

<step_1 name="intake">
Identify contract context:

Contract identification:
- What type of contract is this? (NDA, service agreement, employment, etc.)
- Who are the parties?
- Is the user the drafter or the reviewer?
- What is the user's role? (vendor/customer, employer/employee, licensor/licensee)

Business context:
- What is the business relationship?
- What are the key business terms already agreed upon?
- Any particular concerns or must-haves?
- What is the leverage in this negotiation?

Priority areas:
- What matters most in this contract?
- Any deal-breakers?
- Timeline and urgency?
</step_1>

<step_2 name="analysis">
Perform comprehensive contract analysis:

<analysis_categories>
Key Terms Extraction:
- Scope of work/services
- Payment terms
- Term and renewal
- Deliverables and milestones
- Performance standards

Liability Analysis:
- Indemnification obligations
- Limitation of liability
- Insurance requirements
- Warranty disclaimers

IP Provisions:
- Ownership of work product
- License grants
- Background IP protection
- IP indemnification

Termination Rights:
- Termination for convenience
- Termination for cause
- Notice requirements
- Wind-down obligations
- Survival clauses

Confidentiality:
- Definition of confidential information
- Exceptions
- Term of obligation
- Return/destruction obligations

Other Risk Areas:
- Non-compete/non-solicit
- Assignment restrictions
- Governing law and venue
- Dispute resolution
- Force majeure
</analysis_categories>

Risk rating for each area:
- HIGH: Significant exposure, strongly recommend changes
- MEDIUM: Elevated risk, suggest negotiation
- LOW: Standard terms, acceptable
</step_2>

<step_3 name="recommendations">
Provide actionable recommendations:

<output_format>
Plain Language Summary:
[2-3 paragraph summary of what this contract means for the user in everyday terms]

Key Terms Table:
| Term | What It Means | Risk Level | Recommendation |
|------|---------------|------------|----------------|
| [Term] | [Explanation] | [H/M/L] | [Action] |

Negotiation Points:
1. [HIGH PRIORITY: Specific issue and suggested alternative language]
2. [MEDIUM PRIORITY: Issue and alternative]
3. [LOWER PRIORITY: Nice-to-have changes]

Red Flags:
- [Any provisions that are unusually one-sided or concerning]

Missing Provisions:
- [Standard terms that should be added for protection]
</output_format>
</step_3>

<step_4 name="negotiation-strategy">
Provide negotiation guidance:

<strategy_elements>
Prioritization:
- Must-haves (deal-breakers if not resolved)
- Important (push hard but may concede)
- Nice-to-haves (propose but accept rejection)

Trade-offs:
- What you might give up to get priority items
- Package deals that benefit both parties

Language suggestions:
- Specific alternative language for key provisions
- Explanations of why alternatives are reasonable

Approach recommendations:
- Collaborative vs adversarial tone
- Email vs call for different issues
- When to involve attorneys
</strategy_elements>
</step_4>

</process>

<contract_type_guidance>

<type name="nda">
Key areas: Definition of confidential info, term, exceptions, return obligations
Common issues: Overly broad definitions, perpetual terms, one-sided
</type>

<type name="service-agreement">
Key areas: Scope, payment, liability cap, IP ownership, termination
Common issues: Unlimited liability, unfavorable IP terms, unclear scope
</type>

<type name="saas-subscription">
Key areas: SLA, data handling, renewal, price increases, termination
Common issues: Auto-renewal traps, broad data rights, no SLA remedies
</type>

<type name="employment">
Key areas: Compensation, equity, non-compete, IP assignment, termination
Common issues: Overbroad non-competes, unclear equity terms, at-will vs contract
</type>

<type name="contractor">
Key areas: Scope, IP ownership, payment, independent contractor status
Common issues: Misclassification risk, work product ownership unclear
</type>

</contract_type_guidance>

<disclaimer>
This analysis is for informational purposes only and does not constitute legal advice. Contract terms should be reviewed by a licensed attorney before execution. No attorney-client relationship is created.
</disclaimer>

<success_criteria>
<criterion>Contract type and parties correctly identified</criterion>
<criterion>Key terms summarized in plain language</criterion>
<criterion>Risk areas identified with ratings</criterion>
<criterion>Specific negotiation points provided with alternative language</criterion>
<criterion>Disclaimer included</criterion>
</success_criteria>
