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
  In the Simulator: dark backdrop, heading 315°, drag sideways to turn.
- **Report**: four big kinds, "Where?", Send, today's reports with Waiting / Fixed pills,
  and "Take it further" to the Escalate screen. "I'm the crew lead" turns the tab into the
  lead board: open reports with a 30-minute countdown, the evidence the server attached,
  "What you did" and Mark fixed (`action: "handle"`).

English and Spanish: `CrewAir/Resources/Localizable.xcstrings` and `InfoPlist.xcstrings`.
Rule texts from the API stay in English. After adding UI strings, build, then sync:
`xcrun xcstringstool sync CrewAir/Resources/Localizable.xcstrings --stringsdata $(find build-sim -path '*CrewAir.build*arm64*' -name '*.stringsdata')`.

## Stubbed

- **Check the sky** calls `StubSkyChecker`, which answers "not wired yet". The real one
  sends a sky-only crop (above the horizon line) to a vision model; swap it in `RootView`.
- **Escalate**: only the Cal/OSHA complaint link is live; union and legal aid say "Coming".
- Only one fire (`confidence.fire`, the nearest) is shown; the 8-point direction is all the
  bearing there is, so the pin can be up to 22.5° off.
