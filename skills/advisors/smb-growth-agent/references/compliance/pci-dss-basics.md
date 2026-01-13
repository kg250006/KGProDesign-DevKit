<overview>
PCI-DSS compliance basics for payment processing in small business solutions. Focus on minimizing scope and leveraging payment processors to reduce compliance burden.
</overview>

<scope_definition>

<when_applies>
PCI-DSS applies when you:
- Store cardholder data
- Process cardholder data
- Transmit cardholder data

Cardholder data includes:
- Primary Account Number (PAN) - the card number
- Cardholder name
- Expiration date
- Service code

Sensitive authentication data (NEVER store):
- CVV/CVC
- PIN
- Full magnetic stripe data
</when_applies>

<scope_reduction>
The best compliance strategy for SMBs is to minimize scope:
- Use hosted payment pages (Stripe Checkout, PayPal)
- Let the payment processor handle card data
- Never let card numbers touch your servers
- This dramatically reduces compliance requirements
</scope_reduction>

</scope_definition>

<compliance_levels>

<level name="level-1">
Applies to: More than 6 million transactions/year
Requirements: Annual on-site audit by QSA, quarterly network scan
</level>

<level name="level-2">
Applies to: 1-6 million transactions/year
Requirements: Annual SAQ, quarterly network scan
</level>

<level name="level-3">
Applies to: 20,000 to 1 million e-commerce transactions/year
Requirements: Annual SAQ, quarterly network scan
</level>

<level name="level-4">
Applies to: Fewer than 20,000 e-commerce or up to 1 million other transactions
Requirements: Annual SAQ, quarterly network scan may be required
Most SMBs fall into this category.
</level>

</compliance_levels>

<saq_types>

<saq type="A">
For: Merchants using only hosted payment pages (card-not-present)
Scope: Card data never touches your systems
Effort: Minimal - approximately 22 questions
This is the goal for most SMBs.
</saq>

<saq type="A-EP">
For: E-commerce merchants who partially outsource but control website
Scope: Website affects payment page security
Effort: Moderate - approximately 139 questions
</saq>

<saq type="D">
For: Merchants who store, process, or transmit cardholder data
Scope: Full PCI-DSS requirements
Effort: Significant - approximately 329 questions
Avoid this if possible.
</saq>

</saq_types>

<recommended_approach>

<strategy name="hosted-payments">
Use hosted payment solutions to minimize scope:

Recommended Processors:
- Stripe: Stripe.js + Elements for SAQ A eligibility
- Square: Hosted checkout forms
- PayPal: PayPal Checkout
- Braintree: Drop-in UI

Implementation Pattern:
1. Customer enters payment info on processor's hosted form
2. Processor returns a token (not the card number)
3. Your server uses token to charge the card
4. You never see or handle the actual card number
</strategy>

<checklist name="saq-a-eligibility">
To qualify for SAQ A (minimal compliance burden):
- All payment processing outsourced to PCI-compliant provider
- No electronic storage of cardholder data
- No cardholder data on your systems or premises
- Confirm third-party payment solution is PCI-compliant
- Website does not receive or process cardholder data
</checklist>

</recommended_approach>

<key_requirements>

<requirement name="never-store-sensitive-auth">
NEVER store:
- CVV/CVC codes (the 3-4 digit security code)
- PIN numbers
- Full track data from magnetic stripe
These must never be stored after authorization, period.
</requirement>

<requirement name="protect-stored-data">
If you must store cardholder data (avoid if possible):
- Encrypt storage (AES-256)
- Limit access to need-to-know
- Document data flows
- Have data retention policy
- Securely delete when no longer needed
</requirement>

<requirement name="secure-transmission">
When transmitting cardholder data:
- Use TLS 1.2 or higher
- Never send via email or chat
- No unencrypted transmission
</requirement>

<requirement name="access-control">
Restrict access to cardholder data:
- Unique IDs for each user
- Restrict access based on job role
- Physical access controls
- Log all access
</requirement>

</key_requirements>

<anti_patterns>

<anti_pattern name="storing-card-numbers">
Problem: Building your own payment storage
Fix: Use tokenization from payment processor instead
</anti_pattern>

<anti_pattern name="direct-form-submission">
Problem: Card numbers submitted to your server then forwarded
Fix: Use JavaScript-based tokenization (Stripe.js) or iframes
</anti_pattern>

<anti_pattern name="logging-card-data">
Problem: Card numbers appearing in logs
Fix: Never log card data; sanitize all logging
</anti_pattern>

<anti_pattern name="email-card-numbers">
Problem: Accepting card numbers via email or chat
Fix: Direct customers to secure payment form
</anti_pattern>

<anti_pattern name="storing-cvv">
Problem: Saving CVV for "convenience"
Fix: Never store CVV - it's explicitly prohibited
</anti_pattern>

</anti_patterns>

<smb_recommendations>

<recommendation>
For most SMBs, the path of least resistance:
1. Choose Stripe, Square, or PayPal
2. Use their hosted payment UI
3. Never let card numbers touch your code
4. Complete SAQ A annually
5. Done - minimal compliance overhead
</recommendation>

<when_more_needed>
Consider full PCI compliance only if:
- Business requires storing card data (rare)
- Competitive advantage from seamless checkout
- Enterprise customers require it
In these cases, consult a QSA (Qualified Security Assessor).
</when_more_needed>

</smb_recommendations>
