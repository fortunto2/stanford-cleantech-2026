# Crew Air · video storyboard (utility cut), 24 Oct 16:25

Target: 90–120 s. Three layers mixed: generated cinematic shots (Kling / Sora / Seedance, 16:9, no text in
frame), our animated schematic (`pitch/story/story.html`), and live screens (web, app). Music: Rustam's own
track (`~/Music/!AudioStable/ambient.mp3`). Captions burned in, no voice needed; a voice line is given in
case Rustam records one.

| # | s | What we see | Caption (on screen) | Source |
|---|---|---|---|---|
| 1 | 0–6 | Aerial dusk: a wildfire front on a ridge, smoke pouring into a valley, a power line crossing it, one span down and sparking | **A fire takes down a line.** | Kling: *Aerial drone shot at dusk, a wildfire front on a dry California ridge, thick smoke pouring into a valley, a high-voltage power line crossing the valley with one span fallen and sparking, cinematic, photoreal, slow push-in, no text* |
| 2 | 6–12 | Utility yard at dawn: bucket trucks idling, line crew in hard hats by the trucks, a dispatcher in a control room looking at a wall of screens, waiting | **The crew is ready at 06:00. The dispatcher cannot send them.** | Kling: *Utility line crew in hard hats and yellow FR shirts waiting beside bucket trucks at dawn, orange smoky sky, a dispatcher inside a control room looking at a wall of screens, tense, documentary realism, no text* |
| 3 | 12–20 | Schematic: the map, the work site, the only regulatory monitor 48 km away, a 40 km model cell over the whole canyon; the clock runs 06:00 → 10:00 | **The smoke model has 40 km cells. The nearest monitor is 48 km away. Hours pass.** | story.html scene 2 |
| 4 | 20–28 | Schematic: a satellite passes, VIIRS sees the fire, the API card appears: `dispatch: launch, bearing 333°, 9 km` | **NASA sees the fire. Crew Air issues a sensor task.** | story.html scene 3 |
| 5 | 28–38 | **Sensor network:** along the line, small PM2.5 nodes on poles light up one by one with readings (38, 41, 35 µg/m³); where there is no node, a drone lifts off from a truck with a sensor payload and flies to the break, outside the fire's flight restriction | **Fixed nodes where there is infrastructure. A drone where there is none.** | Kling: *A small industrial quadcopter with a sensor box and a thin intake tube lifting off from a utility truck bed beside a downed power line in a smoky canyon, telephoto, cinematic, no text* + story.html scene 4 (nodes) |
| 6 | 38–48 | **Prediction:** the schematic shows the wind cone from the fire by the hour; the model says the canyon clears by 10:30; the reading at the site confirms it: 38 µg/m³, AQI 108, under 151 | **The model says the canyon clears by 10:30. The reading confirms it.** | story.html scene 5; live: airsignal.app/crew map with the hour-by-hour cones |
| 7 | 48–58 | The record: the printed sheet (how the AQI was determined, instrument, hour, rule, sign-off); the app's Plan tab with the orange Sensor task card and the Record line | **The record the rule requires. Signed at the briefing.** | live: /crew print view; pitch/shots/v2-plan-sensor-task.png, v2-plan-record.png |
| 8 | 58–66 | Bucket trucks rolling out through thinning smoke; a lineman on the pole in an N95; the clock stops at 10:40 | **The crew goes in. 10:40, not 14:00.** | Kling: *Utility bucket trucks driving down a dirt road through thinning wildfire smoke toward a downed power line, morning light breaking through, a lineman in an N95 climbing a pole, cinematic, no text* |
| 9 | 66–78 | The utility view: airsignal.app/crew/grid, 13 communities on one map, fires and cones; the JSON for the DERMS and the home panel (pre-cool before the 4–9 pm peak) | **The same hours for the grid: 13 communities, one map, one JSON.** | live: /crew/grid, /api |
| 10 | 78–90 | Hero image (drone with the title), then the end card | **Crew Air · airsignal.app/crew · Rustam Salavatov · Asher Popper** | pitch/hero.jpg; story.html end |

Voice line, if recorded (60 words): "A fire takes down a line. The crew is ready at six. The rule says
determine the air and log it first, and the nearest monitor is forty-eight kilometres away. So the
dispatcher waits. Crew Air sees the fire from orbit, sends a sensor for a reading, predicts when the canyon
clears, and prints the record. The crew goes in at ten-forty."

What is real and what is a concept, for the captions: the API, the task, the map, the cones, the record,
the app and the sensor-network endpoint are live; the drone payload and the fixed nodes are a concept.
No dollars, no hours-saved claim in the captions.

How to assemble: generated clips into `pitch/video/kling/01.mp4 … 08.mp4`; then
`uv run python pitch/video/assemble.py` (to be written when the clips exist) concatenates clips, schematic
segments (`pitch/story/story.html` captured by `pitch/story/actions.json`) and screen captures with the
captions above.
