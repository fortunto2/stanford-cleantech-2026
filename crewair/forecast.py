"""Hourly smoke (US AQI for PM2.5) and temperature forecast for an address. Open-Meteo, no key."""

import json
import urllib.parse
import urllib.request

from crewair.rules import Hour


def _get(url: str, **params) -> dict:
    with urllib.request.urlopen(f"{url}?{urllib.parse.urlencode(params)}", timeout=20) as r:
        return json.load(r)


def geocode(place: str, state: str = "California") -> tuple[float, float, str]:
    name = place.split(",")[0].strip()
    r = _get("https://geocoding-api.open-meteo.com/v1/search", name=name, count=10, countryCode="US")
    if not r.get("results"):
        raise ValueError(f"place not found: {place}")
    g = next((x for x in r["results"] if x.get("admin1") == state), r["results"][0])
    return g["latitude"], g["longitude"], f"{g['name']}, {g.get('admin1', '')}"


def hourly(lat: float, lon: float, days: int = 2) -> list[Hour]:
    common = dict(latitude=lat, longitude=lon, forecast_days=days, timezone="America/Los_Angeles")
    aq = _get("https://air-quality-api.open-meteo.com/v1/air-quality", hourly="us_aqi_pm2_5", **common)
    wx = _get("https://api.open-meteo.com/v1/forecast", hourly="temperature_2m",
              temperature_unit="fahrenheit", **common)
    temps = dict(zip(wx["hourly"]["time"], wx["hourly"]["temperature_2m"]))
    return [Hour(t, a, temps.get(t)) for t, a in zip(aq["hourly"]["time"], aq["hourly"]["us_aqi_pm2_5"])]
