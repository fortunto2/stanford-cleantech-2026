"""Cal/OSHA thresholds as code. Pure functions: hourly forecast in, shift actions out.

Sources: Title 8 §5141.1 (wildfire smoke, AQI for PM2.5) and §3395 (outdoor heat illness).
"""

from dataclasses import dataclass

SMOKE_N95 = 151  # §5141.1: provide N95s, notify, reduce exposure
SMOKE_REQUIRED = 501  # §5141.1: respirator use mandatory above 500
HEAT_SHADE = 80  # §3395: shade up, water, cool-down on request
HEAT_HIGH = 95  # §3395: high-heat procedures


@dataclass(frozen=True)
class Hour:
    time: str  # local ISO hour, e.g. 2026-10-24T13:00
    aqi: int | None  # US AQI for PM2.5
    temp_f: float | None


@dataclass(frozen=True)
class Action:
    time: str
    rule: str
    text: str


def _first(hours: list[Hour], pred) -> Hour | None:
    return next((h for h in hours if pred(h)), None)


def plan(hours: list[Hour]) -> list[Action]:
    """Actions for one shift, the first hour each threshold is crossed."""
    out: list[Action] = []
    checks = [
        (lambda h: h.aqi is not None and h.aqi >= SMOKE_REQUIRED, "§5141.1",
         "AQI {aqi}: respirators mandatory, move work indoors to filtered air if possible"),
        (lambda h: h.aqi is not None and h.aqi >= SMOKE_N95, "§5141.1",
         "AQI {aqi}: hand out N95s, tell the crew, cut exposure"),
        (lambda h: h.temp_f is not None and h.temp_f >= HEAT_HIGH, "§3395",
         "{temp:.0f}°F: high-heat procedures, pre-shift meeting, watch the crew"),
        (lambda h: h.temp_f is not None and h.temp_f >= HEAT_SHADE, "§3395",
         "{temp:.0f}°F: shade up, water at hand"),
    ]
    smoke_done = heat_done = False
    for pred, rule, text in checks:
        if (rule == "§5141.1" and smoke_done) or (rule == "§3395" and heat_done):
            continue
        h = _first(hours, pred)
        if h:
            out.append(Action(h.time, rule, text.format(aqi=h.aqi, temp=h.temp_f or 0)))
            smoke_done |= rule == "§5141.1"
            heat_done |= rule == "§3395"
    clear = [h.time[11:16] for h in hours
             if (h.aqi or 0) < SMOKE_N95 and (h.temp_f or 0) < HEAT_SHADE]
    if out and clear:
        out.append(Action(clear[0] + "", "plan", f"Heavy work in clear hours: {clear[0]}–{clear[-1]}"))
    return sorted(out, key=lambda a: a.time)
