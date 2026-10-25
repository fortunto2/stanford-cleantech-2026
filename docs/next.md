# After the hackathon: a free app that lives on its own (decided Sat 24 Oct 2026, 18:00 PT)

No business around it. Crew Air ships to the App Store as a free utility for outdoor crews in California,
with the site and the API as they are, and then runs without attention. The order:

1. **Cut what needs a human.** Keep: Plan, Check the sky, Report, the AR horizon, the print sheet, `/api/crew`.
   Drop or hide: the drone/dispatch card (concept), the escalation page beyond the draft, the crew-lead board
   if nobody uses it. The site stays, `/crew/grid` stays (it is static-ish and cheap).
2. **Make it not break while nobody watches.** Open-Meteo 429 already falls back to AirNow + NWS; keep that.
   Keep the Jev sky check only if the TypeSafe key has no monthly cost; otherwise ship the camera photo to the
   report without the score. One health check in `solo systems` that curls `/api/crew` daily.
3. **App Store, by the `solo:ios-release` skill.** ASC app record (`co.superduperai.crewair`, team 8N495BBBLM),
   the privacy page at airsignal.app/crew/privacy from `legal/privacy-policy.md`, App Privacy answers from
   `legal/app-store-privacy.md`, review notes for the camera/AR tab (what it is, where, no markers needed),
   screenshots from the simulator (`pitch/shots/v2-*.png` are the base). `asc validate` drives the checklist.
   The Apple ID was 2FA-locked (423) on Sat; wait a day before retrying.
4. **A counter, declared.** superduper-analytics `app_launched` + `plan_viewed` with an install UUID, and
   the matching line in the privacy page and the App Privacy declaration, in the same commit.
5. **Then leave it.** Dependabot off, no roadmap. Fix only what a user reports through the App Store.
6. **Read the demand around 24 Nov 2026.** The site counter (superduper-analytics, source `airsignal`,
   page views by path, in the Layout since before the hackathon) already covers /crew, /crew/grid and /api:
   `analytics-dig` for those paths, plus `crew_reports` rows in D1 and the App Store units. `/api/crew` calls
   from scripts are not counted by the browser script; count them from the Worker logs if it matters.

Not for this plan: the utility pilot, HRRR-Smoke, nodes, the PG&E smart-panel contact (private memory:
`contact-rongxin-yin-lbnl`): those are the business track, parked unless someone asks.

---

# Next steps (handoff, Fri 23 Oct 2026, ~21:00 PT)

Deadline: **Devpost by Sat 24 Oct 17:00 PT** (https://stanford-cleantech-hackathon.devpost.com/), finalists
demo 17:00–19:00 (3 min + 2 min Q&A), awards 19:00. Building allowed until 17:00 Saturday.

## Done
- **AQI is a NowCast now** (Sat 00:15). Open-Meteo `us_aqi_pm2_5` is a 24 h mean (matches our 24 h mean
  within ±3, 2–3x off the hourly value), so we compute the EPA NowCast from hourly `pm2_5`
  (`crewair/nowcast.py`, known-answer tests). The respirator rule was `AQI >= 501`, which can never
  trip on a scale that stops at 500; both smoke rules are concentrations now (55.5 / 500.5 µg/m³, App. A).
- **Live page: https://airsignal.app/crew** (form, hourly strip, BMS line, Print / Save PDF with a
  pre-shift sign-off) and **`/api/crew?place=&date=&shift=`** (JSON incl. `plan.bms.recirculate_at`).
  Same maths in Rust: `airq-core/src/crew.rs` → WASM `wasm_crew_plan`. This covers steps 2, 4 and most of 5.
- **Checks on every plan** (Sat 00:30): NASA FIRMS VIIRS fires (warning within 50 km, with direction) and
  the latest AirNow monitor hour within 25 km (agree within 1.5x → "sensor-confirmed"; otherwise the
  forecast is scaled toward the monitor, ×0.5…×3, fading over ~12 h). Both keyless public files.
  Python CLI does not have these checks yet; the demo should use the page.
- CLI `crewair` on live Open-Meteo forecasts, rulebook engine, `rulebooks/us-ca.yaml`, 5 tests green.
- Pitch deck (12 slides): https://claude.ai/artifact/2YRYbz8SuvFxQuQqYs9gTA, sources in `pitch/`.
- Repo public, single clean history.

