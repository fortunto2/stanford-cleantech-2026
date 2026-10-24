# Crew Air

**Smoke and heat forecasts turned into a shift plan, so the job site keeps working and stays within the law.**

Stanford Cleantech Hackathon 2026 · Track 2 Climate & Health (Track 3 Resilient Systems for the buildings angle)
· [Pitch deck](https://claude.ai/artifact/Kxr2SHzzCTs2JyCXoSFSsQ) · [pitch/](pitch/)

## The problem

Air-quality maps tell you the air is bad *now*. Nobody tells the foreman what to do *tomorrow*. California
already writes it down: at an AQI of 151 for PM2.5 the employer must provide N95s (Cal/OSHA §5141.1),
at 95°F high-heat procedures start (§3395). Today someone checks airnow.gov at the start of the shift.

## What it does

```
$ uv run python -m crewair.cli "Three Rivers" --shift 06-18
Three Rivers, California (36.439, -118.905) · 2026-10-24 · shift 06:00–18:00
peak AQI 102 · peak 72°F
No Cal/OSHA smoke or heat thresholds crossed. Normal shift.
```

On a smoky or hot day the same command prints the hour each threshold is crossed, the action the rule
requires, and the clear hours to move heavy work into.

- `crewair/forecast.py`: geocoding + hourly US AQI (PM2.5), PM2.5 µg/m³ and temperature from Open-Meteo, no API key
- `crewair/rules.py`: a jurisdiction-agnostic engine, hourly forecast + rulebook → actions
- `rulebooks/us-ca.yaml`: Cal/OSHA §5141.1 (smoke) and §3395 (heat) as data
- `crewair/cli.py`: address + date + shift + rulebook → plan
- `tests/test_rules.py`: the rules and the engine

```bash
uv sync
make plan P="Fresno" S=07-17
make test
```

## Rulebooks: one file per jurisdiction

The engine knows no law. A rulebook names a metric (`us_aqi_pm25`, `pm25_ugm3`, `temp_f`, `temp_c`),
a threshold, the action and the citation. Within a group the most severe rule crossed in the shift wins.
A new state or country is a new YAML file, not new code: Oregon and Washington have their own smoke
rules, Canadian provinces use AQHI, Spain and Italy restrict outdoor work in heatwaves. Only California
ships today; each new rulebook gets its thresholds checked against the source text first.

## Data sources and keys

| Source | Key | Note |
|---|---|---|
| Open-Meteo (CAMS air quality + weather), used now | none | free for non-commercial use; a product needs their paid plan |
| NOAA HRRR-Smoke, next | none | open data on AWS, 3 km over the US |
| NWS api.weather.gov | none | User-Agent header only |
| NASA FIRMS | free MAP_KEY | active fires |
| AirNow | free key | official US monitors, for calibration |
| PurpleAir | paid key | dense community sensors |

Coverage does not depend on sensors: the forecast is a model over every grid cell (CAMS ~40 km
worldwide, HRRR 3 km over the US). Sensors calibrate it; where none are near, the plan says
"model only". Weakest spots: valleys and right next to a fire.

## Satellite side (Earth Engine)

`work/` holds the GEE 101 workshop run locally plus two scripts on the largest fire in California on 20 Oct
2026 (NASA FIRMS, near Sequoia): `fire_s2.py` pulls a Sentinel-2 scene, `burn_scar.py` computes dNBR.
Auth: `ee_init.py` uses your gcloud login (`EE_ACCOUNT`, `EE_PROJECT`).

![Sentinel-2 SWIR composite, active fire front near Sequoia, 17 Oct 2026](pitch/fire_s2_swir.png)

## Status (Fri 23 Oct, night)

- [x] Idea, deck, pitched at team formation (Tracks 2 and 3)
- [x] CLI on live forecasts, rules tested
- [ ] Team (event rules: 2–5)
- [ ] Sharper smoke forecast: NOAA HRRR-Smoke (3 km) instead of CAMS (~40 km, low near fires)
- [ ] One web page for the demo: address → plan + fire map
- [ ] BMS signal for buildings (JSON "recirculate at 12:00")
- [ ] Devpost by Sat 17:00: text, 2-min video

Built during hacking hours (Fri 17:00 – Sat 17:00). The author's earlier project Air Signal (airsignal.app)
is background experience only; none of its code is here. Event notes: [docs/event.md](docs/event.md),
tracks and decision: [docs/tracks.md](docs/tracks.md).

## License

MIT
