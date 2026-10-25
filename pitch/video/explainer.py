"""The explainer: schematic segments, two Kling shots as b-roll, the app and the printed record, with
full-sentence captions on every shot and Rustam's own ambient track.

    uv run --with pillow python pitch/video/explainer.py     # writes pitch/video/crew-air-explainer.mp4
"""

from __future__ import annotations

import subprocess
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
D = Path.home() / "Downloads"
V = ROOT / "pitch" / "video"
BUILD = V / "build"
STORY = V / "crew-air-story-silent.mp4"
MUSIC = Path.home() / "Music" / "!AudioStable" / "ambient.mp3"
FONT = "/System/Library/Fonts/HelveticaNeue.ttc"
W, H, FPS = 1920, 1080, 30
INK, PAPER, MUTED, ACCENT = (18, 24, 38), (251, 247, 242), (201, 191, 180), (232, 85, 28)


def band(i: int, line1: str, line2: str) -> Path:
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rectangle([0, H - 180, W, H], fill=(13, 18, 32, 255))
    d.rectangle([0, H - 180, 14, H], fill=ACCENT + (255,))
    d.text((90, H - 150), line1, font=ImageFont.truetype(FONT, 44, index=1), fill=PAPER + (255,))
    d.text((90, H - 82), line2, font=ImageFont.truetype(FONT, 30), fill=MUTED + (255,))
    p = BUILD / f"ex_band_{i:02d}.png"
    im.save(p)
    return p


def still_app() -> Path:
    """The app's Plan tab beside the site's record block, on the dark paper."""
    im = Image.new("RGB", (W, H - 180), INK)
    phone = Image.open(ROOT / "pitch/shots/v2-plan-sensor-task.png").convert("RGB")
    ph = 820
    pw = int(ph * phone.width / phone.height)
    im.paste(phone.resize((pw, ph)), (120, 40))
    rec = Image.open(ROOT / ".playwright-mcp/crew-record.png").convert("RGB")
    rw = 1280
    rec = rec.resize((rw, int(rw * rec.height / rec.width)))
    im.paste(rec, (120 + pw + 60, 60))
    d = ImageDraw.Draw(im)
    f = ImageFont.truetype(FONT, 28, index=1)
    d.text((120, 40 + ph + 12), "iOS: Plan tab, sensor task with the fire’s bearing", font=f, fill=PAPER)
    d.text((120 + pw + 60, 60 + rec.height + 12), "airsignal.app/crew: the sensor task and how the AQI was determined", font=f, fill=PAPER)
    full = Image.new("RGB", (W, H), INK)
    full.paste(im, (0, 0))
    p = BUILD / "ex_app.png"
    full.save(p)
    return p


def still_sheet() -> Path:
    """The printed sheet's bottom: the determination, the briefing line and the sign-off table."""
    src = Image.open(BUILD / "print-sheet.png").convert("RGB")
    crop = src.crop((0, 1225, src.width, src.height))
    sw = W - 160
    crop = crop.resize((sw, int(sw * crop.height / crop.width)))
    full = Image.new("RGB", (W, H), PAPER)
    full.paste(crop, (80, 60))
    d = ImageDraw.Draw(full)
    d.rectangle([80, 60, 80 + sw, 60 + crop.height], outline=(201, 191, 180), width=2)
    p = BUILD / "ex_sheet.png"
    full.save(p)
    return p


# (kind, source, start, duration, caption line 1, caption line 2)
SEQ = [
    ("clip", D / "kling_20261025_VIDEO_Aerial_dro_1895_0.mp4", 0, 6, "A wildfire takes down a power line.", "Cal/OSHA §5141.1: the crew’s air must be determined and logged before they go in."),
    ("story", STORY, 4, 4.3, None, None),
    ("story", STORY, 8, 4.5, None, None),
    ("clip", D / "kling_20261025_VIDEO_Small_weat_1900_0.mp4", 0, 4.5, "A sensor network: PM2.5 nodes on the poles, every 15 minutes.", "Each node reports through the same API the crew uses: POST /api/crew/report."),
    ("story", STORY, 12.5, 4.5, None, None),
    ("clip", D / "kling_20261025_VIDEO_A_small_in_1941_0.mp4", 0, 4.5, "Where there is no node, a drone takes the reading at the break.", "Outside the fire’s flight restriction; the payload is a concept, the API side is live."),
    ("story", STORY, 17, 5, None, None),
    ("story", STORY, 22, 5, None, None),
    ("still", "app", 0, 6, "The app and the site show the task and the reading.", "Sensor task with the fire’s bearing; how the AQI was determined, the instrument, the rule."),
    ("still", "sheet", 0, 7, "The printed record, filled in and signed at the briefing.", "How the AQI was determined, the instrument line (Appendix A), the rule, the sign-off: what an inspector asks for."),
    ("story", STORY, 27, 5.5, None, None),
    ("clip", D / "kling_20261025_VIDEO_giant_weat_1950_0.mp4", 0, 5, "The crew goes in at 10:40, not 14:00.", "The same JSON goes to the utility’s dispatch, the DERMS and the home panel."),
    ("story", STORY, 32.5, 3, None, None),
]


def main() -> None:
    stills = {"app": still_app(), "sheet": still_sheet()}
    inputs: list[str] = []
    chains: list[str] = []
    n = 0
    for i, (kind, src, start, dur, c1, c2) in enumerate(SEQ):
        if kind == "still":
            inputs += ["-loop", "1", "-t", f"{dur + 0.2:.3f}", "-i", str(stills[src])]
            base = f"[{n}:v]fps={FPS},trim=0:{dur:.3f},setpts=PTS-STARTPTS,scale={W}:{H},setsar=1"
        else:
            inputs += ["-ss", f"{start:.3f}", "-t", f"{dur + 0.2:.3f}", "-i", str(src)]
            base = f"[{n}:v]trim=0:{dur:.3f},setpts=PTS-STARTPTS,fps={FPS},scale={W}:{H},setsar=1"
        n += 1
        if c1:
            inputs += ["-loop", "1", "-t", f"{dur + 0.2:.3f}", "-i", str(band(i, c1, c2))]
            chains.append(f"{base}[b{i}]")
            chains.append(f"[b{i}][{n}:v]overlay=0:0:shortest=1,format=yuv420p[v{i}]")
            n += 1
        else:
            chains.append(f"{base},format=yuv420p[v{i}]")
    total = sum(s[3] for s in SEQ)
    k = len(SEQ)
    concat = "".join(f"[v{i}]" for i in range(k)) + f"concat=n={k}:v=1:a=0[vout]"
    audio = f"[{n}:a]atrim=0:{total:.3f},asetpts=PTS-STARTPTS,afade=t=in:d=1,afade=t=out:st={total - 3:.3f}:d=3,volume=0.8[aout]"
    script = BUILD / "explainer_filter.txt"
    script.write_text(";\n".join(chains + [concat, audio]))
    out = V / "crew-air-explainer.mp4"
    cmd = ["ffmpeg", "-y", "-loglevel", "error", *inputs, "-stream_loop", "-1", "-i", str(MUSIC),
           "-/filter_complex", str(script), "-map", "[vout]", "-map", "[aout]",
           "-c:v", "libx264", "-crf", "20", "-preset", "medium", "-c:a", "aac", "-b:a", "160k", "-shortest", str(out)]
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode:
        print(r.stderr[-2000:])
        raise SystemExit(r.returncode)
    print(out, f"{total:.1f} s")


if __name__ == "__main__":
    main()
