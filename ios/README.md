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

- **Plan**: place, today/tomorrow, shift hours. Fire warning (prominent when a fire is within
  50 km), confidence level and notes, the actions with their citations, an hourly strip (AQI
  in its EPA colour, °F floored), and the building ventilation (BMS) line.
- **Sky**: rear camera with labels pinned to compass bearings on the horizon, using device
  motion (true north once location is allowed, magnetic before). In the Simulator there is no
  camera or compass: a dark backdrop, heading starts at 315°, drag sideways to turn.
- **Report**: one tap per kind (smoke, ash, symptoms, no N95, no shade, no water, other), an
  optional note, and today's reports with status. A report the server refuses stays on the
  phone marked `unsent`.

## Stubbed

- **Check the sky** calls `StubSkyChecker`, which answers "not wired yet". The real one
  sends a sky-only crop (above the horizon line) to a vision model; swap it in `RootView`.
- **Escalate anonymously** is a disabled mock row.
- **AirNow monitor in the sky view**: the API gives the monitor's name and distance but not
  its position, so it shows as "direction unknown". If `ground` gains `nearest_lat` /
  `nearest_lon`, the app already decodes them and pins the monitor.
- Only one fire (`confidence.fire`, the nearest) is shown; the 8-point direction is all the
  bearing there is, so the pin can be up to 22.5° off.
