# Next steps (handoff, Fri 23 Oct 2026, ~21:00 PT)

Deadline: **Devpost by Sat 24 Oct 17:00 PT** (https://stanford-cleantech-hackathon.devpost.com/), finalists
demo 17:00–19:00 (3 min + 2 min Q&A), awards 19:00. Building allowed until 17:00 Saturday.

## Done
- CLI `crewair` on live Open-Meteo forecasts, rulebook engine, `rulebooks/us-ca.yaml`, 5 tests green.
- Pitch deck (12 slides): https://claude.ai/artifact/Kxr2SHzzCTs2JyCXoSFSsQ, sources in `pitch/`.
- Repo public, single clean history.

## Saturday, in order
1. **Team** (rules: 2–5). Morning in person, 9:00 breakfast / mentorship block A; Devpost Participants tab.
2. **AQI check**: is Open-Meteo `us_aqi_pm2_5` a 24 h average? Cal/OSHA §5141.1 uses the current hourly
   AQI (NowCast). If averaged, compute NowCast from hourly `pm2_5` ourselves (EPA formula) and switch the
   rulebook metric. Add a test with a known answer.
3. **Sharper smoke**: NOAA HRRR-Smoke (`noaa-hrrr-bdp-pds` on AWS, `MASSDEN` near-surface smoke) for US
   addresses; keep CAMS as the fallback. Show "model only / sensor nearby" confidence.
4. **One web page** for the demo (FastAPI or static + JS): address, shift → plan, map with FIRMS fires.
5. **BMS signal** (Track 3): `crewair bms <place>` → JSON like `{"recirculate_at": "12:00", "reason": ...}`.
6. **Devpost**: text from README, 2-min video (CLI + page), repo link, tracks 2 and 3.

## Later (after the hackathon)
- Section on airsignal.app (`/crew`), SEO pages for Cal/OSHA smoke/heat questions, analytics, lead form
  for multi-site and BMS. Not before Sat 17:00, so the demo stays clearly hackathon-built.
- More rulebooks (OR, WA, Canada AQHI, Spain/Italy heat), each checked against the source text.
- Product loop: evening alerts (SMS/email), multiple sites, PDF log for inspectors, Spanish.
- Open-Meteo is free only non-commercially: switch to HRRR + NWS or pay before any paid use.
