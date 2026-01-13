<overview>
A/B testing methodology for systematically optimizing marketing performance through controlled experiments.
</overview>

<testing_fundamentals>

<section name="what-is-ab-testing">
A/B testing (split testing) compares two versions of something to see which performs better. Traffic is randomly split between versions, and results are measured to determine a winner.
</section>

<section name="when-to-test">
Test when:
- You have sufficient traffic (100+ conversions per variant minimum)
- You have a clear hypothesis
- The potential impact justifies the effort
- You can run the test long enough

Don't test when:
- Traffic is too low
- You already know the answer
- The difference won't matter
- You can't implement the winner
</section>

<section name="testing-principles">
Test one variable at a time
If you change multiple things, you won't know what caused the difference.

Run tests to statistical significance
Don't call winners early. Wait for 95%+ confidence.

Have a clear hypothesis
"If I [change], then [metric] will [improve] because [reason]."

Document everything
Record what you tested, why, and the results.

Implement winners
Tests are worthless if you don't act on results.
</section>

</testing_fundamentals>

<what_to_test>

<category name="landing-pages">
High impact tests:
- Headlines (biggest impact usually)
- Call-to-action copy
- Button color and placement
- Hero image or video
- Social proof placement
- Form length/fields
- Page length (short vs long)
- Value proposition messaging

Lower impact but worth testing:
- Font and typography
- Color scheme
- Layout variations
- Navigation elements
</category>

<category name="email">
Subject line tests:
- Length (short vs long)
- Personalization (name vs no name)
- Emoji vs no emoji
- Question vs statement
- Curiosity vs benefit
- Urgency vs no urgency

Email body tests:
- Length (short vs long)
- Text vs HTML
- Number of links
- CTA button vs text link
- Image placement
- Personalization
- Sender name
</category>

<category name="ads">
Copy tests:
- Headlines
- Body copy
- Call-to-action
- Benefit angles
- Emotional vs rational

Creative tests:
- Image vs video
- Static vs carousel
- User-generated vs professional
- Face vs no face
- Product vs lifestyle

Targeting tests:
- Audience segments
- Placements
- Bidding strategies
</category>

<category name="checkout">
High impact tests:
- Number of steps
- Guest checkout option
- Trust badges
- Progress indicators
- Payment options
- Shipping presentation
- Urgency elements
- Exit intent offers
</category>

</what_to_test>

<testing_process>

<step num="1" name="identify-opportunity">
Look for:
- Pages with high traffic but low conversion
- Elements you suspect are underperforming
- Best practices you haven't implemented
- Competitor approaches you want to try

Prioritize by:
- Potential impact
- Traffic volume
- Ease of testing
- Confidence in hypothesis
</step>

<step num="2" name="form-hypothesis">
Structure: "If I [change], then [metric] will [increase/decrease] by [amount] because [reason]."

Example: "If I change the headline from feature-focused to benefit-focused, then opt-in rate will increase by 20% because visitors will better understand what they'll gain."

Bad hypothesis: "Let's try a different headline."
Good hypothesis: Specific, measurable, has rationale.
</step>

<step num="3" name="calculate-sample-size">
Use an A/B test calculator:
- Current conversion rate
- Minimum detectable effect (how big an improvement do you need?)
- Statistical significance level (typically 95%)
- Traffic per day

Example: With 2% conversion rate and 10% minimum detectable effect, you might need 15,000 visitors per variant.
</step>

<step num="4" name="set-up-test">
Technical setup:
- Use A/B testing tool (Google Optimize, VWO, Optimizely)
- Ensure random assignment
- Check tracking is working
- Test on all devices

Duration considerations:
- Run for at least one full week (capture day-of-week effects)
- Don't stop early even if one variant looks better
- Consider seasonal factors
</step>

<step num="5" name="run-test">
During the test:
- Don't peek and make decisions
- Monitor for technical issues
- Don't make other changes
- Let it run to completion

Quality assurance:
- Check both versions display correctly
- Verify tracking is accurate
- Watch for unusual patterns
</step>

<step num="6" name="analyze-results">
Check statistical significance:
- Is the result 95%+ significant?
- What's the confidence interval?
- Is the sample size adequate?

Look beyond the primary metric:
- Secondary metrics (time on page, bounce rate)
- Segment performance (mobile vs desktop, new vs returning)
- Revenue impact if applicable
</step>

<step num="7" name="implement-and-document">
If winner is clear:
- Implement the winning version
- Document the test and results
- Plan follow-up tests

If no clear winner:
- Consider extending the test
- Re-evaluate the hypothesis
- Test a different variable
</step>

</testing_process>

<common_mistakes>

<mistake name="stopping-early">
Problem: Calling a winner before reaching significance
Why it's wrong: Early results are often misleading
Solution: Pre-determine sample size and stick to it
</mistake>

<mistake name="testing-too-many-variables">
Problem: Changing multiple things at once
Why it's wrong: Can't isolate what caused the difference
Solution: One variable per test
</mistake>

<mistake name="ignoring-practical-significance">
Problem: Celebrating statistically significant but tiny improvements
Why it's wrong: 0.1% improvement may not be worth implementing
Solution: Set minimum effect threshold before testing
</mistake>

<mistake name="not-segmenting-results">
Problem: Only looking at overall results
Why it's wrong: One variant might win for mobile, lose for desktop
Solution: Analyze key segments
</mistake>

<mistake name="testing-low-traffic-pages">
Problem: Testing pages without enough traffic
Why it's wrong: Tests take forever and often inconclusive
Solution: Focus on high-traffic pages first
</mistake>

<mistake name="never-implementing">
Problem: Running tests but not implementing winners
Why it's wrong: Wasted effort if you don't act
Solution: Have implementation plan before testing
</mistake>

</common_mistakes>

<testing_roadmap>

<priority_1>
Start with highest-impact, easiest wins:
- Landing page headlines
- Email subject lines
- CTA button copy
- Ad headlines
</priority_1>

<priority_2>
Move to broader page elements:
- Page layout
- Form design
- Social proof placement
- Offer presentation
</priority_2>

<priority_3>
Test strategic elements:
- Pricing presentation
- Funnel structure
- Messaging angles
- Target audience segments
</priority_3>

<ongoing>
Continuous optimization:
- Iterate on past winners
- Test new ideas from data insights
- Re-test assumptions periodically
- Expand to new areas
</ongoing>

</testing_roadmap>
