"""Cal/OSHA citations under §5141.1 (wildfire smoke), §3395 (outdoor heat) and §3396 (indoor heat), July
2019 on, from the DOL OSHA enforcement API (Cal/OSHA is a state plan, its inspections are in it).

Standards are coded without the dot: §5141.1(e) is "51410001 E"; a bare "5141 A" is the older §5141
(harmful exposures in general) and is NOT the smoke rule. Each violation is joined to its inspection
for state, industry (NAICS) and why the inspector came (insp_type B = complaint).

    DOL_API_KEY=... uv run python work/evidence_citations.py     # key: dataportal.dol.gov/api-keys
"""

import collections
import json
import os
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

API = "https://apiprod.dol.gov/v4/get/OSHA/{table}/json"
OUT = Path(__file__).parent / "output" / "evidence"
RULES = {"smoke §5141.1": "51410001%", "heat §3395": "3395%", "indoor heat §3396": "3396%"}
SINCE = "2019-07-01"


def key() -> str:
    k = os.environ.get("DOL_API_KEY")
    if not k:
        env = Path(__file__).parent.parent / ".env"
        for line in env.read_text().splitlines() if env.exists() else []:
            if line.startswith("DOL_API_KEY="):
                k = line.split("=", 1)[1].strip()
    if not k:
        raise SystemExit("DOL_API_KEY missing")
    return k


def get(table: str, filt: dict, fields: str, limit: int = 500) -> list[dict]:
    rows, offset = [], 0
    while True:
        q = urllib.parse.urlencode({"X-API-KEY": key(), "limit": limit, "offset": offset,
                                    "filter_object": json.dumps(filt), "fields": fields})
        # The API refuses urllib's default User-Agent with a 403; curl's passes.
        req = urllib.request.Request(f"{API.format(table=table)}?{q}", headers={"User-Agent": "curl/8.7.1"})
        for attempt in range(12):
            try:
                with urllib.request.urlopen(req, timeout=180) as r:
                    page = json.load(r).get("data", [])
                break
            except urllib.error.HTTPError as e:
                # 429 when throttled; it has also answered 403 while throttled. Wait it out.
                if e.code not in (403, 429, 500, 502, 503, 504) or attempt == 11:
                    raise
                print(f"  {table}: HTTP {e.code}, waiting {15 * (attempt + 1)} s", file=sys.stderr, flush=True)
                time.sleep(15 * (attempt + 1))
        rows += page
        print(f"  {table}: {len(rows)} rows", file=sys.stderr, flush=True)
        if len(page) < limit:
            return rows
        offset += limit


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    viols = {}
    for name, pattern in RULES.items():
        viols[name] = get("violation", {"and": [
            {"field": "standard", "operator": "like", "value": pattern},
            {"field": "issuance_date", "operator": "gt", "value": SINCE}]},
            "activity_nr,citation_id,standard,issuance_date,initial_penalty,current_penalty,viol_type,delete_flag")
        viols[name] = [v for v in viols[name] if v.get("delete_flag") != "X"]

    nrs = sorted({v["activity_nr"] for vs in viols.values() for v in vs})
    insp = {}
    for i in range(0, len(nrs), 200):
        for row in get("inspection", {"field": "activity_nr", "operator": "in", "value": nrs[i:i + 200]},
                       "activity_nr,site_state,site_city,naics_code,insp_type,open_date,estab_name"):
            insp[row["activity_nr"]] = row
    (OUT / "citations.json").write_text(json.dumps({"violations": viols, "inspections": insp}, default=str))

    for name, vs in viols.items():
        ca = [v for v in vs if insp.get(v["activity_nr"], {}).get("site_state") == "CA"]
        by_year = collections.Counter(v["issuance_date"][:4] for v in ca)
        ag = [v for v in ca if str(insp[v["activity_nr"]].get("naics_code") or "").startswith("11")]
        complaint = {v["activity_nr"] for v in ca if insp[v["activity_nr"]].get("insp_type") == "B"}
        cur = sum(v["current_penalty"] or 0 for v in ca)
        print(f"\n{name}: {len(ca)} CA violations at {len({v['activity_nr'] for v in ca})} inspections"
              f" (of {len(vs)} in the data) · agriculture {len(ag)} · current penalties ${cur:,.0f}"
              f" · inspections opened by complaint {len(complaint)}")
        print("   by year:", dict(sorted(by_year.items())))


if __name__ == "__main__":
    main()
