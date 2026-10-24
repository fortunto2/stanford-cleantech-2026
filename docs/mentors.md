# Mentor conversations, Sat 24 Oct 14:26–14:56 PT (supervox, far-field, names as heard)

## Carlo (mentor, t=8–14)
- Utilities already buy wildfire prediction (he named Overstory); once a fire burns it is too late for them,
  they want to know in advance.
- "Name the pain you remove; the one feeling it pays." Assets at risk: buildings, data centers in fire areas;
  homeowners would want 30–60 minutes of warning.
- Our answer for the pitch: the pain is a crew lead at 6 a.m. with a rule (§5141.1, §3395) and no tool;
  the payer is the employer (fine, downtime, the sheet an inspector asks for).

## Ros (local, smart-panel + battery behind the meter, pilot with PG&E, street-light VPP; t=14–30)
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
