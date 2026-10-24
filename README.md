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

- `crewair/forecast.py`: geocoding + hourly US AQI (PM2.5) and temperature from Open-Meteo, no API key
- `crewair/rules.py`: Cal/OSHA thresholds as pure functions, hourly forecast → actions
- `crewair/cli.py`: address + date + shift → plan
- `tests/test_rules.py`: the rules

```bash
uv sync
make plan P="Fresno" S=07-17
make test
```

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
