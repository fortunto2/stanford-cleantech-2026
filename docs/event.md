## Event

Third annual Stanford Cleantech Hackathon, Stanford Climate Week. Fri 23 – Sat 24 Oct 2026.
Mackenzie Room, top floor, Jen-Hsun Huang Engineering Center, 475 Via Ortega, Stanford.
Full organizer guide: `docs/organizer-guide.txt`.

## Rules that matter

- **Building only during hacking hours: Fri 23.10 17:00 – Sat 24.10 17:00 PT.** Ideation and
  planning before that is allowed; no code before 17:00 Friday. This repo holds notes only until then.
- Team of 2–5. Team building happens at the event and in Slack `#team-formation`.
- Submit on Devpost (https://stanford-cleantech-hackathon.devpost.com/) by **Sat 17:00**.
- Round 1 is judged on Devpost; 3 finalists per track present live: 3 min demo + 2 min Q&A.
  Someone from the team must be there in person.
- Prize: $1,000 per track, split among the team.

## Schedule

| When | What |
|---|---|
| Fri 15:30–16:00 | Registration |
| Fri 16:00–17:00 | Opening, hacking starts at 17:00 |
| Fri 17:00–18:00 | Workshop: Google Earth Engine 101 |
| Fri 18:00–20:00 | Reception, dinner |
| Sat 09:00 | Breakfast, mentorship A until 11:00 |
| Sat 11:00–12:00 | Panel: From Stanford Research to Startup |
| Sat 13:00–15:00 | Mentorship B |
| Sat 15:00–15:45 | Panel: From Climate Data to Climate Action |
| Sat 16:00–17:00 | Mentorship C |
| **Sat 17:00** | **Devpost submission due** |
| Sat 17:00–19:00 | Demos and judging |
| Sat 19:00–20:00 | Awards |

No overnight stay at the venue.

## Links

- Slack: https://join.slack.com/t/cleantechhack-i5r1006/shared_invite/zt-4bzex42ep-E8KheX8WnwFvj0Ke19mHLQ
- Devpost: https://stanford-cleantech-hackathon.devpost.com/
- ElevenLabs credits: Discord https://discord.com/invite/VnBvbbcdEC, channel #coupon-codes, "Start Redemption"
- Earth Engine catalog: https://developers.google.com/earth-engine/datasets/
- Planet (non-Stanford EDU): https://www.planet.com/industries/education-and-research/
- AirNow API: https://docs.airnowapi.org/
- Carbon Aware SDK: https://carbon-aware-sdk.greensoftware.foundation/
- Organizer contact: angelali@stanford.edu

See `docs/tracks.md` for the tracks and the shortlist, `docs/checklist.md` for what to do before 17:00.

## Our access (checked 23.10 17:10)

- Earth Engine works via gcloud login (`EE_ACCOUNT`), Cloud project `superagentduper`
  (API call on COPERNICUS/S2_SR_HARMONIZED returned the collection).
  Code Editor: https://code.earthengine.google.com/?project=superagentduper
  Python/Colab: `ee.Authenticate(); ee.Initialize(project="superagentduper")`
- Planet: no application or confirmation found in the mail.
- Workshop: https://goto.stanford.edu/hack-gee101, cloned to `refs/` (gitignored).
