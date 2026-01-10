# Workflow: Create PRD (Product Requirement Document)

<objective>
Generate a codebase-agnostic Product Requirement Document (PRD) that fully specifies what to build without dictating implementation details. The PRD can be handed to any qualified engineer or team to implement in any technology stack.
</objective>

<required_reading>
Before generating, read these references:
- @references/prd-best-practices.md
- @references/xml-structure-guide.md
</required_reading>

<process>

<step_1_discovery>
**Requirement Discovery**

Gather comprehensive requirements through questioning:

**Problem Space:**
- What problem are we solving?
- Who experiences this problem? (personas)
- How is it currently solved? (workarounds, competitors)
- What's the impact of not solving it?

**Solution Space:**
- What does success look like?
- What are the must-have features (MVP)?
- What are nice-to-have features (future)?
- What's explicitly out of scope?

**Constraints:**
- Technical constraints (integrations, platforms, data formats)
- Business constraints (timeline, budget, compliance)
- User constraints (accessibility, localization, offline)

Use AskUserQuestion to gather missing information. Don't proceed with assumptions.
</step_1_discovery>

<step_2_research>
**External Research**

Research the domain to ensure comprehensive coverage:

```
WebSearch: Industry best practices for [feature type]
WebSearch: Common pitfalls when implementing [feature]
WebSearch: User expectations for [feature category]
```

Document findings:
- Industry standards and conventions
- User expectations and mental models
- Common edge cases and error scenarios
- Security and compliance requirements
</step_2_research>

<step_3_user_stories>
**Write User Stories**

Create comprehensive user stories covering all personas:

```xml
<user-story id="US1" priority="P0" persona="end-user">
  <narrative>
    As a [specific user type],
    I want to [specific action],
    so that [measurable benefit].
  </narrative>
  <acceptance-criteria>
    <criterion id="AC1.1">Given [context], when [action], then [outcome]</criterion>
    <criterion id="AC1.2">Given [context], when [action], then [outcome]</criterion>
  </acceptance-criteria>
  <edge-cases>
    <case>What if [unusual condition]? Then [expected behavior]</case>
  </edge-cases>
</user-story>
```

**Priority Levels:**
- P0: Must have for MVP, blocking launch
- P1: Important, should have for launch
- P2: Nice to have, can launch without
- P3: Future consideration

Cover the full user journey, including:
- Happy path (everything works)
- Error paths (validation, failures)
- Edge cases (empty states, limits, concurrency)
- Admin/support scenarios
</step_3_user_stories>

<step_4_functional_requirements>
**Define Functional Requirements**

Enumerate specific system behaviors:

```xml
<requirements>
  <functional>
    <requirement id="F1" priority="P0" category="core">
      <title>User Authentication</title>
      <description>
        System shall authenticate users via email/password or OAuth providers.
      </description>
      <rationale>Users need secure, convenient access</rationale>
      <acceptance-criteria>
        <criterion>Users can register with email and password</criterion>
        <criterion>Users can login with Google OAuth</criterion>
        <criterion>Sessions expire after 24 hours of inactivity</criterion>
        <criterion>Failed login attempts are rate-limited (5 per minute)</criterion>
      </acceptance-criteria>
      <dependencies>
        <dependency ref="NF3">Security compliance requirements</dependency>
      </dependencies>
    </requirement>
  </functional>
</requirements>
```

Use clear, testable language:
- "System shall..." not "System should..."
- Specific values, not "reasonable time"
- Observable outcomes, not internal states
</step_4_functional_requirements>

<step_5_non_functional>
**Define Non-Functional Requirements**

Specify quality attributes with measurable targets:

```xml
<non-functional>
  <requirement id="NF1" category="performance">
    <title>Response Time</title>
    <description>API responses under normal load</description>
    <metric>95th percentile response time < 200ms</metric>
    <measurement>Measured via APM tool in production</measurement>
  </requirement>

  <requirement id="NF2" category="scalability">
    <title>Concurrent Users</title>
    <description>System capacity requirements</description>
    <metric>Support 10,000 concurrent users</metric>
    <growth>Scale to 100,000 within 12 months</growth>
  </requirement>

  <requirement id="NF3" category="security">
    <title>Data Protection</title>
    <description>Compliance and data handling</description>
    <requirements>
      <item>GDPR compliant data handling</item>
      <item>Data encrypted at rest and in transit</item>
      <item>PII access logged and auditable</item>
    </requirements>
  </requirement>

  <requirement id="NF4" category="availability">
    <title>Uptime SLA</title>
    <description>Service reliability target</description>
    <metric>99.9% uptime (8.76 hours downtime/year)</metric>
  </requirement>
</non-functional>
```

Categories to consider:
- Performance (response time, throughput)
- Scalability (users, data volume, growth)
- Security (auth, encryption, compliance)
- Availability (uptime, disaster recovery)
- Maintainability (logging, monitoring, debugging)
- Accessibility (WCAG level, screen readers)
- Localization (languages, regions, currencies)
</step_5_non_functional>

<step_6_data_model>
**Conceptual Data Model**

Define entities and relationships (technology-agnostic):

