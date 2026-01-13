<overview>
Search engine optimization fundamentals covering on-page, off-page, and technical SEO.
</overview>

<seo_foundations>

<section name="how-search-works">

<component name="crawling">
Search engines discover pages by following links. Ensure:
- Site is crawlable (not blocked by robots.txt)
- Pages are linked internally
- Sitemap submitted to Google Search Console
</component>

<component name="indexing">
Search engines store and organize content. Ensure:
- Pages have unique, valuable content
- No duplicate content issues
- Pages aren't accidentally noindexed
</component>

<component name="ranking">
Search engines order results by relevance and quality. Key factors:
- Content relevance to query
- Page quality and authority
- User experience signals
- Technical health
</component>

</section>

<section name="keyword-research">

<process>
1. Brainstorm seed keywords
   - What would your audience search?
   - What problems do they have?
   - What solutions do they seek?

2. Expand with tools
   - Google Keyword Planner (free)
   - Ubersuggest (free tier)
   - Ahrefs, SEMrush (paid)
   - Answer the Public (questions)

3. Analyze metrics
   - Search volume (monthly searches)
   - Keyword difficulty (competition)
   - Search intent (what they want)

4. Prioritize keywords
   - Relevance to business
   - Reasonable difficulty
   - Commercial potential
   - Cluster into topics
</process>

<intent_types>
Informational: "how to train a dog" (seeking knowledge)
Navigational: "facebook login" (seeking specific site)
Transactional: "buy dog training course" (ready to purchase)
Commercial: "best dog training courses" (researching options)

Match content type to intent:
- Informational → blog posts, guides
- Transactional → product/sales pages
- Commercial → comparison posts, reviews
</intent_types>

</section>

</seo_foundations>

<on_page_seo>

<section name="title-tags">
Purpose: Primary ranking factor, appears in search results

Best practices:
- Include target keyword near beginning
- 50-60 characters
- Unique for every page
- Compelling for clicks

Formula: Primary Keyword - Secondary Keyword | Brand Name
Example: "Dog Training Tips for Beginners - Complete Guide | PetAcademy"
</section>

<section name="meta-descriptions">
Purpose: Appears in search results, influences CTR

Best practices:
- 150-160 characters
- Include target keyword
- Compelling reason to click
- Unique for every page
- Include CTA when appropriate

Example: "Learn effective dog training tips for beginners. Our step-by-step guide covers commands, behavior correction, and positive reinforcement. Start training today!"
</section>

<section name="header-tags">
Structure content with H1-H6:

H1: Main page title (one per page, includes keyword)
H2: Major sections (include keyword variations)
H3-H6: Subsections

Example structure:
H1: Complete Guide to Dog Training
  H2: Basic Commands Every Dog Should Know
    H3: Teaching "Sit"
    H3: Teaching "Stay"
  H2: Behavior Correction Techniques
    H3: Stopping Jumping
    H3: Reducing Barking
</section>

<section name="content-optimization">
Keyword placement:
- In first 100 words
- Naturally throughout content
- In at least one H2
- In image alt text
- In URL

Content quality signals:
- Comprehensive coverage of topic
- Unique insights or data
- Updated and accurate
- Well-formatted (lists, headers, images)
- Answers search intent completely
- Longer than competitors (when appropriate)
</section>

<section name="internal-linking">
Purpose: Helps users and search engines navigate site

Best practices:
- Link to related content
- Use descriptive anchor text
- Include links naturally in content
- Create topic clusters (pillar + supporting pages)
- Fix broken internal links

Example: "For more training techniques, see our guide to [positive reinforcement methods](/positive-reinforcement)."
</section>

<section name="image-optimization">
File optimization:
- Compress images (TinyPNG, ImageOptim)
- Use WebP format when possible
- Descriptive file names (dog-training-basics.jpg)

Alt text:
- Describe image accurately
- Include keyword naturally
- Keep under 125 characters
- Helpful for accessibility
</section>

<section name="url-structure">
Best practices:
- Short and descriptive
- Include target keyword
- Use hyphens between words
- Lowercase only
- Avoid parameters and IDs

Good: /dog-training-basics
Bad: /post?id=12345&category=pets
</section>

</on_page_seo>

<technical_seo>

<section name="site-speed">
Why it matters: Ranking factor, user experience

Optimization:
- Compress images
- Enable caching
- Minimize code (CSS, JS)
- Use CDN
- Choose fast hosting
- Lazy load images

Tools: Google PageSpeed Insights, GTmetrix
Target: Core Web Vitals passing
</section>

<section name="mobile-optimization">
Why it matters: Mobile-first indexing, majority of traffic

Requirements:
- Responsive design
- Fast mobile load time
- No horizontal scrolling
- Readable text without zooming
- Tap targets properly sized

Test: Google Mobile-Friendly Test
</section>

<section name="crawlability">
Ensure search engines can access:
- Robots.txt not blocking important pages
- XML sitemap submitted and updated
- No orphan pages (unlinked)
- Redirect chains resolved
- 404 errors fixed

Tools: Google Search Console, Screaming Frog
</section>

<section name="https">
Required: SSL certificate
- Ranking factor
- Browser security warnings without it
- Required for e-commerce

Most hosts provide free SSL (Let's Encrypt)
</section>

<section name="schema-markup">
Structured data helps search engines understand content:

Common types:
- Article
- Product
- Review
- FAQ
- How-to
- Local business

Benefits:
- Rich snippets in search results
- Featured snippet eligibility
- Knowledge panel information

Tool: Google Structured Data Testing Tool
</section>

</technical_seo>

<off_page_seo>

<section name="backlinks">
Definition: Links from other sites to yours

Quality factors:
- Relevance of linking site
- Authority of linking site
- Anchor text used
- Link placement (editorial vs footer)
- Follow vs nofollow

Earning backlinks:
- Create linkable content (data, research, tools)
- Guest posting on relevant sites
- Broken link building
- Digital PR and media coverage
- Industry partnerships
- Testimonials and case studies
</section>

<section name="link-building-tactics">

<tactic name="content-marketing">
Create content worth linking to:
- Original research and data
- Comprehensive guides
- Free tools and calculators
- Infographics
- Expert roundups
</tactic>

<tactic name="guest-posting">
Write for other sites:
- Find relevant blogs accepting guests
- Pitch unique angle
- Include natural link in content
- Build relationships
</tactic>

<tactic name="broken-link-building">
Find and replace broken links:
- Find pages with broken outbound links
- Create content that could replace
- Outreach to suggest replacement
</tactic>

<tactic name="digital-pr">
Earn media coverage:
- Newsworthy announcements
- Expert commentary
- Original research
- Industry trends
</tactic>

</section>

</off_page_seo>

<measurement>

<metrics>
Organic traffic: Visitors from search engines
Keyword rankings: Position for target keywords
Click-through rate: Clicks / impressions
Impressions: How often appearing in search
Backlinks: Quantity and quality
Domain authority: Overall site strength
</metrics>

<tools>
Free:
- Google Search Console (performance, errors)
- Google Analytics (traffic, behavior)

Paid:
- Ahrefs (backlinks, keywords, competitors)
- SEMrush (keywords, audit, tracking)
- Moz (domain authority, links)
</tools>

</measurement>
