"""Known-answer check for /api/sky-check (Jev on a photo of the sky).

Photos are public domain (US government works on Wikimedia Commons), labelled by what their title
says: `smoke` or `clear`. An instrument we have not seen get things right AND wrong proves nothing,
so this prints every answer, not just a score.

    uv run python work/sky_eval.py [https://airsignal.app]
"""

import json
import sys
import urllib.request
from pathlib import Path

BASE = sys.argv[1] if len(sys.argv) > 1 else "https://airsignal.app"
HERE = Path(__file__).parent
OUT = HERE / "output" / "sky"
UA = {"User-Agent": "CrewAir-eval/0.1 (info@superduperai.co)"}


def fetch(url: str, path: Path) -> bytes:
    if not path.exists():
        OUT.mkdir(parents=True, exist_ok=True)
        with urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=60) as r:
            path.write_bytes(r.read())
    return path.read_bytes()


def check(jpeg: bytes) -> dict:
    req = urllib.request.Request(f"{BASE}/api/sky-check", data=jpeg, method="POST",
                                 headers={**UA, "content-type": "image/jpeg"})
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.load(r)


def main() -> None:
    rows = [line.split("\t") for line in (HERE / "sky_eval_photos.tsv").read_text().splitlines() if line]
    right = 0
    for i, (label, url) in enumerate(rows, 1):
        d = check(fetch(url, OUT / f"{label}_{i}.jpg"))
        call = d["smoke_call"]
        ok = (label == "smoke") == (call == "yes") and call != "unsure"
        right += ok
        vis = d["visibility"] or {}
        print(f"{'✓' if ok else '✗'} {label:5} smoke={d['smoke']:.2f} call={call:6} sky={d['sky_visible']!s:5} "
              f"vis={vis.get('label')} ({vis.get('confidence')}) {d['source']['ms']}ms")
    print(f"\n{right}/{len(rows)} right on the smoke call")


if __name__ == "__main__":
    main()
