"""The 30-second trailer: fire, the wait, the reading, the phone, the record, on the bars of the track; the
live product at the end. Same renderer as cut.py.

    uv run --with pillow python pitch/video/trailer.py       # writes pitch/video/crew-air-trailer.mp4
"""

from cut import CREDITS, render
from style import AMBER, MUTED, PAPER

# (clip, source offset s, bars, line). 12 bars ≈ 30 s.
SHOTS = [
    ("fire", 0.0, 2, "A FIRE"),
    ("aerial2", 0.0, 1, "A LINE DOWN"),
    ("crew", 0.0, 1, "THE CREW WAITS"),
    ("dispatch", 0.0, 1, "THE MONITOR IS 48 KM AWAY"),
    ("sat", 0.0, 1, "A SATELLITE SEES THE FIRE"),
    ("drone", 0.0, 1, "A DRONE READS THE AIR"),
    ("phone", 1.0, 1, "FIRE ON THE HORIZON · 21 KM"),
    ("phone", 7.5, 1, "THE SHIFT PLAN"),
    ("lineman", 0.0, 1, "A READING. A RECORD."),
    ("lights", 0.0, 1, "10:40, NOT 14:00"),
    ("hero", 0.0, 1, "CREW AIR · LIVE TODAY"),
    ("end", 0.0, 1, ""),
]

if __name__ == "__main__":
    render("trailer", SHOTS, [(120, True, "airsignal.app/crew", PAPER),
                              (44, False, "Live now: the site, the API and the iOS app", AMBER),
                              (34, False, CREDITS, MUTED)], fade=1.0, zoom=(0.0012, 1.08))
