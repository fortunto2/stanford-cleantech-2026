# Mentor conversations, Sat 24 Oct 14:26–14:56 PT (supervox, far-field, names as heard)

## Carlo (mentor, t=8–14)
- Utilities already buy wildfire prediction (he named Overstory); once a fire burns it is too late for them,
  they want to know in advance.
- "Name the pain you remove; the one feeling it pays." Assets at risk: buildings, data centers in fire areas;
  homeowners would want 30–60 minutes of warning.
- Our answer for the pitch: the pain is a crew lead at 6 a.m. with a rule (§5141.1, §3395) and no tool;
  the payer is the employer (fine, downtime, the sheet an inspector asks for).

## Rongxin Yin, LBNL Grid Integration Group ("Ros" in the transcript; t=14–30)
- Senior Scientific Engineering Associate at Lawrence Berkeley National Laboratory since 2007: demand
  flexibility of commercial buildings, Auto-DR / OpenADR, thermal energy storage, and a 2010 paper on
  pre-cooling commercial buildings with thermal mass in California (our `home.precool` is his topic).
  DFAT toolkit (2025). Here: smart panel + battery behind the meter, pilot with PG&E, street-light VPP.
  Confirmed interest in integrating; they take energy forecasts from PG&E. Contact kept privately.
- Users he sees: building and facility managers, city managers, healthcare, hotels; "vulnerable populations".
- Two uses he offered: evacuation planning on a detection; PSPS preparation: pre-charge the battery to 100%
  and plan 10–25 h of backup. Both map onto `home` and `dispatch` in our JSON.
- HVAC: close the outside-air damper when smoke passes a threshold. That is `plan.bms`; show it, do not re-explain.
- His dashboard: CAISO supply/demand, PG&E PSPS 7-day calendar ("ours is faster than PG&E"). He offered
  to connect it to our API and to use our signal in his pilots; email exchanged on paper (photo on Rustam's
  phone). Follow up after the hackathon: a free pilot demo, our JSON into his panel.
- He asked "what is your model?" → honest answer: deterministic rules + NowCast in Rust; ML only in the
  sky check. Not a fire-spread predictor.

## Another mentor to the neighbouring team (t=0–8), worth keeping
- Every screen must carry the story; consumers care about the bill, developers about the return.
- Capacity markets pay for being available; peaker plants and marginal cost by hour.

## Self-correction for the judges
- Open with the worker and the rule, not "I have many ideas".
- Never say we predict how fast a fire arrives. We draw a wind cone and say so.

## Overstory (looked up 15:10, after Carlo named them)
- Vegetation and wildfire intelligence for utilities: satellite + AI, tree by tree, Fuel Detection Model;
  PG&E and 50+ utilities, "6 of the 10 largest in North America"; Series B $43M Nov 2025 (~$68M total),
  80 people, Amsterdam/Boston; partners Watch Duty, Arcos. Sales by demo, SOC 2.
- Nothing on smoke, air quality, crews on the day, Cal/OSHA. They work before the fire, we work the hour
  the air changes. A channel (Arcos runs crews), not a rival. Sources: overstory.com; Series B post.
