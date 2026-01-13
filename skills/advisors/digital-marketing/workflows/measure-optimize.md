<required_reading>

Read these reference files:
1. references/kpi-framework.md
2. references/analytics-interpretation.md
3. references/ab-testing-strategy.md

</required_reading>

<process>

<step_1 name="define-kpis">

Identify key metrics per channel:

Website/SEO:
- Organic traffic (sessions, users)
- Keyword rankings
- Bounce rate
- Time on page
- Pages per session

Email:
- List size and growth rate
- Open rate
- Click-through rate
- Unsubscribe rate
- Revenue per email

Social Media:
- Follower growth
- Engagement rate (likes, comments, shares)
- Reach/impressions
- Click-through rate
- Conversions from social

Paid Advertising:
- Cost per click (CPC)
- Click-through rate (CTR)
- Cost per acquisition (CPA)
- Return on ad spend (ROAS)
- Quality/relevance score

Funnel Metrics:
- Opt-in rate
- Sales conversion rate
- Average order value
- Customer lifetime value (CLV)
- Cart abandonment rate

Set baseline and targets:
- Current performance (baseline)
- Target improvement (specific, measurable)
- Timeline for achievement

</step_1>

<step_2 name="setup-measurement">

Analytics tools configuration:

Website analytics:
- Google Analytics 4 (GA4) setup
- Goals/conversions configured
- E-commerce tracking (if applicable)
- Event tracking for key actions

UTM tracking strategy:
- Source: Where traffic comes from (facebook, google, email)
- Medium: Type of traffic (cpc, organic, email, social)
- Campaign: Specific campaign name
- Content: Variation or ad (optional)

Example: ?utm_source=facebook&utm_medium=cpc&utm_campaign=spring-sale&utm_content=video-ad-1

Dashboard creation:
- Weekly snapshot of key metrics
- Channel performance comparison
- Funnel visualization
- Goal tracking progress

Tools by need:
- Google Analytics: Website traffic, conversions
- Google Search Console: SEO performance
- Email platform analytics: Email metrics
- Social platform analytics: Social metrics
- Data studio/Looker: Custom dashboards

</step_2>

<step_3 name="analyze-performance">

Review metrics against goals:
- Are we on track to hit targets?
- What's trending up vs down?
- Are there anomalies to investigate?

Identify patterns and insights:
- Which content performs best?
- Which channels drive most value?
- What time/day performs best?
- Which audience segments convert best?

Calculate ROI:
- Revenue attributed to marketing
- Total marketing spend
- ROI = (Revenue - Cost) / Cost x 100

Attribution analysis:
- First-touch: What brought them in?
- Last-touch: What converted them?
- Multi-touch: Full journey contribution

Common analysis frameworks:
- Week over week comparison
- Month over month trends
- Year over year (seasonality)
- Campaign vs non-campaign periods

</step_3>

<step_4 name="optimize">

Form hypotheses from data:
"If we [change X], then [metric Y] will [improve/decrease] because [reason]."

Examples:
- "If we add more social proof to the landing page, conversion rate will increase because visitors will have more trust."
- "If we send emails on Tuesday instead of Monday, open rates will increase because people are less overwhelmed."

Design A/B tests:
- One variable at a time
- Sufficient sample size
- Clear success metric
- Defined test duration

High-impact test areas:
- Headlines and CTAs
- Pricing and offers
- Email subject lines
- Ad copy and creative
- Landing page layout

Implement winning variations:
- Document what was tested
- Record results
- Implement winner
- Plan next test

Optimization roadmap:
- Quick wins (easy changes, potential high impact)
- Medium-term improvements (more effort, proven impact)
- Long-term projects (significant investment)

</step_4>

</process>

<reporting_cadence>

<frequency name="daily">
What to check: Ad spend, major anomalies
Time: 5 minutes
</frequency>

<frequency name="weekly">
What to review: Key metrics vs goals, top/bottom performers
Time: 30 minutes
Action: Identify quick optimizations
</frequency>

<frequency name="monthly">
What to analyze: Full funnel performance, channel comparison, ROI
Time: 1-2 hours
Action: Strategic adjustments, report to stakeholders
</frequency>

<frequency name="quarterly">
What to evaluate: Overall strategy, goal progress, major pivots
Time: Half day
Action: Strategic planning, budget reallocation
</frequency>

</reporting_cadence>

<optimization_priorities>

Focus optimization efforts on:
1. Highest-volume stages first (more data, faster learning)
2. Biggest conversion drop-offs (lowest-hanging fruit)
3. Highest-value customer paths (optimize for best customers)
4. Proven channels before testing new ones

Avoid optimizing:
- With insufficient data (wait for statistical significance)
- Multiple variables at once (can't isolate impact)
- Things that don't matter to business goals (vanity metrics)

</optimization_priorities>

<success_criteria>
<criterion>KPIs defined with specific targets for each channel</criterion>
<criterion>Tracking implemented with UTM strategy documented</criterion>
<criterion>Regular reporting cadence established</criterion>
<criterion>Optimization roadmap created with prioritized tests</criterion>
<criterion>ROI calculation methodology documented</criterion>
</success_criteria>
