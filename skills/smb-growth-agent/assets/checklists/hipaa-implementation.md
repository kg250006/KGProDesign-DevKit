<checklist name="hipaa-implementation">

<overview>
Implementation checklist for HIPAA-compliant healthcare solutions. Complete all required items before handling any Protected Health Information (PHI).
</overview>

<section name="technical_safeguards">

<item id="TS-1" required="true">
  <requirement>All PHI encrypted at rest using AES-256 or equivalent</requirement>
  <verification>
  - [ ] Database encryption enabled
  - [ ] File storage encryption enabled
  - [ ] Backup encryption enabled
  </verification>
  <evidence>Screenshot of encryption settings, encryption key management documentation</evidence>
</item>

<item id="TS-2" required="true">
  <requirement>All PHI encrypted in transit using TLS 1.2 or higher</requirement>
  <verification>
  - [ ] HTTPS enforced on all endpoints
  - [ ] Valid SSL certificate installed
  - [ ] HTTP redirects to HTTPS
  - [ ] API endpoints require TLS
  </verification>
  <evidence>SSL Labs scan results, certificate documentation</evidence>
</item>

<item id="TS-3" required="true">
  <requirement>Unique user identification for all system access</requirement>
  <verification>
  - [ ] Individual accounts for all users
  - [ ] No shared/generic accounts
  - [ ] User provisioning process documented
  - [ ] User deprovisioning process documented
  </verification>
  <evidence>User management documentation, account list audit</evidence>
</item>

<item id="TS-4" required="true">
  <requirement>Access controls limit PHI access to authorized users</requirement>
  <verification>
  - [ ] Role-based access control implemented
  - [ ] Principle of least privilege applied
  - [ ] Access rights documented by role
  - [ ] Access review process established
  </verification>
  <evidence>RBAC documentation, role-permission matrix</evidence>
</item>

<item id="TS-5" required="true">
  <requirement>Automatic logoff after period of inactivity</requirement>
  <verification>
  - [ ] Session timeout configured (15-30 minutes recommended)
  - [ ] Re-authentication required after timeout
  - [ ] Timeout applies to all interfaces
  </verification>
  <evidence>Session configuration settings, testing documentation</evidence>
</item>

<item id="TS-6" required="true">
  <requirement>Audit controls log all access to PHI</requirement>
  <verification>
  - [ ] All PHI access logged
  - [ ] Logs include who, what, when
  - [ ] Authentication attempts logged (success and failure)
  - [ ] Administrative actions logged
  - [ ] Logs protected from modification
  - [ ] Log retention meets requirements (6 years minimum)
  </verification>
  <evidence>Sample audit logs, log retention configuration</evidence>
</item>

<item id="TS-7" required="true">
  <requirement>Strong password/authentication requirements</requirement>
  <verification>
  - [ ] Minimum password complexity enforced
  - [ ] Password history enforced
  - [ ] Account lockout after failed attempts
  - [ ] Multi-factor authentication available (required for admin)
  </verification>
  <evidence>Password policy configuration, MFA documentation</evidence>
</item>

</section>

<section name="access_controls">

<item id="AC-1" required="true">
  <requirement>Workforce access to PHI based on job function</requirement>
  <verification>
  - [ ] Access rights defined for each role
  - [ ] Access requests require approval
  - [ ] Access removed when no longer needed
  - [ ] Regular access reviews conducted
  </verification>
  <evidence>Access request forms, review documentation</evidence>
</item>

<item id="AC-2" required="true">
  <requirement>Emergency access procedures documented</requirement>
  <verification>
  - [ ] Break-glass procedures defined
  - [ ] Emergency access logged
  - [ ] Post-emergency review process
  </verification>
  <evidence>Emergency access procedure documentation</evidence>
</item>

</section>

<section name="audit_controls">

<item id="AU-1" required="true">
  <requirement>Audit log review procedures established</requirement>
  <verification>
  - [ ] Regular log review schedule
  - [ ] Anomaly detection process
  - [ ] Incident response triggers defined
  </verification>
  <evidence>Log review procedures, sample review documentation</evidence>
</item>

</section>

<section name="integrity_controls">

