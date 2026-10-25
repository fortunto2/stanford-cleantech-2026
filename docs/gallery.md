# Cleantech Hackathon 2026: gallery survey

Read on 24 Oct 2026 from https://stanford-cleantech-hackathon.devpost.com/project-gallery (one page, 19 projects, Crew Air skipped = 18). Every project page was opened and read in full. WebFetch got HTTP 403 from Devpost, so pages were fetched with curl and a browser User-Agent. Nothing on the gallery or on any project page marks a winner or a prize yet. "Winner: not stated" below means exactly that.

Conventions: **Track** is stated only when the page says it; `~T1.1` means inferred from the organizer's track list in `docs/tracks.md`. **Finalist** comes from `/Users/rustam/.supervox/live/summary.md`, which has names as heard on stage; the match to a Devpost page is mine and marked `(match inferred)` where the stage name differs. Two summary names have no Devpost page of the same name: "Acha" is most likely **matcha** (solo builder, ElevenLabs audio, AirNow/NWS/Cal OES), and "DER intelligence layer" is **WattNext**. "Juby" is **Judy**. "Data-center routing" is **Follow The Sun**.

## 1. All projects

| Project | Track | Idea (one line) | Data sources | Live / repo | Finalist | Winner |
|---|---|---|---|---|---|---|
| [GridLight](https://devpost.com/software/gridlight) | ~T1.1 | Traffic light merging TOU price and hourly grid CO2; cost of running an appliance now vs best time; Green Button "bill X-ray" in browser | CAISO Today's Outlook CO2 + demand files, PG&E TOU tariffs (proxy for SVCE), SVCE CalFUSE hourly prices via GridX API, Green Button CSV | live + repo | no | not stated |
| [SolarCharge](https://devpost.com/software/solarcharge) | ~T1 | Charge EV from rooftop solar vs export vs split, under California Net Billing Tariff | SVCE rates + GridShift findings, PG&E E-ELEC, PG&E 2026 hourly export credits, CPUC docs | "live" link is a ChatGPT conversation; no repo | no | not stated |
| [Follow The Sun](https://devpost.com/software/follow-the-sun-nmp93y) | ~T1.2 (Grid) | Simulator that routes AI queries to the datacenter with lowest energy use/cost within a latency limit; claims 13.7% energy cut at <100 ms | "public datasets" (hardware efficiency, weather cooling, demand curves); none named | live (Vercel), no repo | yes (Grid) | not stated |
| [Housemates](https://devpost.com/software/housemates-ig482y) | ~T1.2 (Grid) | Appliance photo + label OCR becomes a chat "Applimon" that says when to run it; iMessage bridge in beta | Open-Meteo; price and carbon signals are **simulated** (page says so) | repo, no live link | yes (Grid) | not stated |
| [Judy](https://devpost.com/software/judy-q6x1mc) | ~T1.2 (Grid) | Smart plugs + RL model that pauses devices in peak hours | smart-plug telemetry; no public data named | live (Vercel), no repo | yes (Grid, as "Juby") (match inferred) | not stated |
| [Griddy](https://devpost.com/software/griddy-oz4fxe) | not stated (grid) | Click any California site for a 0-100 build score, hourly simulation, cost and CO2 of solar/wind/storage/gas | EIA, CAISO, LBNL Queued Up, NREL ATB, EPA, Census, Earth Engine; two XGBoost models | live (getgriddy.app), no repo | no | not stated |
| [Shadow Plan](https://devpost.com/software/shadow-plan) | Track 1 (stated) | Checks CPUC's 77-substation solar/battery plan against CAISO upgrade delays, queue and county land decisions; drafts a CPUC comment | CAISO upgrade list and queue, county agendas/PDFs (Tesseract OCR), CAISO hourly grid | live (Vercel preview), no repo | no | not stated |
| [US Heat and Cold Plan Audit](https://devpost.com/software/county-heat-and-cold-plan-audit) | ~T2.1 | LLM codes 50 heat/cold plan PDFs; county map of lives/yr a better mix of measures would save at equal cost | plan PDFs, EpiNOAA county temps 1999-2024, EPA CIRA curves, CDC WONDER | live (GitHub Pages), no repo | yes (Climate & Health) | not stated |
| [Dengai](https://devpost.com/software/dengai-daily-dengue-inspection-routes-for-makassar) | ~T2.2 | Drone-detected breeding sites become daily inspection routes per team, sent by WhatsApp | OSM via OSMnx; **synthetic** detections (real ones not released) | repo + pitch deck, no live | yes (C&H) | not stated |
| [Locasur](https://devpost.com/software/locasur) | ~T2.2 | Same problem: priority scores become inspection routes, offline-capable web app | "real satellite measurements" for Tallo, simulated larvae labels | live (chatgpt.site), no repo | no | not stated |
| [The Chill Factor](https://devpost.com/software/the-chill-factor) | T2 per summary (UC Davis FNRIC challenge) | Orchard-level chill hours; green/yellow/red verdict vs past seasons plus forecast | CIMIS, FNRIC sensors, PRISM, Daymet, NWS National Blend, 16-day forecasts | live (web.app), no repo | yes (C&H) | not stated |
| [FlareWise](https://devpost.com/software/ember-ni0e52) | not stated | Which gas flares to capture under a budget, trading gas value against people downwind | NASA FIRMS VIIRS + Nightfire, ERA5 wind, Census grid, EPA NO2 monitors | live (GitHub Pages) + repo | no | not stated |
| [matcha](https://devpost.com/software/matcha-4g8ed5) | ~T3 (Resilience) | Daily climate check-in with audio, backup-battery sizing, small "power moves" | Open-Meteo, NWS alerts, EPA AirNow, Cal OES outages | live (Lovable), no repo | yes as "Acha" (match inferred) | not stated |
| [Pismo](https://devpost.com/software/pismo) | ~T3 | Replays Feb 2024 storm: forecast trigger for home batteries fired 27 h before the Humboldt High Wind Warning | NOAA GFS via Earth Engine, NWS alert archive (Iowa Mesonet), EAGLE-I outages 2018-21 | live (claude.ai artifact), no repo | no | not stated |
| [WattNext](https://devpost.com/software/project-p8qw6by7u91o) | ~T3.2 | Scores each household for grid value, outage exposure, support need, data confidence; enrol and dispatch to a Raspberry Pi battery | Census ACS, CPUC fire tiers, OSM, Open-Meteo, Earth Engine, Planet, Google Solar API; households **synthetic** | no live, no repo | yes as "DER intelligence layer" (match inferred) | not stated |
| [ResilienceOS](https://devpost.com/software/resilienceos-outage-risk-for-life-dependent-customers) | ~T3.2 | Storm outage risk for life-dependent customers in SCE territory, backup-battery check, LLM action plan | EAGLE-I, NOAA HRRR, NVIDIA StormCast; customer sites **synthetic** | no live, no repo | yes (Resilience) | not stated |
| [AI-Powered Carbon Credit Verifier](https://devpost.com/software/ai-powered-carbon-credit-verifier) | not stated | AI validates simulated IoT energy data and mints carbon-credit tokens on Polygon | simulated MQTT/CSV | repo, no live | no | not stated |
| [SatQuery AI](https://devpost.com/software/satquery-ai) | not stated | Local satellite-image analysis: change detection, land cover, PDF report; inspired by an ISRO problem statement | uploaded or sample imagery | repo, no live | no | not stated |

## 2. Copy into Air Signal (5)

1. **Hourly CO2 next to price on the TOU plan.** From GridLight. Air Signal's home plan already carries E-TOU-C peak 16-21 and pre-cool 13-16. GridLight's finding is that off-peak is not one thing: 4 AM and 1 PM cost the same 29 cents on E-TOU-C, yet 4 AM carries 324 g/kWh against 141 g/kWh at 1 PM (their numbers, from three October weekdays). Data: CAISO Today's Outlook CO2-by-source and demand files, no key needed. Build: 2-3 days, one hourly intensity table in the Rust engine plus a Worker cron.
2. **One-click calendar file of today's green windows.** From GridLight. Fits "no accounts, offline-first": an `.ics` file replaces push notifications. Data: the same hourly table as above. Build: half a day.
3. **Downwind exposure and a rotation test for smoke or flare sources.** From FlareWise. They cluster FIRMS VIIRS detections into sites with DBSCAN, run an hourly Gaussian plume on ERA5 wind, and land it on a Census grid. Their check is worth stealing for the smoke model: measured NO2 rose on days with wind from the flares (4.8 ppb vs 2.2 ppb upwind at Karnes), and the signal vanished when every wind direction was rotated 180 degrees. Data: FIRMS (already wired), wind from Open-Meteo or ERA5, Census population. Build: 4-5 days for the plume layer; the rotation test alone is 1 day against existing AirNow monitors.
4. **Daily brief with backup-power sizing.** From matcha. Combines weather, AirNow, NWS alerts and Cal OES outage reports in one calm briefing, plus a deterministic calculator (devices x hours = battery kWh). Page says AI only words the text and the sizing is plain TypeScript. Data: all four already available except Cal OES, whose exact endpoint the page does not state. Build: 1-2 days for the calculator and brief; the outage feed is unknown until checked.
5. **"This season vs past years" verdict from sparse data.** From The Chill Factor. One number and one colour against history, built from daily min/max by reconstructing hourly values. For Air Signal this is "smoke hours this season vs past seasons at this monitor", using the AirData history behind `make evidence`. Data: EPA AirData, PRISM or Daymet if temperatures are wanted. Build: 1 day.

Considered and left out: Pismo's forecast-ahead trigger (rain >= 15 mm or wind >= 18 m/s on NOAA GFS through Earth Engine). It is the closest to a real idea for "act before the alert", but it was tuned on two months, tested on one storm, and the page itself says wind predicts wind alerts and outages only weakly.

## 3. Worth a standalone small app (3)

**GridLight.** Static, dependency-free web app (vanilla JS, hand-built SVG), 100% in the browser, no sign-up, no upload. It uses data any PG&E customer can download. Ops after launch: refresh the CAISO intensity table and the tariff table when PG&E changes rates (March 2026 prices are embedded).
- Moat: none. Public data, simple logic. SVCE is a possible channel, not a moat.
- Built: working app, Playwright tests, four rate plans in two seasons, repo and live page. CalFUSE prices for 21-25 Oct are embedded and fetched live when the browser allows.
- Claimed beyond that: the "$62/month, CO2 -18%" result is a simulated San Jose EV home, not a customer. PG&E prices stand in for SVCE (they report GreenStart bills within 0.3%). Carbon is the mean of three October weekdays plus one July day, not a live feed. The SVCE program view is a calculator over N assumed homes.
- Overlaps Air Signal's home plan, so it is a feature before it is an app.

**FlareWise.** Pure public data (FIRMS, ERA5, Census, EPA), a reproducible pipeline with tests and CI, a dashboard that "runs offline", and one config file per oil field.
- Moat: none. Anyone can rerun it. The only asset is the validation story.
- Built: Eagle Ford 2023-2024, 1,574 flare sites, a monitor check at Karnes County, Monte Carlo ranges. Repo and live page exist.
- Claimed: the budget plans (about 1,250 vs 28,000 people protected) rest on screening-level capture costs and a modelled plume. The page admits only 19 flares pay for themselves at $2.50 per MMBtu and that the cheapest-gas-first plan avoids more greenhouse gas than the health plan. Buyer is an operator or regulator; as a free public "who is downwind of flares" map it needs no customer.

**US Heat and Cold Plan Audit.** Static site on GitHub Pages, no accounts, every number linked to a quote on the plan page. After the build there is nothing to operate.
- Moat: the coded database of plans, which costs LLM time to extend. Nothing stops a copy.
- Built: 50 plan documents coded with a fixed codebook and "not stated" when silent, 326 jurisdictions analysed in California and Texas, engine with a lint test that bans place names in code. The page does not say how the agent agreement or the LA County figure quoted on stage was measured.
- Risk: plans change, so it goes stale; coverage is two states; the effect sizes come from one 2026 review paper.

## 4. Skip

**Needs a business or a paying institution**
- Griddy: broad planning tool for developers and utilities, built on twelve datasets; large, live, no repo to borrow from.
- Shadow Plan: audience is CPUC staff and buyers like SVCE; one-off analysis of one planning round.
- ResilienceOS: needs an SCE-type utility and real customer lists; sites and batteries are synthetic.
- WattNext: needs an aggregator or CCA and real permit/meter data; households synthetic, outage probability is a picked scenario.
- Follow The Sun: needs cloud providers to change routing; a simulator with unnamed data.
- SolarCharge: needs solar + EV owners and charger control; control is simulated and the demo link is a chat page.

**Needs hardware**
- Judy: smart plugs and a server; no public data named.

**Needs a partner or field access**
- Dengai and Locasur: need a Makassar health center and the Rosser lab's drone detections; both use synthetic data and neither has been tested with a health team.
- The Chill Factor: the plan is subscription ($5,000 per 1,000 acres, their estimate) plus in-orchard sensors; the $3.75M at-risk figure is their estimate.

**Vapor or off-theme**
- AI-Powered Carbon Credit Verifier: simulated IoT, blockchain tokens, "built in 6 hours".
- SatQuery AI: generic image analysis from an ISRO problem statement, nothing cleantech-specific.
- Housemates: price and carbon are simulated; conversation does not yet turn into an action.
- Pismo: one storm, one county, tuned on two months; kept only as an idea (see section 2).
- matcha: the useful parts are in section 2; the product needs paid ElevenLabs and Lovable AI calls, and marketplace revenue was the answer to judges' monetization question.
