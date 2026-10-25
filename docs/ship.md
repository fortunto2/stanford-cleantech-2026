# Ship Crew Air (started Sat 24 Oct 2026, 20:20 PT)

Mandate: finish the app for the App Store and the site so both are useful on their own; no business layer.
Decisions are logged here with the reason; the three repos stay the source of truth.

## Tracks

### A. iOS → App Store (agent `ios-ship`)
- [ ] Remove the drone/dispatch concept from the UI: the Plan tab keeps "Fire N km, direction, check the sky";
      the orange "Sensor task: launch" card goes (it described hardware that does not exist). CrewKit keeps
      parsing `dispatch` so the API stays compatible.
- [ ] Keep: Plan, Check the sky (Jev + AR horizon with fire and monitor markers), Report, crew-lead board, print/share.
- [ ] Analytics: superduper-analytics `app_launched`, `plan_viewed`, `sky_checked` with an install UUID
      (generated on first launch, stored locally); source id from `~/startups/shared/superduper-analytics/registry/sources.yaml`
      (add `crewair-ios` if missing). Declared in `legal/app-store-privacy.md` and `legal/privacy-policy.md` in the same commit.
- [ ] Version 1.0 (1). Icon present. `make test`, `make build` green. 37 CrewKit tests stay green.
- [ ] Screenshots: iPhone 6.9" (iPhone 17 Pro Max simulator) ×5: plan with fire, sky check, AR, report, print sheet.
      Saved to `ios/metadata/screenshots/`.
- [ ] `ios/metadata/` for `asc`: name "Crew Air", subtitle, description (≤4000), keywords, support URL
      https://airsignal.app/crew, privacy URL https://airsignal.app/crew/privacy, review notes (AR tab: where, what,
      no markers; the camera photo goes to TypeSafe for one analysis; no account).
- [ ] Archive + export .ipa (`make build-device` signing with TEAM from Makefile.local; `asc xcode archive`/`export`).
      If signing needs an Apple ID session (2FA was locked at 423 today), stop and write the exact command.

### B. Site (agent `web-ship`, repo ~/startups/active/air-signal-web)
- [ ] /crew: the "Sensor task: launch" card becomes "A worksite reading is advised" (fire within 50 km):
      bearing/distance stay, the drone sentence goes; the API `dispatch` field stays.
- [ ] CrewMap note: distance rounded to one decimal (today prints 14.902251688490937 km).
- [ ] Download the shift plan as `.ics` (GridLight idea): events for "N95 from HH:00", "heat: shade+water from HH:00",
      "heavy work window", "pre-cool", "TOU peak". One link in the plan header, generated in the Worker.
- [ ] Home block: backup battery sizing (matcha idea): devices × hours → kWh, deterministic, three presets
      (fridge, CPAP, phone+router), no AI. Prints on the sheet.
- [ ] Time-boxed 1 h: hourly grid CO2 next to the TOU bar from CAISO Today's Outlook (GridLight). If the feed
      needs more than a cron + one table, leave a note in docs and skip.
- [ ] /crew/privacy matches `legal/privacy-policy.md` (analytics counter line included).
- [ ] `make deploy`, then curl /crew, /api/crew, /crew/grid, /crew/privacy, the .ics.

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
