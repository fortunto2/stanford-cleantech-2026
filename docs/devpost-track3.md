# Devpost, Track 3 Resilient Systems (Asher's focus, 24 Oct 15:55)

**Elevator pitch (≤200):** A micro-local compliance and drone-tasking API that lets utilities dispatch line crews into smoke zones with a reading and a record, cutting outage time after a wildfire.

**Track:** Resilient Systems

## Story

## The problem

When a wildfire takes down a line, the utility has to restore power fast and, under Cal/OSHA §5141.1, determine the air its crew will breathe and log it before anyone goes in. The data is far from the break: smoke models have 40 km cells, and the nearest regulatory monitor can be 48 km away (measured at one of our test sites). So the dispatcher either waits for a canyon the wind has already cleared, or sends people without a record. Heat and smoke rules are the most-cited in California: 8,507 heat violations and $8.1M in penalties since 2019.

## What Crew Air does

A micro-local clearance workflow, built on a live air engine:

1. **Trigger.** NASA VIIRS sees a fire within 50 km of the work site. The API issues a sensor task with a bearing and a distance (`dispatch` in `/api/crew`).
2. **Reading.** A fixed PM2.5 node, or a drone carrying one outside the FAA flight restriction, samples the air at the break and reports it through the same endpoint the crew uses (`/api/crew/report`). A photo of the sky, judged by a vision model, is the second check.
3. **Record.** The plan recomputes in seconds: the EPA NowCast AQI, the hour each rule starts, N95s or respirators, and a printed sheet that states how the AQI was determined (§5141.1(c), Appendix A instrument line) with a sign-off. That is the document the crew goes in with, and the one an inspector asks for.

The same JSON drives a building's air handler (`plan.bms`: close outside air at the smoke hour), a home energy panel (`home`: pre-cool before the 4–9 pm peak, hold the battery before a PSPS) and a utility's dispatch. Thirteen SVCE communities on one map: airsignal.app/crew/grid. Every endpoint, no key: airsignal.app/api.

## Business

B2B SaaS for utilities and their contractors: a subscription for the API in the dispatch system, and a per-site fee for each compliance record. The crew app stays free. The customer's number is restored hours per outage; it comes from a pilot, not from us.

## How we built it

A Rust engine (NowCast, rulebooks as data, the plan, the checks) compiled to WASM in a Cloudflare Worker, Astro SSR, D1 for reports, MapLibre for the smoke map, a Swift 6 app, a Python CLI. Public data only: Open-Meteo, NASA FIRMS, AirNow, NWS, EPA, BLS, DOL.

## What we learned

A satellite sees heat, not smoke. A vision model is not a sensor. The rule does not forbid work in smoke; it requires a determination and a record, so that is what we sell. The drone payload is a concept; the API side is live.

**Disclosure:** built in the hacking hours on top of our earlier open-source work (the Air Signal site, the AQI merge, camera geometry); the README says which is which.
