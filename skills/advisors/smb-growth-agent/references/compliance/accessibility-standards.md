<overview>
ADA and WCAG accessibility requirements for public-facing web applications. Ensuring digital accessibility protects against legal risk and expands your audience.
</overview>

<legal_context>

<ada>
Americans with Disabilities Act (ADA):
- Title III applies to "places of public accommodation"
- Courts have increasingly applied this to websites
- No explicit web standards in ADA, but WCAG is the de facto benchmark
- Lawsuits against inaccessible websites are increasing
</ada>

<section_508>
Section 508:
- Applies to federal agencies and federal contractors
- Requires WCAG 2.0 AA compliance
- If you work with federal government, this is mandatory
</section_508>

<state_laws>
Various states have accessibility requirements:
- California: Unruh Civil Rights Act
- New York: State and city human rights laws
Check local requirements for your operating states.
</state_laws>

</legal_context>

<wcag_levels>

<level name="A">
Minimum level - basic accessibility
Essential for: Any web content
Addresses: Most severe barriers
Example Requirements:
- Non-text content has text alternatives
- Captions for pre-recorded audio
- Content can be navigated without color
</level>

<level name="AA">
Target level for most organizations
Industry standard - legal benchmark
Example Requirements:
- All Level A requirements
- Captions for live audio
- Color contrast ratio of 4.5:1 for normal text
- Resize text to 200% without loss of content
- Multiple ways to find pages
</level>

<level name="AAA">
Highest level - enhanced accessibility
Not typically required but shows commitment
Example Requirements:
- All Level A and AA requirements
- Sign language interpretation for video
- Color contrast ratio of 7:1
- No timing on interactions
</level>

<recommendation>
For SMBs: Target WCAG 2.1 AA compliance
This is the industry standard and legal safe harbor.
</recommendation>

</wcag_levels>

<pour_principles>

<principle name="perceivable">
Users must be able to perceive the information
Requirements:
- Text alternatives for images (alt text)
- Captions for video
- Audio descriptions for video (or transcript)
- Sufficient color contrast
- Content works without color alone
- Text can be resized without breaking layout
</principle>

<principle name="operable">
Users must be able to operate the interface
Requirements:
- All functionality available from keyboard
- No keyboard traps
- Skip navigation links
- Descriptive page titles
- Logical focus order
- Visible focus indicators
- No flashing content (seizure risk)
- Sufficient time to complete tasks
</principle>

<principle name="understandable">
Users must be able to understand content and interface
Requirements:
- Page language specified
- Consistent navigation
- Consistent identification of elements
- Error identification and suggestions
- Labels for form inputs
- Clear instructions
</principle>

<principle name="robust">
Content must work with assistive technologies
Requirements:
- Valid HTML
- Name, role, value for custom components
- Status messages can be programmatically determined
- Compatible with screen readers
</principle>

</pour_principles>

<implementation_checklist>

<category name="images">
- [ ] All images have alt text
- [ ] Decorative images have empty alt (alt="")
- [ ] Complex images have long descriptions
- [ ] Text in images also available as real text
</category>

<category name="forms">
- [ ] All form inputs have associated labels
- [ ] Required fields are indicated
- [ ] Error messages are clear and helpful
- [ ] Form errors are announced to screen readers
- [ ] Logical tab order
</category>

<category name="navigation">
- [ ] Skip to main content link
- [ ] Consistent navigation across pages
- [ ] Descriptive link text (not "click here")
- [ ] Focus visible on all interactive elements
- [ ] Logical heading hierarchy (h1, h2, h3)
</category>

<category name="color-contrast">
- [ ] Normal text: 4.5:1 contrast ratio minimum
- [ ] Large text (18pt+): 3:1 contrast ratio minimum
- [ ] UI components: 3:1 contrast ratio
- [ ] Information not conveyed by color alone
</category>

<category name="keyboard">
- [ ] All functionality keyboard accessible
- [ ] No keyboard traps
- [ ] Visible focus indicator
- [ ] Logical focus order
</category>

<category name="media">
- [ ] Videos have captions
- [ ] Audio has transcripts
- [ ] No auto-playing media with sound
- [ ] No flashing content (more than 3 flashes/second)
</category>

</implementation_checklist>

<testing_tools>

<tool name="automated">
Catches approximately 30-40% of issues:
- axe (browser extension) - Most comprehensive
- WAVE (browser extension) - Visual feedback
- Lighthouse (built into Chrome) - Quick audit
- Pa11y (CLI tool) - CI/CD integration
</tool>

<tool name="manual">
Required for complete testing:
- Keyboard-only navigation testing
- Screen reader testing (NVDA, VoiceOver, JAWS)
- Zoom testing (200% text size)
- Color blindness simulators
</tool>

<tool name="user-testing">
Most valuable but resource-intensive:
- Test with actual users who use assistive technology
- Identify real-world barriers automated tests miss
- Provides prioritization based on actual impact
</tool>

</testing_tools>

<common_issues>

<issue name="missing-alt-text">
Problem: Images without alt attributes
Impact: Screen reader users don't know what images show
Fix: Add descriptive alt text to all meaningful images
</issue>

<issue name="poor-contrast">
Problem: Light gray text on white background
Impact: Hard to read for low vision users
Fix: Use contrast checker, ensure 4.5:1 ratio minimum
</issue>

<issue name="no-keyboard-access">
Problem: Custom components only work with mouse
Impact: Keyboard and screen reader users cannot interact
Fix: Add keyboard handlers, ARIA roles, focus management
</issue>

<issue name="missing-form-labels">
Problem: Input fields without associated labels
Impact: Screen reader users don't know what to enter
Fix: Use label elements with for attribute
</issue>

<issue name="improper-heading-structure">
Problem: Headings used for styling, not structure
Impact: Screen reader navigation is confusing
Fix: Use headings semantically (h1, h2, h3 in order)
</issue>

</common_issues>

<quick_wins>

<win effort="low" impact="high">
Add alt text to all images
</win>

<win effort="low" impact="high">
Add skip navigation link
</win>

<win effort="low" impact="medium">
Fix color contrast issues
</win>

<win effort="medium" impact="high">
Add labels to all form inputs
</win>

<win effort="medium" impact="high">
Fix heading hierarchy
</win>

<win effort="medium" impact="medium">
Add focus visible styles
</win>

</quick_wins>
