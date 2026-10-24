"""Hourly smoke and temperature forecast for an address. Open-Meteo (CAMS + weather models), no key.

Every metric a rulebook may name is filled here: us_aqi_pm25, pm25_ugm3, temp_f, temp_c.
"""

import json
import urllib.parse
import urllib.request

from crewair.rules import Hour


def _get(url: str, **params) -> dict:
    with urllib.request.urlopen(f"{url}?{urllib.parse.urlencode(params)}", timeout=20) as r:
        return json.load(r)


def geocode(place: str, state: str = "California", country: str = "US") -> tuple[float, float, str]:
    name = place.split(",")[0].strip()
    r = _get("https://geocoding-api.open-meteo.com/v1/search", name=name, count=10, countryCode=country)
    if not r.get("results"):
        raise ValueError(f"place not found: {place}")
    g = next((x for x in r["results"] if x.get("admin1") == state), r["results"][0])
    return g["latitude"], g["longitude"], f"{g['name']}, {g.get('admin1', '')}"


def hourly(lat: float, lon: float, days: int = 2, tz: str = "America/Los_Angeles") -> list[Hour]:
    common = dict(latitude=lat, longitude=lon, forecast_days=days, timezone=tz)
    aq = _get("https://air-quality-api.open-meteo.com/v1/air-quality",
              hourly="us_aqi_pm2_5,pm2_5", **common)["hourly"]
    wx = _get("https://api.open-meteo.com/v1/forecast", hourly="temperature_2m", **common)["hourly"]
    temp_c = dict(zip(wx["time"], wx["temperature_2m"]))
    hours = []
    for t, aqi, pm in zip(aq["time"], aq["us_aqi_pm2_5"], aq["pm2_5"]):
        c = temp_c.get(t)
        hours.append(Hour(t, {"us_aqi_pm25": aqi, "pm25_ugm3": pm, "temp_c": c,
                              "temp_f": None if c is None else c * 9 / 5 + 32}))
    return hours
