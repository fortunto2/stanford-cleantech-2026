# Ship Crew Air (started Sat 24 Oct 2026, 20:20 PT)

Mandate: finish the app for the App Store and the site so both are useful on their own; no business layer.
Decisions are logged here with the reason; the three repos stay the source of truth.

## Tracks

### A. iOS → App Store (agent `ios-ship`)
- [x] Remove the drone/dispatch concept from the UI: the Plan tab keeps "Fire N km, direction, check the sky";
      the orange "Sensor task: launch" card goes (it described hardware that does not exist). CrewKit keeps
      parsing `dispatch` so the API stays compatible.
- [x] Keep: Plan, Check the sky (Jev + AR horizon with fire and monitor markers), Report, crew-lead board, print/share.
- [x] Analytics: superduper-analytics `app_launched`, `plan_viewed`, `sky_checked` with an install UUID
      (generated on first launch, stored locally); source id from `~/startups/shared/superduper-analytics/registry/sources.yaml`
      (add `crewair-ios` if missing). Declared in `legal/app-store-privacy.md` and `legal/privacy-policy.md` in the same commit.
- [x] Version 1.0 (1). Icon present. `make test`, `make build` green. 37 CrewKit tests stay green.
- [x] Screenshots: iPhone 6.9" (iPhone 17 Pro Max simulator) ×5: plan with fire, sky check, AR, report, print sheet.
      Saved to `ios/metadata/screenshots/`.
- [x] `ios/metadata/` for `asc`: name "Crew Air", subtitle, description (≤4000), keywords, support URL
      https://airsignal.app/crew, privacy URL https://airsignal.app/crew/privacy, review notes (AR tab: where, what,
      no markers; the camera photo goes to TypeSafe for one analysis; no account).
- [x] Archive + export .ipa (`make build-device` signing with TEAM from Makefile.local; `asc xcode archive`/`export`).
      If signing needs an Apple ID session (2FA was locked at 423 today), stop and write the exact command.

### B. Site (agent `web-ship`, repo ~/startups/active/air-signal-web)
- [x] /crew: the "Sensor task: launch" card becomes "A worksite reading is advised" (fire within 50 km):
      bearing/distance stay, the drone sentence goes; the API `dispatch` field stays. (air-signal-web 8a0cf56)
- [x] CrewMap note: distance rounded to one decimal (today prints 14.902251688490937 km). (8a0cf56)
- [x] Download the shift plan as `.ics` (GridLight idea): events for "N95 from HH:00", "heat: shade+water from HH:00",
      "heavy work window", "pre-cool", "TOU peak". One link in the plan header, generated in the Worker. (577e7a4,
      `/api/crew/plan.ics`, `src/lib/ics.ts`, 4 node:test cases)
- [x] Home block: backup battery sizing (matcha idea): devices × hours → kWh, deterministic, three presets
      (fridge, CPAP, phone+router), no AI. Prints on the sheet. (577e7a4, `src/lib/battery.ts`, 4 tests)
- [x] Hourly grid CO2 next to the TOU bar from CAISO Today's Outlook (GridLight). Done properly on the lead's
      request (23:00): Worker cron every 30 min → D1 `grid_co2`, 14 days kept, /crew and /api/crew show the median
      of the last 7 days per hour, California only, labelled "not a forecast". (air-signal-web 63c5662)
- [x] /privacy for the Air Signal app (was 404): legal/airsignal/privacy-policy.md from air-signal-ios, footer link,
      guide sitemap. (801eee8)
- [x] /api/crew/report takes `app` and `observation` from Air Signal; observations stored, kept off crew boards;
      wind in the server's evidence; migration 0012. (6955fa6)
- [x] /crew/privacy matches `legal/privacy-policy.md` (analytics counter line included): the "Usage counter" section
      now has a paragraph on the web counter (`sda.js`, source `airsignal`, page views, no cookies, no account) in
      both copies, byte-identical.
- [x] `make deploy`, then curl /crew, /api/crew, /crew/grid, /crew/privacy, the .ics. Deployed 21:40 (version
      9cf22c75); all five answer as expected (log 21:45). One catch: `/openapi.json` is edge-cached 24 h with a key
      that drops the query string, so it still shows the old spec until about 15:30 PT Sun 25 Oct, or until a purge.

### C. App Store Connect (me)
- [x] Bundle ID `co.superduperai.crewair` registered (J7FW562VSY, team 8N495BBBLM, UNIVERSAL).
- [ ] App record: needs an Apple web session (2FA, only Rustam). Password is stored in asc; run in the terminal:
      `! asc web auth login --apple-id rust.starman@gmail.com` (enter the 2FA code when asked), then
      `! asc web apps create --name "Crew Air" --bundle-id co.superduperai.crewair --sku co.superduperai.crewair --primary-locale en-US --platform IOS`
      (if the account is still locked from the 423 at 14:00, wait until Sunday).
