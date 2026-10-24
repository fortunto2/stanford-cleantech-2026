"""Rulebook engine. Pure functions: hourly forecast + a jurisdiction's rulebook in, shift actions out.

The engine knows no law. Thresholds, metrics, wording and citations live in `rulebooks/<id>.yaml`.
"""

from dataclasses import dataclass, field
from pathlib import Path

import yaml

RULEBOOKS = Path(__file__).resolve().parent.parent / "rulebooks"


@dataclass(frozen=True)
class Hour:
    time: str  # local ISO hour, e.g. 2026-10-24T13:00
    metrics: dict[str, float | None] = field(default_factory=dict)


@dataclass(frozen=True)
class Rule:
    id: str
    group: str
    metric: str
    gte: float
    action: str
    cite: str


@dataclass(frozen=True)
class Action:
    time: str
    rule: str
    text: str


def load(jurisdiction: str = "us-ca") -> list[Rule]:
    doc = yaml.safe_load((RULEBOOKS / f"{jurisdiction.lower()}.yaml").read_text())
    return [Rule(**r) for r in doc["rules"]]


def _crossed(h: Hour, r: Rule) -> bool:
    v = h.metrics.get(r.metric)
    return v is not None and v >= r.gte


def plan(hours: list[Hour], rules: list[Rule]) -> list[Action]:
    """For each group, the most severe rule crossed in the shift, at the first hour it is crossed;
    then the clear hours (no rule crossed) as the window for heavy work."""
    out: list[Action] = []
    for group in dict.fromkeys(r.group for r in rules):
        for r in sorted((r for r in rules if r.group == group), key=lambda r: -r.gte):
            h = next((h for h in hours if _crossed(h, r)), None)
            if h:
                text = r.action.format(value=h.metrics[r.metric], aqi=h.metrics.get("us_aqi_pm25"))
                out.append(Action(h.time, r.cite, text))
                break
    clear = [h.time[11:16] for h in hours if not any(_crossed(h, r) for r in rules)]
    if out and clear:
        out.append(Action(hours[0].time, "plan", f"Heavy work in clear hours: {clear[0]}–{clear[-1]}"))
    return sorted(out, key=lambda a: a.time)