<item id="IN-1" required="true">
  <requirement>Mechanisms to authenticate PHI integrity</requirement>
  <verification>
  - [ ] Data validation on input
  - [ ] Checksums or hashes for stored data
  - [ ] Version control for changes
  </verification>
  <evidence>Data integrity implementation documentation</evidence>
</item>

</section>

<section name="transmission_security">

<item id="TX-1" required="true">
  <requirement>PHI transmission over secure channels only</requirement>
  <verification>
  - [ ] No PHI in unencrypted email
  - [ ] Secure messaging for PHI if needed
  - [ ] API transmissions use TLS
  - [ ] File transfers use secure protocols
  </verification>
  <evidence>Transmission security configuration, email policy</evidence>
</item>

</section>

<section name="administrative_safeguards">

<item id="AD-1" required="true">
  <requirement>Security Risk Assessment completed</requirement>
  <verification>
  - [ ] Risk assessment documented
  - [ ] Threats and vulnerabilities identified
  - [ ] Risk levels assigned
  - [ ] Mitigation plans created
  - [ ] Assessment dated within 12 months
  </verification>
  <evidence>Risk assessment document</evidence>
</item>

<item id="AD-2" required="true">
  <requirement>Security policies and procedures documented</requirement>
  <verification>
  - [ ] Information security policy
  - [ ] Acceptable use policy
  - [ ] Access control policy
  - [ ] Incident response policy
  </verification>
  <evidence>Policy documents with approval dates</evidence>
</item>

<item id="AD-3" required="true">
  <requirement>Workforce security training completed</requirement>
  <verification>
  - [ ] Initial training for new workforce
  - [ ] Annual refresher training
  - [ ] Training records maintained
  </verification>
  <evidence>Training materials, completion records</evidence>
</item>

<item id="AD-4" required="true">
  <requirement>Incident response procedures documented</requirement>
  <verification>
  - [ ] Incident identification process
  - [ ] Incident response team identified
  - [ ] Escalation procedures defined
  - [ ] Communication plan for breaches
  - [ ] Post-incident review process
  </verification>
  <evidence>Incident response plan</evidence>
</item>

</section>

<section name="third_party_services">

<item id="TP-1" required="true">
  <requirement>Business Associate Agreements in place for all services handling PHI</requirement>
  <verification>
  - [ ] All services handling PHI identified
  - [ ] BAA signed with each service
  - [ ] BAAs stored and accessible
  - [ ] BAA renewal tracked
  </verification>
  <services_checklist>
  - [ ] Cloud hosting provider (AWS/Azure/GCP)
  - [ ] Database service (if managed)
  - [ ] Email service (if handling PHI)
  - [ ] Analytics service (if processing PHI)
  - [ ] Backup service
  - [ ] Other: ____________________
  </services_checklist>
  <evidence>Signed BAAs for all services</evidence>
</item>

<item id="TP-2" required="true">
  <requirement>Third-party service security verified</requirement>
  <verification>
  - [ ] Service is HIPAA-eligible
  - [ ] Security documentation reviewed
  - [ ] Configuration follows security guidance
  </verification>
  <evidence>Service HIPAA documentation, configuration review</evidence>
</item>

</section>

<section name="physical_safeguards">

<item id="PH-1" required="conditional">
  <requirement>Physical access controls (if applicable)</requirement>
  <applies_when>Physical servers or workstations access PHI</applies_when>
  <verification>
  - [ ] Server room access restricted
  - [ ] Workstation placement considered
  - [ ] Screen privacy filters if public-facing
  </verification>
  <evidence>Physical security documentation</evidence>
</item>

<item id="PH-2" required="true">
  <requirement>Device and media controls</requirement>
  <verification>
  - [ ] Encryption on devices accessing PHI
  - [ ] Remote wipe capability for mobile
  - [ ] Secure disposal procedures for media
  </verification>
  <evidence>Device management configuration, disposal procedures</evidence>
</item>

</section>

<summary>
Before launch with PHI:
- [ ] All required items completed
- [ ] Evidence documented for each item
- [ ] Security officer sign-off obtained
- [ ] BAAs in place for all third parties
- [ ] Workforce training completed
</summary>

</checklist>
