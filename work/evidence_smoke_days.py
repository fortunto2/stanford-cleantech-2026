"""Ag worker-days in California at PM2.5 AQI >= 151 in fire season, from public data. No keys.

EPA AirData daily AQI by county (Defining Parameter PM2.5, June-October only, so winter inversion
smoke in the valley is left out) times BLS QCEW private NAICS 11 annual average employment per
county, times 5/7 working days. A lower bound twice over: the daily mean hides hours above 151 that
the rule counts, and QCEW misses uncovered farm work.

    uv run python work/evidence_smoke_days.py   # downloads ~10 MB into work/output/evidence/
"""

import collections
import csv
import io
import urllib.request
import zipfile
from pathlib import Path

OUT = Path(__file__).parent / "output" / "evidence"
YEARS = range(2020, 2026)


def fetch(url: str, name: str) -> Path:
    p = OUT / name
    if not p.exists():
        OUT.mkdir(parents=True, exist_ok=True)
        urllib.request.urlretrieve(url, p)
    return p


def ag_employment(year: int) -> dict[str, int]:
    p = fetch(f"https://data.bls.gov/cew/data/api/{year}/a/industry/11.csv", f"qcew_11_{year}.csv")
    return {r["area_fips"]: int(r["annual_avg_emplvl"] or 0) for r in csv.DictReader(p.open())
            if r["area_fips"].startswith("06") and r["own_code"] == "5" and r["agglvl_code"] == "74"}


def smoke_days(year: int) -> collections.Counter:
    p = fetch(f"https://aqs.epa.gov/aqsweb/airdata/daily_aqi_by_county_{year}.zip", f"aqi_{year}.zip")
    z = zipfile.ZipFile(p)
    days: collections.Counter = collections.Counter()
    for r in csv.DictReader(io.TextIOWrapper(z.open(z.namelist()[0]))):
        if (r["State Name"] == "California" and r["Defining Parameter"] == "PM2.5"
                and 6 <= int(r["Date"][5:7]) <= 10 and int(r["AQI"]) >= 151):
            days["06" + r["County Code"].zfill(3)] += 1
    return days


def main() -> None:
    latest = 2024  # newest full QCEW year
    for y in YEARS:
        emp, days = ag_employment(min(y, latest)), smoke_days(y)
        wd = sum(n * emp.get(c, 0) for c, n in days.items()) * 5 / 7
        print(f"{y}: {sum(days.values()):4d} county-days >= 151 · {wd:>12,.0f} ag worker-days")


if __name__ == "__main__":
    main()
