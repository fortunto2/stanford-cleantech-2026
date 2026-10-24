# Devpost submission — Crew Air

**Tagline (≤200 chars):** Smoke and heat forecasts turned into the shift plan California law already requires,
checked by satellite, ground monitors and the crew's own photos of the sky.

**Tracks:** Track 2 Climate & Health (primary), Track 1 Energy & the Grid (the same hours for a home:
heat, smoke and the 4–9 pm peak price on one strip), Track 3 Resilient Systems (the BMS and home signal
as JSON for a building system or a home agent)

**Links:** live https://airsignal.app/crew · code https://github.com/fortunto2/stanford-cleantech-2026 ·
deck https://claude.ai/artifact/Kxr2SHzzCTs2JyCXoSFSsQ · [video: TODO]

## Inspiration

California tells outdoor employers exactly what to do: at PM2.5 AQI 151, N95s and tell the crew
(Cal/OSHA §5141.1); at 80°F shade and water, at 95°F high-heat procedures (§3395). It almost never
happens. In the 2020–21 fire seasons farmworkers spent at least 4.5 million worker-days at AQI 151+
(our calculation from EPA AirData and BLS employment data). Cal/OSHA cited the smoke rule 19 times in
seven years (July 2019 to September 2026, DOL enforcement data) against 8,507 heat citations. About 60%
of surveyed Central Valley farmworkers got no N95. Inspections wait for complaints, and workers are
afraid to complain.

## What it does

- **Shift plan.** Place, day, shift → the hour each rule starts, the action, the clear window for heavy
  work, and when a building should close outside air. One printed sheet with a pre-shift briefing sign-off.
- **Checked four ways.** A forecast model (with the AQI computed as an EPA NowCast; the 24-hour mean that
  forecast feeds publish lags a smoke front by most of a shift), NASA VIIRS fires within 50 km, AirNow
  monitors within 25 km (a disagreement scales the forecast, never below half), and the crew.
- **Check the sky.** A photo of the horizon goes to TypeSafe's Jev vision decision model. Faces are blurred
  on the phone. On 12 public-domain photos with known answers it made the smoke call right 11–12/12,
  never wrongly. Visible smoke under a clean forecast becomes a report.
- **The report ladder.** Worker reports (no name, evidence attached) → crew lead marks it handled → after
  30 minutes it can go further anonymously (a Cal/OSHA complaint; union and legal-aid forwarding once
  partners agree).
- **iOS app**: plan, AR horizon with fires and monitors pinned at their real bearing, sky check, reports.
- **The same hours for a home and the grid.** Heat and smoke days are the grid's worst days too. The
  hourly strip shows the PG&E E-TOU-C peak price (4–9 pm every day; SVCE bills generation on the same
  hours) next to heat and smoke, marks the cheap hours to pre-cool a house before the peak, and the smoke
  hour to shut windows (a closed house runs the air conditioner longer). Active NWS alerts (Red Flag
  Warning, Heat Advisory) are on the page. All of it is in the JSON (`home`, `alerts`, `plan.bms`) for a
  home agent or a DERMS. Rules, not an optimisation: we claim no dollars or megawatts, that needs a load
  model and a pilot.

## How we built it

Rust engine (`airq-core/src/crew.rs`: NowCast, rulebooks as data, plan, BMS, checks) compiled to WASM and
run in a Cloudflare Worker (Astro SSR) with D1 for reports; Swift 6 / SwiftUI app; Python CLI mirror;
public data only: Open-Meteo, NASA FIRMS, AirNow hourly files, EPA AirData, BLS QCEW, DOL OSHA
enforcement; Earth Engine + Sentinel-2 for the burn-scar slide.

## Challenges

- Open-Meteo's `us_aqi` turned out to be a 24-hour mean; we compute the NowCast from hourly PM2.5.
- The respirator rule "AQI > 500" can never fire on a scale that stops at 500; we use the concentration
  as Appendix A does.
- Vision models are not sensors: Jev's visibility estimate was unreliable on our eval, so only the smoke
  call drives the verdict, and "not sure" asks for another photo.

## What's next

HRRR-Smoke (3 km), more rulebooks (OR, WA, Canada, Spain), SMS/WhatsApp alerts in Spanish, partners for
step 3 (unions, legal aid), a pilot farm next summer. For the grid: a backtest with a CCA of one summer's
peak days against our heat and smoke hours, then hourly grid carbon on the strip; PM2.5 sensor nodes
where the nearest monitor is far (48.7 km at one of our test sites).

## Built with

rust, webassembly, cloudflare-workers, astro, d1, swift, swiftui, python, typesafe-jev, nasa-firms,
airnow, open-meteo, earth-engine

**Disclosure:** written during hacking hours, on top of our earlier open-source work (Air Signal site
hosting, airq-core AQI/merge, Starlapse camera geometry); see README "Where the code is".