- [ ] `asc validate` once the record exists; App Privacy answers from `legal/app-store-privacy.md`.

## Log
- 20:20 started; agents ios-ship and web-ship spawned.
- 20:24 bundle ID already exists; app record blocked on the Apple web session (2FA), command prepared above.
- 00:45 web-ship: /simplify findings applied in four commits (1695939 reuse+dead, 900949d grid_co2 efficiency, af15423
  root causes, 355f2f1 fix), deployed 9730d084, all curl-verified. Shipped: src/lib/tz.ts (one zone helper, tested
  across DST and 3 zones), src/lib/stats.ts median (AirNow 2-monitor case now averages the middle pair), planFromQuery
  for both plan routes, paths.crewPlan/crewApi/crewPlanIcs, REPORT_KINDS/apps imported from observation.ts
  everywhere, strict observation kinds (no aliases), ics events from plan.actions and the engine's clear-window text
  (no thresholds in ics.ts), cron writes only the last two hours and backfills 3 days in parallel with a failed-day
  marker row (hour -1), typical CO2 remembered per day for 30 min, report path skips the grid read. Root causes:
  every hour in /api/crew is in place.tz (geocoder, or Open-Meteo timezone=auto for coordinates); the geocoder is
  global, California first; outside the US the engine gets an empty rulebook (jurisdiction null, actions [], home
  null, said on the page); boards keyed country-state-town with the two older key generations still read
  ("barstow", "barstow-california"); every crew query carries app='crewair' (handle, get, list; retention and the
  rate limit stay app-agnostic on purpose); evidence hour = observation.observed_at when present;
  dispatch.reading_advised with sensor kept as the deprecated alias. Judgment calls: tz.ts not pacific.ts (after
  the change only CAISO is Pacific); UTC instants instead of a VTIMEZONE per zone; coordinates still look their town
  up because countries.iso is NULL for all 156 rows (fill it and the lookup is skipped for foreign points); no
  node fixture of a whole US-CA answer (crew.ts pulls the WASM core and cloudflare:workers), the zone helpers are
  tested instead and Fresno was verified live (07:00 first hour, US-CA, 2 actions, home, grid_co2).
  Verified live: Berlin → "Berlin, Germany", DE, Europe/Berlin, jurisdiction null; Paris, France → FR; Springfield,
  Illinois → America/Chicago; 52.52,13.40 → near Berlin, DE; 36.75,-119.77 → near Fresno, California, US-CA; boards
  Barstow 5 (3 legacy + 2 older), Fresno 1; an airsignal observation with observed_at 13:30Z got evidence hour
  2026-10-25T06:00 and wind, could not be handled (404) nor escalated ("No such report"); test row deleted.
  Next, not done: a separate /api/report route for observations (bigger API change); air-signal-ios CLAUDE.md
  still says /api/crew answers in Los Angeles time, now it is place.tz, and PacificTime.swift can go.
- 01:45 web-ship: POST /api/report shipped (air-signal-web d799c7f, deployed fe6a9b18). Storage: new `observations`
  table (migration 0013, applied remotely), not crew_reports: an observation has no site board, status or handling,
  and its readers want rows shaped lat/lon/kind/intensity/hour/evidence. Body {lat, lon, observation {kind,
  intensity 1–5, observed_at?}, sky? {smoke_score 0–1}, snapshot?}; server rounds to 2 decimals, names the point
  from our cities, builds the plan for the local day of observed_at in place.tz and stores evidence for that hour
  (NowCast, PM2.5, temp, wind, fire, monitor). Same 10/10 min limit and daily salted sender hash; retention in the
  same purge. /api/crew/report keeps app/observation one release, deprecated in openapi. 31 tests green (validator
  7, evidence 2 new). Verified live: valid body → 201 id 1, row: lat 36.75/-119.77, hour 2026-10-25T00:00 for
  observed_at 07:19Z, metrics {aqi 68, nowcast 18 µg/m³, 56.3 °F}, wind {100°, 6 km/h}, snapshot trimmed (junk key
  dropped), sender 16 hex; six bad bodies → 400 with the field named; crew board unchanged; deprecated path still
  201; test rows deleted. openapi.json still edge-cached until ~15:30 PT (same 24 h key as before). Privacy copy on
  the site updated (observations in their own table, not shown on crew pages); air-signal-ios/legal/airsignal/
  privacy-policy.md has the old sentence and should take the same edit.

