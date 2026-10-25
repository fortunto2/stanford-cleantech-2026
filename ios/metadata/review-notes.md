# Crew Air 1.0 — notes for App Review

Paste into App Store Connect → version → App Review Information → Notes. No sign-in required: leave the
demo account fields empty.

---

Crew Air needs no account and has no sign-in. Everything below works on first launch.

PLAN tab: opens on a plan for the current place (Fresno by default; tap the place name to change it, or
"Use my location"). It shows the hour the Cal/OSHA wildfire-smoke rule (§5141.1) and the heat rule (§3395)
apply during the shift.

SKY tab (the camera view): point the rear camera at the horizon. There are no AR markers or printed
targets to find; the app draws labels for the nearest satellite-detected fire and the nearest air monitor
at their compass bearings, using the device heading. To test without a view of a real fire, tap the
sample button (the photo icon with the arrow, bottom right) and choose "Smoky city": a bundled photo is
sent for analysis and the verdict card appears. "Use a photo" does the same with a library photo.

REPORT tab: pick a kind (for example "Smoke or haze") and press Send. The report appears in the list
below with a Waiting pill. Please use a place such as "Barstow" to keep review reports out of the demo
site's page. "I'm the crew lead" switches the tab to the lead's board where a report can be marked fixed.

Permissions, all optional: Camera (the Sky tab preview and photo), Location (true north for the compass
labels and a rounded location on a report), Motion (device heading). Denying any of them leaves the rest
of the app working; the Sky tab falls back to "check a photo instead".

Data: the sky photo is sent once to our server and passed to TypeSafe's vision model for a single
analysis; it is not stored by us, and faces are blacked out on the phone before upload. A report carries
the location rounded to about 100 m only when location is allowed. The app also sends three anonymous
usage events (app opened, plan shown, sky check done) to our own counter with an install UUID that is
deleted with the app. Privacy policy: https://airsignal.app/crew/privacy
