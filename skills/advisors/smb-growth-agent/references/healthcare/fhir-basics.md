<overview>
FHIR (Fast Healthcare Interoperability Resources) basics for healthcare data exchange. This is the modern standard for healthcare API development.
</overview>

<what_is_fhir>

<definition>
FHIR (pronounced "fire") is an HL7 standard for healthcare data exchange. It combines the best of previous standards (HL7v2, HL7v3, CDA) with modern web technologies.

Key characteristics:
- RESTful API design
- JSON and XML support
- Modular resources
- Built-in extensibility
- OAuth2 security model
</definition>

<why_fhir>
Regulatory drivers:
- 21st Century Cures Act requires FHIR APIs
- CMS Interoperability Rules mandate patient access
- ONC certification requires FHIR capability

Practical benefits:
- Familiar REST patterns for web developers
- JSON support (easier than XML-only standards)
- Strong open-source ecosystem
- Growing vendor support
</why_fhir>

<versions>
Current versions:
- FHIR R4 (Release 4): Current production standard, required by regulation
- FHIR R4B: Minor update to R4
- FHIR R5: Latest release, not yet widely implemented

For SMB projects: Target FHIR R4 (US Core Implementation Guide)
</versions>

</what_is_fhir>

<common_resources>

<resource name="patient">
Description: Demographic information about a patient
Key Fields: name, birthDate, gender, address, telecom, identifier
Use Cases: Patient lookup, demographics display
Example:
{
  "resourceType": "Patient",
  "id": "example",
  "name": [{"family": "Smith", "given": ["John"]}],
  "birthDate": "1970-01-01",
  "gender": "male"
}
</resource>

<resource name="practitioner">
Description: Information about a healthcare provider
Key Fields: name, identifier (NPI), qualification, telecom
Use Cases: Provider directory, care team display
</resource>

<resource name="encounter">
Description: A clinical interaction (visit, admission)
Key Fields: status, class, subject, participant, period
Use Cases: Visit history, appointment tracking
</resource>

<resource name="condition">
Description: Clinical condition, problem, or diagnosis
Key Fields: code, subject, clinicalStatus, verificationStatus
Use Cases: Problem list, diagnosis history
</resource>

<resource name="observation">
Description: Measurements and assertions about a patient
Key Fields: code, value, subject, effectiveDateTime
Use Cases: Vital signs, lab results, assessments
Example Types: Blood pressure, heart rate, lab values, social history
</resource>

<resource name="medicationrequest">
Description: An order for medication
Key Fields: medication, subject, dosageInstruction, status
Use Cases: Active medications, prescription history
</resource>

<resource name="appointment">
Description: A booking of a healthcare event
Key Fields: status, start, end, participant, serviceType
Use Cases: Scheduling, appointment management
</resource>

<resource name="allergyintolerance">
Description: Risk of harmful reaction to a substance
Key Fields: code, patient, clinicalStatus, type
Use Cases: Allergy list display, clinical decision support
</resource>

<resource name="documentreference">
Description: Reference to a document (CCD, notes, images)
Key Fields: type, content, subject, context
Use Cases: Document retrieval, clinical notes access
</resource>

</common_resources>

<api_patterns>

<pattern name="read">
GET [base]/Patient/123
Returns a single resource by ID
Response: The resource as JSON/XML
</pattern>

<pattern name="search">
GET [base]/Patient?name=Smith&birthdate=1970-01-01
Returns a Bundle of matching resources
Common parameters: _id, _lastUpdated, _count, _include
</pattern>

<pattern name="create">
POST [base]/Patient
Body: The new resource
Returns: Created resource with server-assigned ID
</pattern>

<pattern name="update">
PUT [base]/Patient/123
Body: The updated resource
Returns: Updated resource
</pattern>

<pattern name="bundle">
Response containing multiple resources:
{
  "resourceType": "Bundle",
  "type": "searchset",
  "total": 10,
  "entry": [
    {"resource": {...}, "fullUrl": "..."},
    ...
  ]
}
</pattern>

</api_patterns>

<us_core>

<description>
US Core Implementation Guide defines the minimum data requirements for US healthcare. Most EHR FHIR APIs implement US Core profiles.
</description>

<must_support_resources>
Required resources in US Core R4:
- Patient
- Practitioner, PractitionerRole
- Organization
- AllergyIntolerance
- Condition
- DiagnosticReport (Lab, Notes)
- Encounter
- Goal
- Immunization
- MedicationRequest
- Observation (Vitals, Labs, Social History)
- Procedure
- DocumentReference
</must_support_resources>

<implementation_guide>
US Core: http://hl7.org/fhir/us/core/
This is what EHRs are required to support.
Build to US Core profiles for maximum compatibility.
</implementation_guide>

</us_core>

<implementation_tips>

<tip name="start-read-only">
Don't try to write to EHRs initially:
- Read operations are more commonly supported
- Less approval friction
- Lower risk
- Prove value before requesting write access
</tip>

<tip name="use-hapi-fhir">
HAPI FHIR is the go-to library:
- Java: HAPI FHIR base library
- .NET: Firely SDK
- JavaScript: fhir.js, fhirclient
- Python: fhirclient
Don't build FHIR parsing from scratch.
</tip>

<tip name="test-servers">
Public FHIR servers for testing:
- http://hapi.fhir.org (HAPI test server)
- https://launch.smarthealthit.org (SMART sandbox)
- Vendor-specific sandboxes (Epic, Cerner, etc.)
Always test with synthetic data first.
</tip>

<tip name="handle-variability">
Real-world FHIR varies:
- Fields may be missing
- Extensions differ by vendor
- CodeSystem values vary
Build defensive parsing that handles missing data gracefully.
</tip>

<tip name="smart-on-fhir">
For EHR-embedded apps:
- Implement SMART on FHIR launch
- OAuth2 with EHR as authorization server
- Launch context provides patient and user
Resources: https://smarthealthit.org
</tip>

</implementation_tips>

<common_pitfalls>

<pitfall name="assuming-consistency">
Problem: Expecting all servers to behave the same
Reality: FHIR implementations vary significantly
Fix: Test with multiple servers, handle variations
</pitfall>

<pitfall name="ignoring-pagination">
Problem: Assuming all results come in one response
Reality: Bundles are paginated for large result sets
Fix: Follow Bundle.link.next for all results
</pitfall>

<pitfall name="code-matching">
Problem: Expecting exact code matches
Reality: Same concept may use different coding systems
Fix: Handle multiple CodeSystems, use standard terminologies
</pitfall>

<pitfall name="timezone-issues">
Problem: DateTime handling inconsistencies
Reality: Servers may return UTC, local, or unspecified times
Fix: Parse carefully, store in UTC internally
</pitfall>

</common_pitfalls>

<quick_reference>

<base_url>
Pattern: https://[ehr-server]/fhir/r4/
Headers: Authorization: Bearer [token], Accept: application/fhir+json
</base_url>

<common_searches>
Patient by ID: GET /Patient/[id]
Patient by name: GET /Patient?name=[name]
Conditions for patient: GET /Condition?patient=[patient-id]
Observations for patient: GET /Observation?patient=[patient-id]
Everything about patient: GET /Patient/[id]/$everything
</common_searches>

</quick_reference>
