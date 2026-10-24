"""crewair "Fresno" --date 2026-10-24 --shift 07-17 --rules us-ca  → the shift plan."""

import argparse
import datetime as dt

from crewair.forecast import geocode, hourly
from crewair.rules import load, plan


def main() -> None:
    p = argparse.ArgumentParser(prog="crewair")
    p.add_argument("place")
    p.add_argument("--date", default=(dt.date.today() + dt.timedelta(days=1)).isoformat())
    p.add_argument("--shift", default="07-17", help="start-end hour, local")
    p.add_argument("--rules", default="us-ca", help="rulebook id in rulebooks/")
    a = p.parse_args()
    start, end = (int(x) for x in a.shift.split("-"))
    lat, lon, name = geocode(a.place)
    hours = [h for h in hourly(lat, lon) if h.time.startswith(a.date) and start <= int(h.time[11:13]) < end]
    print(f"{name} ({lat:.3f}, {lon:.3f}) · {a.date} · shift {start:02d}:00–{end:02d}:00 · rules {a.rules}")
    peak = lambda m: max((h.metrics.get(m) or 0) for h in hours)  # noqa: E731
    print(f"peak AQI {peak('us_aqi_pm25'):.0f} · peak {peak('temp_f'):.0f}°F")
    actions = plan(hours, load(a.rules))
    if not actions:
        print("No smoke or heat thresholds crossed. Normal shift.")
    for x in actions:
        print(f"  {x.time[11:16]}  [{x.rule}]  {x.text}")


if __name__ == "__main__":
    main()
