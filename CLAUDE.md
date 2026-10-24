# CLAUDE.md — Crew Air (Stanford Cleantech Hackathon 2026)

Hackathon repo. Deadline: Devpost Sat 24 Oct 2026 17:00 PT. Honor code: all building happens in hacking
hours (Fri 17:00 – Sat 17:00 PT); earlier open-source work is used only as disclosed in README "Where the
code is". Keep that table true when you add anything.

## Where things live (three repos)

- **Engine**: `~/startups/active/airq/airq-core/src/crew.rs` (Rust, tests with `cargo test --lib`), exported
  to WASM as `wasm_crew_plan`. Rulebook JSON: `airq-core/rulebooks/us-ca.json`.
- **Live page + API**: `~/startups/active/air-signal-web` — `src/pages/crew.astro`, `src/lib/crew.ts`,
  `src/pages/api/crew/{index,report,reports}.ts`, `src/pages/crew/escalate.astro`, D1 `crew_reports`.
  After changing crew.rs: `make wasm` there, then `make deploy`. Its CLAUDE.md governs that repo.
- **This repo**: Python CLI mirror (`crewair/`, `rulebooks/us-ca.yaml`), evidence script, pitch, `ios/`.

The Rust engine is the source of truth. The Python CLI mirrors the NowCast and rules but not the fire and
monitor checks; say so wherever it matters (demo uses the page).

## Commands

```bash
make test        # Python rules + NowCast known-answer tests
make plan P=Fresno S=07-17
make evidence    # worker-days at AQI 151+ from EPA AirData × BLS QCEW
make ios-test    # CrewKit tests (swift test), once ios/ exists
make ios-build   # simulator build
make -C ios install   # on Rustam's iPhone (TEAM/DEVICE in ios/Makefile.local, gitignored)
uv run python work/sky_eval.py   # Jev known-answer eval against prod
```

## Rules learned here (do not relearn them)

- Open-Meteo `us_aqi_pm2_5` is a **24-hour mean**. Cal/OSHA uses the current (NowCast) AQI. Compute it.
- AQI caps at 500: a rule `AQI >= 501` never fires. Smoke rules are concentrations (App. A).
- The newest AirNow hourly file fills in over the next hour: a listed monitor may have an empty PM2.5.
- A safety tool corrects down cautiously: ground factor clamped to [0.5, 3].
- `wrangler dev` keeps the edge cache across restarts: add a throwaway query param when testing `/api/*`.
- Numbers in the pitch come from `docs/evidence.md` with sources; never add one without a source.
- Astro's origin check returns 403 to multipart/urlencoded POSTs without an Origin header (apps, curl).
  App endpoints take JSON or a raw `image/jpeg` body.
- DOL API: urllib's default User-Agent is refused; it also answers 403 while throttled (429). Retry slow.
  §5141.1 is coded `51410001 <sub>`; a bare `5141 A` is the older §5141, not the smoke rule.
- Jev: the smoke question is reliable on our eval, its visibility score is not. Re-run `work/sky_eval.py`
  after changing any question wording; it prints every answer, not just the score.
- Open-Meteo answers 429 "Daily API request limit exceeded" to the Worker for a whole UTC day: the limit is per
  IP and Cloudflare's egress IPs are shared. The plan then holds the nearest AirNow reading and takes NWS
  temperatures (`fallback` in the answer); errors carry the upstream status so this is visible in one curl.
- Slides deck: edit via the Artifact (read first), then copy changed slides into `pitch/slides/`.
