# Crew Air: what we are, the 3-minute pitch, the 2-minute video

## Positioning, settled Sat 15:15 after the mentors

**What we do.** One forecast, read for the person responsible for people outdoors: the hour each
Cal/OSHA rule starts on a shift (N95s at AQI 151, shade and water at 80 °F), checked by satellite, the
nearest monitor and a photo of the sky, printed as the sheet an inspector asks for. The same hours,
as JSON, for whoever controls a building, a home or a sensor.

**Who pays.** The employer of an outdoor crew: a farm, a landscaping contractor, a utility or its
line-crew contractor. The pain is a crew lead at 6 a.m. with a rule and no tool; the cost is the fine,
the downtime and the missing paper. Workers use it free.

**Where it goes next (the mentors' angle).** A grid-integration researcher at a national lab (pre-cooling and
Auto-DR research, pilots with PG&E; name kept private, he is referenced by idea only) confirmed the grid reading of the same signal: pre-cool before the
4–9 pm peak, hold the battery before a PSPS, close the damper in smoke. Carlo: name the pain, the
one feeling it pays; utilities already buy fire prediction (Overstory), what they do not have is the
hour the air changes for the crew. Asher: line crews after a fire, a reading at the work site when the
monitor is 48 km away; we keep it as "a reading and a record", not a legal clearance, and the drone
payload as a concept.

**What we do not claim.** Dollars or megawatts saved; predicting how fast a fire moves; a built drone;
certifying air. The employer determines the AQI (§5141.1(c), Appendix A); we record how.

## The 3-minute pitch (finalists: 3 min + 2 min Q&A)

Slides: cover · problem · fines · outcome · plan · layers · app · grid · linecrew · ladder · model · base · ask.

0:00 **Cover.** "Crew Air. California tells outdoor employers exactly what to do when smoke or heat
hits a crew. Almost nobody does it. We turn the forecast into that shift plan."

0:15 **Problem.** "N95s at AQI 151, shade and water at 80 °F. In the 2020–21 fire seasons farmworkers
spent 4.5 million worker-days at AQI 151 or worse. About 60% got no N95. The rule waits for a complaint,
and workers are afraid to complain."

0:35 **Fines.** "Heat gets cited: 8,507 violations, $8.1M since 2019. Smoke does not: 19 citations in
seven years. The usual miss is paper: no plan on site."

0:50 **Outcome / Plan.** "Place and shift in. Out: the hour each rule starts, the clean window for heavy
work, one printed sheet with a sign-off. Live for Fresno. One detail: Cal/OSHA goes by the current AQI,
the EPA NowCast. Forecast feeds give a 24-hour mean that lags a smoke front by most of a shift. We compute
the NowCast."

1:15 **Layers.** "Checked four ways: the model, NASA fires within 50 km, the AirNow monitor, and the crew.
A map shows where the smoke goes, hour by hour from the wind."

1:30 **App.** "In the crew's pocket, English and Spanish. Point the camera at the horizon; a vision model
says whether it sees smoke, right 11 or 12 times out of 12 on known photos, never wrongly. One tap, the
crew lead sees it."

1:50 **Grid.** "Heat and smoke days are the grid's worst days. The same strip carries the 4–9 pm peak
price and the cheap hours to pre-cool. For a utility: thirteen SVCE cities on one map. A grid-integration
researcher at a national lab told us this afternoon the signal could go into their utility panel pilots."

2:10 **Line crews.** "After a fire, a utility crew needs the air determined and logged before it goes in;
the monitor can be 48 km away. The API issues a sensor task; the reading comes back; the plan prints as
the record."

2:30 **Ladder / Model.** "A worker reports with no name. The crew lead fixes it or, after 30 minutes, it can
go further: a complaint drafted, never filed for them. Employers pay per site, workers never. Two of us,
built on our open air-quality engine; everything here was built in the hacking hours."

2:50 **Ask.** "We want one farm and one utility contractor for next summer, and a CCA to backtest one
summer's peak days against our hours."

### Q&A, one line each
- Why not AirNow / PurpleAir? They show a number; we give the hour the rule starts and the sheet.
- How accurate is smoke? Reliable for 24 h, risk beyond; we say so and we hold the monitor when the model is down.
- Dollars? Not claimed: a load model and a pilot.
- Can you certify the air? No: the employer determines, Appendix A allows any direct-reading PM2.5
  monitor used per the manufacturer; we record how, and the worse of model and reading applies.
- Drone? A task with a bearing; a node or a drone outside the TFR; the payload is a concept.
- Overstory? Before the fire, for the utility; we are the hour the air changes, for the crew.
- What was built before? Hosting, AQI merge, camera geometry; the engine, page, app and map in hacking hours.

## The 2-minute video (Rustam records, screen + voice)

0:00–0:15 airsignal.app/crew?place=Fresno&shift=07-17: the headline, peak AQI and °F, the actions list.
0:15–0:35 Scroll: hourly strip with "cool" and "peak", the Home block, the Building block.
0:35–0:55 The map: fires, the monitor, the cones; read the sentence under it aloud.
0:55–1:15 Phone: Plan tab, Check the sky with a smoky photo, the report, the crew lead board.
1:15–1:35 airsignal.app/crew/grid: 13 cities, the table, the four facts.
1:35–1:50 Print / Save PDF: the sheet with "How the AQI was determined" and the sign-off.
1:50–2:00 airsignal.app/api, then the GitHub repo. "Built in the hacking hours. Crew Air."

## After the hackathon (do not lose)
- Email the LBNL researcher (contact in private memory) within a week: the JSON, /crew/grid, offer OpenADR event or webhook, a 30-min call.
- Asher's line-crew case: find one utility contractor to ask what their dispatcher does today.
- Carlo's point: write the one-sentence pain on the landing page first.
- HRRR-Smoke raster instead of wind cones; OSM power layer on /crew/grid (Overpass failed from the venue).
- TestFlight once the app record exists; App Store only with explicit OK.
