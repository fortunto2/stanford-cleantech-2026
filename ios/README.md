# Crew Air (iOS)

A thin client for the smoke + heat shift plan at `https://airsignal.app/api/crew`: what an
outdoor crew in California has to do today under Cal/OSHA §5141.1 (wildfire smoke) and
§3395 (heat), where the fire is, and a way for a worker to flag a problem to the crew lead.

## Run

```bash
make gen     # xcodegen: CrewAir.xcodeproj from project.yml (the project is not committed)
make test    # CrewKit domain tests on the Mac, no simulator
make build   # simulator compile check
make run SIM="iPhone 17 Pro"   # build, install, launch in a simulator
make lint    # SwiftLint, if installed
```

Or `make gen && open CrewAir.xcodeproj`. For a device build, set your team in Xcode or pass
`DEVELOPMENT_TEAM=...`; it is empty in `project.yml` on purpose.

## Layout

```
CrewKit/      SPM package: API models + decoding, EPA AQI bands, compass → degrees,
              horizon projection. Recorded /api/crew responses are the test fixtures.
CrewAir/
  App/        @main, TabView, Theme.swift (every colour and spacing: redesign here)
  Services/   CrewService (URLSession), HeadingProvider (CoreMotion), CameraSession, SkyChecker
  ViewModels/ PlanViewModel, ReportViewModel (@Observable @MainActor)
  Views/      Plan, Sky, Report, preview data
```

## Tabs

- **Plan**: one hero card in the colour of the shift's peak EPA band (peak AQI, the first
  smoke rule as a sentence), Heat and Heavy-work tiles, "Air by the hour" bars, a Checked /
  Model only chip, and "Print the briefing sheet" (opens airsignal.app/crew in Safari). Tap
  the place name to change place, day or shift.
- **Sky**: rear camera with the nearest fire and the nearest AirNow monitor pinned to their
  compass bearings on the horizon (true north once location is allowed, magnetic before).
  In the Simulator: dark backdrop, heading 315°, drag sideways to turn. The X closes to Plan
  (or back to the camera after a photo check).
  **Check the sky** sends one frame to Jev (`POST /api/sky-check?place=`, raw `image/jpeg`).
  Before upload, on the phone: every face Vision finds is painted black, a camera frame is
  cut 12% below the horizon line, the long side is capped at 768 px, JPEG q0.8. Also works on
  a library photo ("Use a photo") or a bundled sample ("Try a sample"), for indoor demos.
  On our 12 known-answer photos Jev got the smoke call right 11–12 of 12 across two runs;
  ~70–100 ms server side. Its visibility estimate is shown only when it says `trusted`.
  "Looks worse than the forecast" offers Report smoke, which files kind `smoke` with the verdict.
- **Report**: four big kinds, "Where?", Send, today's reports with Waiting / Fixed pills,
  and "Take it further" to the Escalate screen. "I'm the crew lead" turns the tab into the
  lead board: open reports with a 30-minute countdown, the evidence the server attached,
  "What you did" and Mark fixed (`action: "handle"`).

Every report carries the phone's position and true heading when location is allowed (the
server rounds to ~100 m and works out "toward the fire"), and the sky check it came from.
A library photo's EXIF (GPS, `GPSImgDirection`, `DateTimeOriginal`) is used instead of the
live fix and shown on the verdict card. After a check, **Share the evidence card** renders
the photo as sent with the forecast, satellite fire, monitor and heading, for forwarding.
The plan follows the phone (`place=<lat>,<lon>`, named "near <city>" by the server) until a
place is picked in the sheet under the place name: "Use my location", or a search with live
suggestions from `/api/crew/places`. The choice is remembered.
A first-launch guide (and "?" on Plan) has a worker path and an employer path; choosing
employer turns on crew-lead mode.

English and Spanish: `CrewAir/Resources/Localizable.xcstrings` and `InfoPlist.xcstrings`.
Rule texts from the API stay in English. After adding UI strings, build, then sync:
`xcrun xcstringstool sync CrewAir/Resources/Localizable.xcstrings --stringsdata $(find build-sim -path '*CrewAir.build*arm64*' -name '*.stringsdata')`.

## Sample photos

Bundled in `CrewAir/Resources/Samples/`, both public domain, Wikimedia Commons:

- `sample-smoke.jpg`: "Orange Haze Hides Manhattan"
- `sample-clear.jpg`: "Fall View from Stony Dome" (NPS)

## Stubbed

- `StubSkyChecker` remains for previews only; the app uses `LiveSkyChecker`.
- Horizon crop uses the app's own horizon line (heading + pitch), not `VNDetectHorizonRequest`:
  Vision returns the horizon's angle, not its height. Library photos are sent uncropped.
- **Escalate**: only the Cal/OSHA complaint link is live; union and legal aid say "Coming".
- Only one fire (`confidence.fire`, the nearest) is shown; the 8-point direction is all the
  bearing there is, so the pin can be up to 22.5° off.
