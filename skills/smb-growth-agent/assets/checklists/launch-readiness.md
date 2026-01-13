<checklist name="launch-readiness">

<overview>
Pre-launch verification checklist for production deployment. Complete all required items before going live.
</overview>

<section name="security">

<item id="SEC-1">
  <requirement>HTTPS enforced with valid certificate</requirement>
  <verification>
  - [ ] SSL certificate installed and valid
  - [ ] HTTP redirects to HTTPS
  - [ ] Certificate expiration date noted
  - [ ] Auto-renewal configured (if using Let's Encrypt)
  </verification>
</item>

<item id="SEC-2">
  <requirement>Security headers configured</requirement>
  <verification>
  - [ ] HSTS enabled
  - [ ] X-Content-Type-Options: nosniff
  - [ ] X-Frame-Options: DENY or SAMEORIGIN
  - [ ] Content-Security-Policy defined
  - [ ] X-XSS-Protection enabled
  </verification>
</item>

<item id="SEC-3">
  <requirement>No secrets in codebase</requirement>
  <verification>
  - [ ] API keys in environment variables
  - [ ] Database credentials in environment variables
  - [ ] No hardcoded passwords
  - [ ] .env files in .gitignore
  - [ ] Git history checked for leaked secrets
  </verification>
</item>

<item id="SEC-4">
  <requirement>Dependencies audited for vulnerabilities</requirement>
  <verification>
  - [ ] npm audit / pip-audit run
  - [ ] No critical vulnerabilities
  - [ ] High vulnerabilities addressed or mitigated
  - [ ] Dependency audit scheduled for ongoing
  </verification>
</item>

<item id="SEC-5">
  <requirement>Authentication and authorization working</requirement>
  <verification>
  - [ ] Login works correctly
  - [ ] Password reset works
  - [ ] Session management secure
  - [ ] Role-based access working
  - [ ] Unauthenticated access blocked where needed
  </verification>
</item>

<item id="SEC-6">
  <requirement>Input validation implemented</requirement>
  <verification>
  - [ ] All user inputs validated
  - [ ] SQL injection prevented
  - [ ] XSS attacks prevented
  - [ ] File upload restrictions in place (if applicable)
  </verification>
</item>

</section>

<section name="reliability">

<item id="REL-1">
  <requirement>Error handling and logging in place</requirement>
  <verification>
  - [ ] Errors logged with useful context
  - [ ] User-friendly error messages displayed
  - [ ] Sensitive data not exposed in errors
  - [ ] Error notification system configured
  </verification>
</item>

<item id="REL-2">
  <requirement>Backup and recovery tested</requirement>
  <verification>
  - [ ] Database backups configured
  - [ ] Backup schedule appropriate
  - [ ] Restore procedure tested
  - [ ] Backup verification automated
  - [ ] Backup location documented
  </verification>
</item>

<item id="REL-3">
  <requirement>Monitoring and alerting configured</requirement>
  <verification>
  - [ ] Uptime monitoring active
  - [ ] Error rate alerting configured
  - [ ] Performance monitoring in place
  - [ ] Alert recipients defined
  - [ ] Alert thresholds appropriate
  </verification>
</item>

<item id="REL-4">
  <requirement>Load and performance acceptable</requirement>
  <verification>
  - [ ] Page load times acceptable
  - [ ] API response times acceptable
  - [ ] Performance under expected load tested
  - [ ] Database query performance acceptable
  </verification>
</item>

</section>

<section name="functionality">

<item id="FUN-1">
  <requirement>Core features working correctly</requirement>
  <verification>
  - [ ] Primary user flows tested
  - [ ] Critical paths verified
  - [ ] Edge cases handled
  - [ ] Data saves correctly
  </verification>
</item>

<item id="FUN-2">
  <requirement>Cross-browser/device testing completed</requirement>
  <verification>
  - [ ] Chrome tested
  - [ ] Safari tested
  - [ ] Firefox tested
  - [ ] Mobile responsive verified
  - [ ] Target devices tested
  </verification>
</item>

<item id="FUN-3">
  <requirement>Forms and inputs working</requirement>
  <verification>
  - [ ] Form submissions work
  - [ ] Validation messages display
  - [ ] Required fields enforced
  - [ ] File uploads work (if applicable)
  </verification>
</item>

<item id="FUN-4">
  <requirement>Integrations verified</requirement>
  <verification>
  - [ ] Third-party APIs connected
  - [ ] Webhooks receiving
  - [ ] Data sync working
  - [ ] Authentication with external systems working
  </verification>
</item>

</section>

<section name="compliance">

<item id="COM-1">
  <requirement>Privacy policy published</requirement>
  <verification>
  - [ ] Privacy policy accessible
  - [ ] Privacy policy current
  - [ ] Cookie policy included (if applicable)
  - [ ] GDPR requirements met (if applicable)
  </verification>
</item>

<item id="COM-2">
  <requirement>Terms of service published</requirement>
  <verification>
  - [ ] Terms of service accessible
  - [ ] Terms of service current
  - [ ] User agreement flow working (if required)
  </verification>
</item>

<item id="COM-3">
  <requirement>Industry-specific compliance verified</requirement>
  <verification>
  - [ ] HIPAA requirements met (if healthcare)
  - [ ] PCI-DSS requirements met (if payments)
  - [ ] ADA/WCAG requirements met (if public-facing)
  - [ ] Industry-specific licenses obtained
  </verification>
</item>

</section>

<section name="documentation">

<item id="DOC-1">
  <requirement>User documentation available</requirement>
  <verification>
  - [ ] User guide/help available
  - [ ] FAQ section if needed
  - [ ] Support contact visible
  </verification>
</item>

<item id="DOC-2">
  <requirement>Admin/ops documentation created</requirement>
  <verification>
  - [ ] Deployment procedures documented
  - [ ] Environment variables documented
  - [ ] Runbook for common issues
  - [ ] Emergency procedures documented
  </verification>
</item>

<item id="DOC-3">
  <requirement>Technical documentation current</requirement>
  <verification>
  - [ ] README up to date
  - [ ] API documentation current
  - [ ] Architecture documented
  - [ ] Code comments adequate
  </verification>
</item>

</section>

<section name="deployment">

<item id="DEP-1">
  <requirement>Production environment configured</requirement>
  <verification>
  - [ ] Production server provisioned
  - [ ] Domain configured
  - [ ] DNS propagated
  - [ ] Environment variables set
  - [ ] SSL certificate active
  </verification>
</item>

<item id="DEP-2">
  <requirement>Deployment process tested</requirement>
  <verification>
  - [ ] Deployment to production tested
  - [ ] Rollback procedure documented
  - [ ] Deployment checklist available
  - [ ] Zero-downtime deployment (if required)
  </verification>
</item>

<item id="DEP-3">
  <requirement>DNS and domain ready</requirement>
  <verification>
  - [ ] Domain registered and accessible
  - [ ] DNS records configured
  - [ ] Email DNS records set (if applicable)
  - [ ] www and non-www handling
  </verification>
</item>

</section>

<section name="product_registry">

<item id="REG-1">
  <requirement>Product registered in registry</requirement>
  <verification>
  - [ ] Product added to product registry
  - [ ] All metadata captured
  - [ ] Compliance requirements noted
  - [ ] Technology stack documented
  </verification>
</item>

<item id="REG-2">
  <requirement>Maintenance schedule defined</requirement>
  <verification>
  - [ ] Review cadence set (quarterly recommended)
  - [ ] Next review date scheduled
  - [ ] Support scope documented
  - [ ] Emergency contact defined
  </verification>
</item>

<item id="REG-3">
  <requirement>Dependencies documented</requirement>
  <verification>
  - [ ] All dependencies listed
  - [ ] Version pinning in place
  - [ ] Update procedure documented
  - [ ] Dependency monitoring enabled
  </verification>
</item>

</section>

<section name="communication">

<item id="CMU-1">
  <requirement>Stakeholder communication prepared</requirement>
  <verification>
  - [ ] Launch announcement ready
  - [ ] User communication prepared
  - [ ] Support team briefed
  - [ ] Escalation path defined
  </verification>
</item>

<item id="CMU-2">
  <requirement>Post-launch monitoring plan</requirement>
  <verification>
  - [ ] First 24 hours monitoring plan
  - [ ] First week check-ins scheduled
  - [ ] Feedback collection mechanism
  - [ ] Issue triage process defined
  </verification>
</item>

</section>

<final_approval>
<signoff>
Launch Readiness Confirmed:

Technical Lead: _______________ Date: _______________
Client Approval: _______________ Date: _______________
</signoff>
</final_approval>

</checklist>