## Saturday, in order
1. **Team** (rules: 2–5). Morning in person, 9:00 breakfast / mentorship block A; Devpost Participants tab.
2. ~~**AQI check**~~ done, see above.: is Open-Meteo `us_aqi_pm2_5` a 24 h average? Cal/OSHA §5141.1 uses the current hourly
   AQI (NowCast). If averaged, compute NowCast from hourly `pm2_5` ourselves (EPA formula) and switch the
   rulebook metric. Add a test with a known answer.
3. **Sharper smoke**: NOAA HRRR-Smoke (`noaa-hrrr-bdp-pds` on AWS, `MASSDEN` near-surface smoke) for US
   addresses; keep CAMS as the fallback. Show "model only / sensor nearby" confidence.
4. **One web page** for the demo (FastAPI or static + JS): address, shift → plan, map with FIRMS fires.
5. **BMS signal** (Track 3): `crewair bms <place>` → JSON like `{"recirculate_at": "12:00", "reason": ...}`.
6. **Devpost**: text from README, 2-min video (CLI + page), repo link, tracks 2 and 3.

## Saturday run (task list, kept here so it survives context compaction)

Positioning: heat paperwork is the wedge (enforced every summer), smoke rides on the same sheet;
the worker report ladder (worker → crew lead → anonymous escalation to union / legal aid / Cal/OSHA)
creates the urgency enforcement does not. Evidence: `docs/evidence.md`.

- [x] Site: manual worker reports on /crew (D1 `crew_reports`, evidence snapshot, crew-lead "handled",
      30-min escalation mock), reports on the printed sheet
- [x] Deck: problem slide with the 4.5M / 11 numbers, ladder slide, heat-first wedge, checks slide
- [x] Docs: README (what is live, data sources incl. FIRMS + AirNow files), evidence, Devpost text
- [x] Harness: CLAUDE.md for this repo, `make` targets (test, evidence, ios), sensors green
- [x] iOS: `ios/` scaffold (XcodeGen, Swift 6, SwiftUI), thin client of /api/crew, Sky + Report tabs
- [x] Design: Claude design artifact for the app (Plan, Sky AR, Report, Sheet)
- [x] Sky check: /api/sky-check (Jev) + page upload + eval 11–12/12
- [x] iOS rounds 2–6: X / tab bar, scroll, Check the sky, design, crew lead, Spanish, EXIF, guide, agency cards
- [ ] TestFlight: Apple 2FA locked (423) after the SMS code timed out; Rustam creates the app record on appstoreconnect.apple.com (Crew Air, co.superduperai.crewair, SKU crewair), then `asc publish testflight` with the API key
- [x] DOL citations by year in docs/evidence.md + 'fines' slide (the ag/complaint split is still downloading)
- [x] /crew survives Open-Meteo's daily 429 (AirNow + NWS fallback)
- [ ] Devpost by 17:00: text (docs/devpost.md, tracks 2 + 1 + 3), repo link; Asher on the team by email; video pitch/video/crew-air.mp4 [x] built 15:31, upload to YouTube unlisted
- [x] Home signal for Track 1/3 (E-TOU-C peak band, pre-cool, NWS alerts) live on /crew and /api/crew (14:20)
- [x] Smoke map on /crew (fires, monitor, per-hour downwind cones), dispatch signal, /crew/grid for SVCE's 13 cities, /api page (14:50)
- [ ] OSM power layer on /crew/grid: Overpass timed out from the venue twice; src/data/svce-power.json is []

## Later (after the hackathon)
- SEO pages for Cal/OSHA smoke/heat questions, analytics, lead form
  for multi-site and BMS.
- More rulebooks (OR, WA, Canada AQHI, Spain/Italy heat), each checked against the source text.
- Product loop: evening alerts (SMS/email), multiple sites, PDF log for inspectors, Spanish.
- Open-Meteo is free only non-commercially: switch to HRRR + NWS or pay before any paid use.

## After the hackathon (from docs/pitch.md)
- [ ] Email Rongxin Yin, LBNL Grid Integration Group (contact in private memory): JSON fields, /crew/grid, OpenADR/webhook, 30-min call
- [ ] One utility contractor interview on the line-crew case (Asher)
- [ ] HRRR-Smoke raster on the map; OSM power layer on /crew/grid
- [ ] TestFlight once the app record exists; App Store only with explicit OK
