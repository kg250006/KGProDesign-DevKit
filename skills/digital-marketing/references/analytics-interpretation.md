<overview>
Guide to interpreting marketing analytics data and turning insights into action.
</overview>

<interpretation_framework>

<section name="ask-right-questions">

Before diving into data:
1. What decision are we trying to make?
2. What would change our approach?
3. What's the hypothesis we're testing?
4. What's the business context?

Example: Instead of "How did our emails perform?" ask "Should we continue this subject line style or try something different?"
</section>

<section name="look-for-patterns">

Time patterns:
- Day of week performance
- Time of day trends
- Seasonal variations
- Month-over-month trends

Segment patterns:
- Device differences (mobile vs desktop)
- Geographic variations
- Traffic source performance
- Customer type behavior

Content patterns:
- Which topics perform best
- Which formats get engagement
- Which CTAs convert
- Which headlines attract clicks
</section>

<section name="context-matters">

Always consider:
- Sample size (is it statistically significant?)
- External factors (holidays, news, competition)
- Technical issues (tracking problems, site changes)
- Campaign timing (was something else running?)
- Baseline performance (what's normal?)
</section>

</interpretation_framework>

<common_scenarios>

<scenario name="traffic-dropped">
Possible causes:
- Algorithm change (SEO)
- Seasonal trend
- Campaign ended
- Technical issue
- Competition

Investigation steps:
1. Check which traffic source dropped
2. Compare to same period last year
3. Verify tracking is working
4. Check for site changes or errors
5. Review search console for SEO issues
6. Check if campaigns are running as expected
</scenario>

<scenario name="conversion-rate-dropped">
Possible causes:
- Traffic quality changed
- Landing page issues
- Offer fatigue
- Technical problems
- Pricing concerns
- Competition

Investigation steps:
1. Check conversion by traffic source
2. Check conversion by device
3. Review landing page changes
4. Test checkout process
5. Check page load speed
6. Review heatmaps and recordings
</scenario>

<scenario name="email-engagement-declined">
Possible causes:
- List fatigue
- Deliverability issues
- Content relevance
- Sending frequency
- Subject line effectiveness
- List growth quality

Investigation steps:
1. Check engagement by segment
2. Review deliverability metrics
3. Compare recent vs historical subjects
4. Look at list growth sources
5. Check spam complaints
6. Test with smaller segments
</scenario>

<scenario name="ad-performance-declined">
Possible causes:
- Ad fatigue
- Audience saturation
- Increased competition
- Algorithm changes
- Landing page issues
- Seasonal factors

Investigation steps:
1. Check frequency (are people seeing too often?)
2. Review creative performance
3. Compare audience performance
4. Check landing page conversion
5. Review competitor activity
6. Test new creative/copy
</scenario>

<scenario name="high-traffic-low-conversion">
Possible causes:
- Wrong traffic (not target audience)
- Poor landing page
- Misaligned messaging
- Price/offer issues
- Trust concerns
- Technical barriers

Investigation steps:
1. Analyze traffic source quality
2. Review landing page experience
3. Check message match (ad to page)
4. Survey visitors or run polls
5. Review user recordings
6. Test different offers
</scenario>

</common_scenarios>

<analysis_techniques>

<technique name="cohort-analysis">
Purpose: Track how groups behave over time

Example: Compare customers acquired in January vs. February to see retention differences.

How to use:
1. Define cohorts (by acquisition date, channel, etc.)
2. Track behavior over same time period
3. Compare performance across cohorts
4. Identify what differs in high-performing cohorts
</technique>

<technique name="segmentation">
Purpose: Find differences within your audience

Common segments:
- Traffic source
- Device type
- Geographic location
- Customer type (new vs returning)
- Acquisition channel
- Product category
- Price point

Action: Optimize for best segments, understand underperformers
</technique>

<technique name="funnel-analysis">
Purpose: Find where people drop off

Process:
1. Define funnel stages
2. Measure conversion at each step
3. Identify biggest drop-offs
4. Hypothesize reasons
5. Test improvements

Example funnel:
Homepage (100%) → Product page (40%) → Add to cart (15%) → Checkout (10%) → Purchase (5%)

Focus optimization on largest drop-offs first.
</technique>

<technique name="ab-test-analysis">
Purpose: Determine which version performs better

Requirements:
- Sufficient sample size (use calculator)
- Statistical significance (95%+ confidence)
- Adequate test duration
- Single variable tested

Interpretation:
- Check if result is statistically significant
- Look at confidence interval
- Consider practical significance (is the difference meaningful?)
- Check for segment differences
</technique>

<technique name="attribution-analysis">
Purpose: Understand which touchpoints drive conversions

Models:
- Last click: Credit to final touchpoint
- First click: Credit to initial touchpoint
- Linear: Equal credit to all touchpoints
- Time decay: More credit to recent touchpoints
- Position-based: 40% first, 40% last, 20% middle

Use: Compare models to understand full customer journey
</technique>

</analysis_techniques>

<turning_insights_to_action>

<framework>
For each insight:
1. What is the observation? (Data point)
2. What might it mean? (Interpretation)
3. So what? (Implication for business)
4. Now what? (Specific action to take)
</framework>

<example>
Observation: Mobile conversion rate is 50% lower than desktop
Interpretation: Mobile experience may have friction
Implication: We're losing revenue from mobile visitors
Action: Run mobile UX audit, simplify mobile checkout, test mobile-specific improvements
</example>

<prioritization>
Score actions by:
- Impact (High/Medium/Low)
- Effort (High/Medium/Low)
- Confidence (High/Medium/Low)

Prioritize: High impact, low effort, high confidence first
</prioritization>

</turning_insights_to_action>

<reporting_best_practices>

<practice name="lead-with-insights">
Don't just show numbers - explain what they mean and why they matter.

Bad: "Open rate was 25%"
Good: "Open rate was 25%, up from 22% last month. The subject line test showed personal questions outperform statements by 3x."
</practice>

<practice name="compare-to-context">
Always provide comparison:
- vs. previous period
- vs. same period last year
- vs. target/goal
- vs. benchmark
</practice>

<practice name="recommend-action">
End with what to do next:
- Continue what's working
- Stop what's not
- Test new approaches
- Investigate anomalies
</practice>

</reporting_best_practices>