```xml
<data-model>
  <entity name="User">
    <description>System user account</description>
    <attributes>
      <attribute name="id" type="unique-identifier" required="true"/>
      <attribute name="email" type="email" required="true" unique="true"/>
      <attribute name="name" type="string" required="true" max-length="100"/>
      <attribute name="role" type="enum" values="user,admin,moderator"/>
      <attribute name="created_at" type="timestamp" required="true"/>
    </attributes>
    <relationships>
      <relationship entity="Post" cardinality="one-to-many" name="authored_posts"/>
      <relationship entity="Organization" cardinality="many-to-one" name="belongs_to"/>
    </relationships>
  </entity>
</data-model>
```

Include:
- All entities with their attributes
- Relationships and cardinalities
- Business rules (uniqueness, required fields)
- Data lifecycle (archival, deletion)
</step_6_data_model>

<step_7_api_contracts>
**API Contracts**

Define interfaces without implementation specifics:

```xml
<api-contracts>
  <endpoint name="Create User">
    <method>POST</method>
    <path>/users</path>
    <description>Register a new user account</description>
    <request>
      <body>
        <field name="email" type="email" required="true"/>
        <field name="password" type="string" required="true" min-length="8"/>
        <field name="name" type="string" required="true"/>
      </body>
    </request>
    <responses>
      <response status="201" description="User created successfully">
        <field name="id" type="unique-identifier"/>
        <field name="email" type="email"/>
        <field name="name" type="string"/>
        <field name="created_at" type="timestamp"/>
      </response>
      <response status="400" description="Invalid input">
        <field name="error" type="string"/>
        <field name="details" type="object"/>
      </response>
      <response status="409" description="Email already exists">
        <field name="error" type="string"/>
      </response>
    </responses>
  </endpoint>
</api-contracts>
```

Cover:
- All external-facing endpoints
- Request/response schemas
- Error codes and messages
- Authentication requirements
</step_7_api_contracts>

<step_8_edge_cases>
**Document Edge Cases**

Explicitly address unusual scenarios:

```xml
<edge-cases>
  <category name="Data Edge Cases">
    <case id="E1">
      <scenario>User submits form with empty required field</scenario>
      <expected>Validation error shown inline, form not submitted</expected>
    </case>
    <case id="E2">
      <scenario>User uploads file exceeding size limit</scenario>
      <expected>Clear error message with size limit, upload rejected</expected>
    </case>
  </category>

  <category name="Concurrency Edge Cases">
    <case id="E3">
      <scenario>Two users edit same resource simultaneously</scenario>
      <expected>Optimistic locking with conflict resolution UI</expected>
    </case>
  </category>

  <category name="Failure Edge Cases">
    <case id="E4">
      <scenario>External payment API timeout</scenario>
      <expected>Graceful degradation, retry with exponential backoff, user notification</expected>
    </case>
  </category>
</edge-cases>
```

Categories to cover:
- Data validation edge cases
- Concurrency and race conditions
- External service failures
- Network issues and timeouts
- Rate limiting and abuse
- Empty states and boundaries
</step_8_edge_cases>

<step_9_success_metrics>
**Define Success Metrics**

How will we know this feature succeeded?

```xml
<success-metrics>
  <metric name="Adoption Rate">
    <description>Percentage of users who use the feature</description>
    <target>30% within first month</target>
    <measurement>Feature usage / total active users</measurement>
  </metric>

  <metric name="Task Completion Rate">
    <description>Users who complete the intended workflow</description>
    <target>85% completion rate</target>
    <measurement>Completed actions / started actions</measurement>
  </metric>

  <metric name="Error Rate">
    <description>Percentage of attempts resulting in errors</description>
    <target>< 2% error rate</target>
    <measurement>Error events / total events</measurement>
  </metric>
</success-metrics>
```
</step_9_success_metrics>

<step_10_write_document>
**Write PRD Document**

Generate the complete PRD using @templates/prd-template.md structure.

Ensure:
- All sections are complete (no TODOs)
- Language is implementation-agnostic
- Acceptance criteria are testable
- Edge cases are comprehensive
- Metrics are measurable
</step_10_write_document>

<step_11_save>
**Save Document**

```bash
# Create directory if needed
mkdir -p PRDs

# Save document
Write: PRDs/PRD-{feature-name}.md
```

Report completion with summary.
</step_11_save>

</process>

<output_format>
## PRD Created

**Location:** `PRDs/PRD-{feature-name}.md`

**Summary:**
- User Stories: X (Y P0, Z P1)
- Functional Requirements: N
- Non-Functional Requirements: M
- API Endpoints: K
- Edge Cases Documented: J

**Completeness Score:** X/10
[Explanation: What's well-defined? What might need stakeholder input?]

**Next Steps:**
1. Share with stakeholders for review
2. Once approved, convert to PRP: `/skill software-architect` → "PRP from PRD"
3. Or hand to engineering team for their own implementation planning
</output_format>

<success_criteria>
- Document is codebase-agnostic (no file paths, no tech-specific syntax)
- All requirements have acceptance criteria
- Data models are complete with relationships
- API contracts cover all endpoints
- Edge cases are documented
- Success metrics are defined
- Any engineer could implement this in any stack
</success_criteria>

<anti_patterns>
Avoid these mistakes:
- Technology-specific language ("use React", "store in PostgreSQL")
- Vague requirements ("should be fast", "must be secure")
- Missing edge cases (only documenting happy path)
- Implementation details masquerading as requirements
- Assuming shared context (be explicit about everything)
- Skipping non-functional requirements
</anti_patterns>
