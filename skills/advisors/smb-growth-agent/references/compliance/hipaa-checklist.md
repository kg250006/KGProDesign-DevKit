<overview>
HIPAA compliance requirements for healthcare technology solutions. Use this checklist to ensure solutions handling Protected Health Information (PHI) meet regulatory requirements.
</overview>

<phi_definition>
Protected Health Information (PHI) includes:
- Patient names
- Dates (birth, admission, discharge, death)
- Phone numbers, fax numbers
- Email addresses
- Social Security numbers
- Medical record numbers
- Health plan beneficiary numbers
- Account numbers
- Device identifiers and serial numbers
- Biometric identifiers
- Full face photos
- Any other unique identifying number

PHI applies when combined with health information - a name alone isn't PHI, but a name linked to a diagnosis is.
</phi_definition>

<technical_safeguards>

<safeguard name="encryption">
Requirement: PHI must be encrypted at rest and in transit
At Rest:
- Database encryption (AES-256 recommended)
- File storage encryption
- Backup encryption
In Transit:
- TLS 1.2 or higher for all connections
- No PHI transmitted over unencrypted channels
- HTTPS enforced for web applications
</safeguard>

<safeguard name="access-controls">
Requirement: Unique user identification and access controls
Implementation:
- Unique user accounts (no shared logins)
- Role-based access control (RBAC)
- Principle of least privilege
- Automatic session timeout
- Strong password requirements
- Multi-factor authentication recommended
</safeguard>

<safeguard name="audit-controls">
Requirement: Log all access to PHI
Implementation:
- Log who accessed what PHI when
- Log authentication attempts (success and failure)
- Log administrative actions
- Retain logs for 6 years minimum
- Protect logs from tampering
</safeguard>

<safeguard name="transmission-security">
Requirement: Protect PHI during electronic transmission
Implementation:
- End-to-end encryption for messaging
- Secure file transfer protocols
- Email encryption for PHI
- VPN for remote access to systems containing PHI
</safeguard>

</technical_safeguards>

<administrative_safeguards>

<safeguard name="risk-analysis">
Requirement: Conduct regular risk assessments
Frequency: Annual minimum, or when significant changes occur
Scope:
- Identify all systems containing PHI
- Assess threats and vulnerabilities
- Evaluate current security measures
- Document findings and remediation plans
</safeguard>

<safeguard name="workforce-training">
Requirement: Train all workforce members
Topics:
- What is PHI
- Acceptable use policies
- Security best practices
- Incident reporting procedures
- Social engineering awareness
Frequency: At hire and annually thereafter
</safeguard>

<safeguard name="security-incident-procedures">
Requirement: Document and follow incident response procedures
Process:
1. Detection and reporting
2. Containment
3. Investigation
4. Notification (if breach)
5. Remediation
6. Post-incident review
</safeguard>

</administrative_safeguards>

<physical_safeguards>

<safeguard name="device-security">
For workstations and devices accessing PHI:
- Screen locks
- Encrypted hard drives
- Remote wipe capability for mobile devices
- Secure disposal procedures
</safeguard>

<safeguard name="facility-access">
For physical locations containing PHI:
- Access controls to server rooms
- Visitor logs
- Secure disposal of paper records
- Clean desk policies
</safeguard>

</physical_safeguards>

<baa_requirements>

<definition>
Business Associate Agreement (BAA): Required contract between covered entity and any service provider that creates, receives, maintains, or transmits PHI on their behalf.
</definition>

<when_required>
A BAA is required for:
- Cloud hosting providers (AWS, Azure, GCP)
- Database services
- Email providers handling PHI
- Analytics services processing PHI
- Backup and disaster recovery services
- IT support with system access
- Any vendor that may access PHI
</when_required>

<key_provisions>
BAA must include:
- Description of permitted uses
- Security obligations
- Breach notification requirements
- Return or destruction of PHI on termination
- Certification of compliance
</key_provisions>

<common_services_with_baas>
AWS: Available for HIPAA-eligible services
Azure: Available through Volume Licensing
Google Cloud: Available for eligible services
Twilio: Available for specific products
SendGrid: Not typically HIPAA compliant
</common_services_with_baas>

</baa_requirements>

<common_violations>

<violation name="unencrypted-transmission">
Problem: Sending PHI via unencrypted email or messaging
Fix: Use encrypted email or secure messaging platforms with BAAs
</violation>

<violation name="logging-phi">
Problem: Writing PHI to application logs
Fix: Sanitize logs, mask sensitive data, encrypt log storage
</violation>

<violation name="shared-accounts">
Problem: Multiple users sharing login credentials
Fix: Individual accounts for all users
</violation>

<violation name="missing-baas">
Problem: Using third-party services without BAAs
Fix: Inventory all services, obtain BAAs or switch providers
</violation>

<violation name="insufficient-access-control">
Problem: All users can access all patient data
Fix: Implement RBAC, limit access to minimum necessary
</violation>

<violation name="no-audit-trail">
Problem: Cannot determine who accessed what data when
Fix: Implement comprehensive audit logging
</violation>

</common_violations>

<quick_reference>

<must_have>
- All PHI encrypted at rest (AES-256)
- All PHI encrypted in transit (TLS 1.2+)
- Unique user identification
- Audit logging for all PHI access
- BAAs with all service providers
- Documented security policies
- Workforce training
- Risk assessment completed
</must_have>

<breach_notification>
If a breach occurs:
- Individuals: Within 60 days
- HHS: Within 60 days (or annual report if fewer than 500)
- Media: If 500+ individuals in a state
</breach_notification>

</quick_reference>
