"""EPA NowCast for PM2.5 and the AQI it maps to (2024 breakpoints).

Cal/OSHA §5141.1 goes by the current AQI, which AirNow computes as a NowCast over the last 12 hours.
Open-Meteo's `us_aqi_pm2_5` is a 24-hour mean (checked 23 Oct 2026: it matches our 24 h mean within
±3 and is 2-3x off the hourly value), so it lags a smoke front by most of a shift. Same maths as
airq-core `crew.rs`, which powers airsignal.app/crew.
"""

import math

PM25 = [(0.0, 9.0, 0, 50), (9.1, 35.4, 51, 100), (35.5, 55.4, 101, 150),
        (55.5, 125.4, 151, 200), (125.5, 225.4, 201, 300), (225.5, 325.4, 301, 500)]


def aqi(c: float) -> int:
    if c <= 0:
        return 0
    for lo, hi, a, b in PM25:
        if c <= hi:
            return min(500, round((b - a) / (hi - lo) * max(c - lo, 0) + a))
    return 500


def nowcast(recent_first: list[float | None]) -> float | None:
    """`recent_first[0]` is the latest hour. Needs two of the latest three hours."""
    w12 = recent_first[:12]
    if sum(c is not None for c in w12[:3]) < 2:
        return None
    valid = [max(c, 0.0) for c in w12 if c is not None]
    hi, lo = max(valid), min(valid)
    w = max(lo / hi, 0.5) if hi > 0 else 1.0
    num = sum(w**i * max(c, 0.0) for i, c in enumerate(w12) if c is not None)
    den = sum(w**i for i, c in enumerate(w12) if c is not None)
    return math.floor(num / den * 10 + 1e-9) / 10


def series(pm25: list[float | None]) -> list[float | None]:
    return [nowcast(pm25[: i + 1][::-1]) for i in range(len(pm25))]
