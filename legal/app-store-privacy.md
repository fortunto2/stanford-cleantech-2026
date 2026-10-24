# Crew Air — App Store Connect privacy answers

Privacy policy URL: https://airsignal.app/crew/privacy

**Tracking:** No. No ATT prompt needed. No IDFA, no third-party SDKs, no analytics.

**Data collected** (all *Not linked to the user*, none used for tracking):

| Apple category | Type | Purpose | Why |
|---|---|---|---|
| Location | **Precise Location** | App Functionality | reports keep coordinates to 3 decimals; Apple defines 3+ decimals as precise |
| User Content | Photos or Videos | App Functionality | the sky photo goes to the server and TypeSafe for one analysis, not stored by us; declared to be safe |
| User Content | Other User Content | App Functionality | report kind and note |
| Identifiers | — | — | none: the rate-limit hash is server-side, erased after 2 days, derived from IP, not a device ID |
| Usage Data, Diagnostics | — | — | none collected |

**Not linked to identity:** there are no accounts, names or device identifiers, so nothing can be tied to
a person by us.

**Age rating note:** reports are user-generated content visible to anyone opening the same site's page;
declare User-Generated Content in the age rating questionnaire.

**Review notes (for App Review):** no login. To test: Plan tab shows a plan for the current place; Sky
tab → "Try a sample" → "Smoky city" runs the vision check; Report tab sends a report (use place Barstow
to stay out of the demo data). The camera needs no AR markers; it shows labels at real compass bearings.
Faces are detected with Vision only to black them out before upload; no face data is stored or sent.
