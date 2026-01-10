# PRD Template

Use this template structure when generating PRDs. Copy and fill in all sections.

```xml
<prd name="[feature-name]" version="1.0">

<metadata>
  <created>[YYYY-MM-DD]</created>
  <author>[Author name]</author>
  <status>[draft|review|approved|implemented]</status>
  <stakeholders>
    <stakeholder role="[Product Manager]">[Name]</stakeholder>
    <stakeholder role="[Engineering Lead]">[Name]</stakeholder>
  </stakeholders>
  <reviewers>
    <reviewer>[Name/Role]</reviewer>
  </reviewers>
</metadata>

<executive-summary>
  <problem>
    [Clear articulation of the problem being solved. Who has this problem?
    How are they currently dealing with it? What's the impact?]
  </problem>

  <solution>
    [High-level description of proposed solution. What will exist when done?
    How does it solve the problem?]
  </solution>

  <success-metrics>
    <metric name="[Metric Name]">
      <target>[Specific measurable target]</target>
      <measurement>[How it will be measured]</measurement>
    </metric>
  </success-metrics>

  <scope>
    <in-scope>
      <item>[Included functionality]</item>
    </in-scope>
    <out-of-scope>
      <item>[Explicitly excluded functionality]</item>
    </out-of-scope>
  </scope>
</executive-summary>

<user-stories>

  <story id="US1" priority="[P0|P1|P2]" persona="[user type]">
    <narrative>
      As a [specific user type],
      I want to [specific action],
      so that [measurable benefit].
    </narrative>

    <acceptance-criteria>
      <criterion id="AC1.1">
        Given [context/precondition],
        when [action/trigger],
        then [expected outcome].
      </criterion>
      <criterion id="AC1.2">
        Given [context],
        when [action],
        then [outcome].
      </criterion>
    </acceptance-criteria>

    <edge-cases>
      <case id="EC1.1">
        <scenario>[Unusual condition]</scenario>
        <expected-behavior>[How system should respond]</expected-behavior>
      </case>
    </edge-cases>
  </story>

  <story id="US2" priority="[P0|P1|P2]" persona="[user type]">
    <!-- Repeat structure -->
  </story>

</user-stories>

<requirements>

  <functional>
    <requirement id="F1" priority="[P0|P1|P2]" category="[core|integration|admin]">
      <title>[Short descriptive title]</title>
      <description>
        System shall [specific, testable behavior].
      </description>
      <rationale>[Why this is needed]</rationale>
      <acceptance-criteria>
        <criterion>[Testable outcome]</criterion>
      </acceptance-criteria>
      <dependencies>
        <dependency ref="[F2|NF1]">[Why dependent]</dependency>
      </dependencies>
    </requirement>

    <requirement id="F2" priority="[P0|P1|P2]" category="[category]">
      <!-- Repeat structure -->
    </requirement>
  </functional>

  <non-functional>
    <requirement id="NF1" category="performance">
      <title>[Requirement title]</title>
      <description>[Quality attribute requirement]</description>
      <metric>[Measurable target, e.g., "95th percentile < 200ms"]</metric>
      <measurement>[How it will be verified]</measurement>
    </requirement>

    <requirement id="NF2" category="security">
      <title>[Security requirement]</title>
      <description>[What must be secured]</description>
      <compliance>[Standards to meet, e.g., "OWASP Top 10"]</compliance>
    </requirement>

    <requirement id="NF3" category="scalability">
      <title>[Scalability requirement]</title>
      <description>[Capacity requirement]</description>
      <current>[Current capacity]</current>
      <target>[Target capacity]</target>
    </requirement>

    <requirement id="NF4" category="availability">
      <title>[Availability requirement]</title>
      <metric>[Uptime target, e.g., "99.9%"]</metric>
      <recovery-time>[RTO if applicable]</recovery-time>
    </requirement>

    <requirement id="NF5" category="accessibility">
      <title>[Accessibility requirement]</title>
      <standard>[e.g., "WCAG 2.1 Level AA"]</standard>
      <requirements>
        <item>[Specific accessibility requirement]</item>
      </requirements>
    </requirement>
  </non-functional>

</requirements>

<technical-design>

  <data-model>
    <entity name="[EntityName]">
      <description>[What this entity represents]</description>
      <attributes>
        <attribute name="id" type="unique-identifier" required="true"/>
        <attribute name="[field_name]" type="[string|number|boolean|datetime|enum]"
                   required="[true|false]"
                   constraints="[max-length:100|values:a,b,c|etc]"/>
      </attributes>
      <relationships>
        <relationship entity="[OtherEntity]"
                      cardinality="[one-to-one|one-to-many|many-to-many]"
                      name="[relationship_name]"/>
      </relationships>
      <business-rules>
        <rule>[Validation or constraint rule]</rule>
      </business-rules>
    </entity>
  </data-model>

  <api-contracts>
    <endpoint name="[Endpoint Name]">
      <method>[GET|POST|PUT|PATCH|DELETE]</method>
      <path>[/api/v1/resource]</path>
      <description>[What this endpoint does]</description>
      <authentication>[required|optional|none]</authentication>
      <authorization>[Roles/permissions required]</authorization>

      <request>
        <headers>
          <header name="[Header-Name]" required="[true|false]">[Description]</header>
        </headers>
        <query-params>
          <param name="[param]" type="[type]" required="[true|false]">[Description]</param>
        </query-params>
        <body content-type="application/json">
          <field name="[field]" type="[type]" required="[true|false]">[Description]</field>
        </body>
      </request>

      <responses>
        <response status="200" description="Success">
          <field name="[field]" type="[type]">[Description]</field>
        </response>
        <response status="400" description="Bad Request">
          <field name="error" type="string"/>
          <field name="details" type="object"/>
        </response>
        <response status="401" description="Unauthorized"/>
        <response status="404" description="Not Found"/>
        <response status="500" description="Server Error"/>
      </responses>
    </endpoint>
  </api-contracts>

  <integrations>
    <integration name="[External System]">
      <description>[What we integrate with]</description>
      <type>[API|webhook|database|file|message-queue]</type>
      <direction>[inbound|outbound|bidirectional]</direction>
      <data-exchanged>[What data flows]</data-exchanged>
      <failure-handling>[How to handle failures]</failure-handling>
    </integration>
  </integrations>

</technical-design>

<edge-cases>

  <category name="Data Validation">
    <case id="E1">
      <scenario>[Invalid input scenario]</scenario>
      <handling>[Expected system behavior]</handling>
      <user-message>[Message shown to user]</user-message>
    </case>
  </category>

  <category name="Concurrency">
    <case id="E2">
      <scenario>[Race condition or concurrent access]</scenario>
      <handling>[How system resolves]</handling>
    </case>
  </category>

  <category name="External Failures">
    <case id="E3">
      <scenario>[External service unavailable]</scenario>
      <handling>[Fallback behavior]</handling>
      <retry-policy>[If applicable]</retry-policy>
    </case>
  </category>

  <category name="Capacity Limits">
    <case id="E4">
      <scenario>[Limit reached]</scenario>
      <handling>[Behavior at limit]</handling>
      <user-communication>[How user is informed]</user-communication>
    </case>
  </category>

</edge-cases>

<security-considerations>
  <threat id="S1">
    <description>[Potential security threat]</description>
    <mitigation>[How it's addressed]</mitigation>
  </threat>
  <data-classification>
    <classification type="[PII|sensitive|public]">[Data covered]</classification>
  </data-classification>
</security-considerations>

<release-strategy>
  <phases>
    <phase name="Alpha">
      <audience>[Who gets access]</audience>
      <features>[What's included]</features>
      <success-criteria>[Exit criteria]</success-criteria>
    </phase>
    <phase name="Beta">
      <audience>[Expanded audience]</audience>
      <features>[Additional features]</features>
      <success-criteria>[Exit criteria]</success-criteria>
    </phase>
    <phase name="GA">
      <audience>[General availability]</audience>
      <features>[Full feature set]</features>
    </phase>
  </phases>
  <rollback-plan>
    <trigger>[When to rollback]</trigger>
    <procedure>[How to rollback]</procedure>
  </rollback-plan>
</release-strategy>

<appendix>
  <references>
    <reference>[Link to related documents]</reference>
  </references>
  <glossary>
    <term name="[Term]">[Definition]</term>
  </glossary>
  <revision-history>
    <revision version="1.0" date="[YYYY-MM-DD]" author="[Name]">
      [Change description]
    </revision>
  </revision-history>
</appendix>

</prd>
```

## Priority Levels Reference

| Priority | Meaning | Release Impact |
|----------|---------|----------------|
| P0 | Must have | Blocks launch |
| P1 | Should have | Important for launch |
| P2 | Nice to have | Can launch without |
| P3 | Future | Post-launch consideration |

## Non-Functional Categories

| Category | Focus Areas |
|----------|-------------|
| performance | Response time, throughput, latency |
| scalability | Users, data volume, geographic distribution |
| security | Authentication, authorization, encryption, compliance |
| availability | Uptime, disaster recovery, redundancy |
| maintainability | Logging, monitoring, debugging, documentation |
| accessibility | WCAG compliance, screen readers, keyboard navigation |
| localization | Languages, regions, currencies, date formats |
