# PRD Best Practices

<purpose>
Guidelines for creating clear, comprehensive, codebase-agnostic PRDs that any qualified engineer can implement in any technology stack.
</purpose>

<core_principles>

## 1. Specify What, Not How

PRDs describe outcomes, not implementations:

**Good (What):**
- "Users can authenticate via email/password or OAuth providers"
- "System returns search results within 200ms"
- "Data is encrypted at rest and in transit"

**Bad (How):**
- "Use bcrypt to hash passwords"
- "Implement Redis caching layer"
- "Store in PostgreSQL with indexes on user_id"

The implementation team decides the "how" based on their stack.

## 2. Requirements Are Testable

Every requirement should have a clear pass/fail criterion:

**Testable:**
- "Login form displays error message when credentials are invalid"
- "API responds with 401 status when token is expired"
- "System processes 1000 requests per second without errors"

**Not Testable:**
- "Login should be user-friendly"
- "API should be fast"
- "System should scale well"

## 3. Cover the Complete User Journey

Don't just document the happy path:

**Happy Path:** User logs in successfully
**Error Paths:**
- Wrong password
- Account locked
- Email not found
- Session expired

**Edge Cases:**
- Multiple simultaneous logins
- Login during password reset
- OAuth provider unavailable

## 4. Prioritize Ruthlessly

Use priority levels consistently:

| Priority | Meaning | Impact |
|----------|---------|--------|
| P0 | Must have | Feature doesn't work without it |
| P1 | Should have | Significantly worse without it |
| P2 | Nice to have | Adds value but not essential |
| P3 | Future | Out of scope for this release |

Be honest about P0s. If everything is P0, nothing is.

## 5. Be Explicit About Scope

State what's in and out clearly:

```xml
<scope>
  <in-scope>
    <item>User registration with email verification</item>
    <item>Password reset flow</item>
    <item>Session management</item>
  </in-scope>
  <out-of-scope>
    <item>Two-factor authentication (future)</item>
    <item>Social login beyond Google/GitHub (future)</item>
    <item>Admin user management (separate PRD)</item>
  </out-of-scope>
</scope>
```

</core_principles>

<user_stories>

## Writing Effective User Stories

### Structure

```
As a [specific persona],
I want to [concrete action],
so that [measurable benefit].
```

### Examples

**Good:**
```
As a new customer,
I want to create an account with my email,
so that I can save my preferences across devices.
```

**Bad:**
```
As a user,
I want to sign up,
so that I can use the app.
```

### Acceptance Criteria Format (Given-When-Then)

```
Given I am on the registration page,
When I enter a valid email and password and click "Sign Up",
Then I receive a verification email within 5 minutes
And I see a confirmation message with next steps.
```

### Common Mistakes

1. **Too vague:** "As a user, I want a good experience"
2. **Too technical:** "As a user, I want my data stored in the database"
3. **Multiple stories combined:** Use one story per distinct behavior
4. **Missing acceptance criteria:** Every story needs verifiable outcomes

</user_stories>

<requirements_writing>

## Writing Clear Requirements

### Use "Shall" for Requirements

```
The system shall validate email format before submission.
The system shall expire sessions after 24 hours of inactivity.
The system shall log all authentication attempts.
```

### Be Specific with Numbers

```xml
<!-- Bad -->
<requirement>System should be fast</requirement>

<!-- Good -->
<requirement id="NF1">
  <description>API response time under normal load</description>
  <metric>95th percentile response time < 200ms</metric>
  <conditions>Up to 1000 concurrent users</conditions>
</requirement>
```

### Link Related Requirements

```xml
<requirement id="F3" priority="P0">
  <title>Password Reset</title>
  <dependencies>
    <dependency ref="F1">User registration (user must exist)</dependency>
    <dependency ref="NF2">Email delivery service</dependency>
  </dependencies>
</requirement>
```

</requirements_writing>

<data_modeling>

## Conceptual Data Modeling

PRDs define entities and relationships without database specifics:

```xml
<entity name="Order">
  <description>Customer purchase order</description>
  <attributes>
    <attribute name="id" type="unique-identifier"/>
    <attribute name="status" type="enum"
               values="pending,paid,shipped,delivered,cancelled"/>
    <attribute name="total_amount" type="currency"/>
    <attribute name="placed_at" type="timestamp"/>
  </attributes>
  <relationships>
    <relationship entity="Customer" cardinality="many-to-one"/>
    <relationship entity="OrderItem" cardinality="one-to-many"/>
  </relationships>
  <business-rules>
    <rule>Total amount must equal sum of item amounts</rule>
    <rule>Cannot cancel after status is "shipped"</rule>
  </business-rules>
</entity>
```

**Include:**
- Entity purpose
- Attributes with types
- Relationships with cardinality
- Business rules and constraints

**Exclude:**
- Table names
- Column types (varchar, int, etc.)
- Indexes
- Database-specific features

</data_modeling>

<api_contracts>

## Technology-Agnostic API Contracts

Define interfaces without implementation:

```xml
<endpoint name="Create Order">
  <method>POST</method>
  <path>/orders</path>
  <authentication>required</authentication>

  <request>
    <field name="items" type="array" required="true">
      <item-schema>
        <field name="product_id" type="identifier"/>
        <field name="quantity" type="integer" min="1"/>
      </item-schema>
    </field>
    <field name="shipping_address_id" type="identifier" required="true"/>
  </request>

  <responses>
    <response status="201">
      <field name="id" type="identifier"/>
      <field name="status" type="string"/>
      <field name="total" type="currency"/>
    </response>
    <response status="400">
      <field name="error" type="string"/>
      <field name="invalid_fields" type="array"/>
    </response>
  </responses>
</endpoint>
```

</api_contracts>

<edge_cases>

## Documenting Edge Cases

Organize by category:

### Data Validation
- Empty required fields
- Values exceeding limits
- Invalid formats (email, phone)
- Duplicate entries

### Timing and Concurrency
- Simultaneous updates
- Expired sessions mid-action
- Stale data display

### External Dependencies
- Third-party service down
- Slow network response
- Partial failures

### Business Logic
- Zero-quantity orders
- Negative amounts
- Edge of date ranges

For each edge case, document:
1. The scenario
2. Expected system behavior
3. User communication (if any)

</edge_cases>

<common_mistakes>

## Common PRD Mistakes

### 1. Technology Assumptions
```xml
<!-- Bad: Assumes React -->
<requirement>Component shall use useState for form state</requirement>

<!-- Good: Technology-agnostic -->
<requirement>Form shall maintain state across field changes until submission</requirement>
```

### 2. Incomplete Edge Cases
Only documenting happy paths leads to undefined behavior.

### 3. Vague Metrics
```xml
<!-- Bad -->
<metric>System should be scalable</metric>

<!-- Good -->
<metric>Support 100,000 daily active users with <500ms response time</metric>
```

### 4. Missing Stakeholder Context
Who requested this? Who approves? Who's impacted?

### 5. No Success Metrics
How will we know this feature succeeded after launch?

</common_mistakes>

<stakeholder_communication>

## Writing for Different Audiences

PRDs serve multiple readers. Structure for scanning:

### Executive Summary
- One paragraph on problem and solution
- Key metrics and timeline
- Business impact

### Product/Design Team
- User stories and journeys
- Acceptance criteria
- Edge cases and error states

### Engineering Team
- Data models and relationships
- API contracts
- Non-functional requirements
- Integration points

### QA Team
- Acceptance criteria (primary source)
- Edge cases
- Success metrics for testing

Use clear headings, bullet points, and tables for scannability.

</stakeholder_communication>
