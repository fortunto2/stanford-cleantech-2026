"""The explainer: schematic segments, Kling shots as b-roll, the phone video, the site's map and record,
a data card for the model, with full-sentence captions on every shot and Rustam's own ambient track.

    uv run --with pillow python pitch/video/explainer.py     # writes pitch/video/crew-air-explainer.mp4

Site screens come from Playwright at zoom 1.8, dark scheme (pitch/video/build/site-*.png).
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
PHONE = D / "WhatsApp Video 2026-10-24 at 16.35.50.mp4"  # AR horizon at Stanford, fire 21 km E, then the Plan tab
MUSIC = Path.home() / "Music" / "!AudioStable" / "ambient.mp3"
FONT = "/System/Library/Fonts/HelveticaNeue.ttc"
W, H, FPS = 1920, 1080, 30
BAND = 180  # caption band height
INK, PAPER, MUTED, ACCENT = (18, 24, 38), (251, 247, 242), (201, 191, 180), (232, 85, 28)
GREEN, AMBER = (46, 158, 91), (251, 227, 161)


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(FONT, size, index=1 if bold else 0)


def band(i: int, line1: str, line2: str) -> Path:
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rectangle([0, H - BAND, W, H], fill=(13, 18, 32, 255))
    d.rectangle([0, H - BAND, 14, H], fill=ACCENT + (255,))
    d.text((90, H - 150), line1, font=font(44, True), fill=PAPER + (255,))
    d.text((90, H - 82), line2, font=font(30), fill=MUTED + (255,))
    p = BUILD / f"ex_band_{i:02d}.png"
    im.save(p)
    return p


def centred(name: str, parts: list[Image.Image], gap: int = 24, pad: int = 40) -> Path:
    """Stack the images vertically, scaled to fill the frame above the caption band, centred."""
    area_h = H - BAND - 2 * pad
    total_h = sum(p.height for p in parts) + gap * (len(parts) - 1)
    k = min((W - 2 * pad) / max(p.width for p in parts), area_h / total_h)
    parts = [p.resize((int(p.width * k), int(p.height * k)), Image.LANCZOS) for p in parts]
    total_h = sum(p.height for p in parts) + gap * (len(parts) - 1)
    full = Image.new("RGB", (W, H), INK)
    y = pad + (area_h - total_h) // 2
    for p in parts:
        full.paste(p, ((W - p.width) // 2, y))
        y += p.height + gap
    out = BUILD / f"ex_{name}.png"
    full.save(out)
    return out


def still_site() -> Path:
    return centred("site", [Image.open(BUILD / "site-hours.png").convert("RGB"), Image.open(BUILD / "site-map.png").convert("RGB")])


def still_record() -> Path:
    return centred("record", [Image.open(BUILD / "site-record.png").convert("RGB")])


def still_sheet() -> Path:
    """The printed sheet's bottom: the determination, the briefing line and the sign-off table."""
    src = Image.open(BUILD / "print-sheet.png").convert("RGB")
    return centred("sheet", [src.crop((0, 1225, src.width, src.height))])


def still_model() -> Path:
    """What the model takes today and what the pilot adds. Every line is a live source or a named next step."""
    full = Image.new("RGB", (W, H), INK)
    d = ImageDraw.Draw(full)
    d.text((120, 60), "THE MODEL", font=font(26), fill=MUTED)
    d.text((120, 100), "What it takes today", font=font(44, True), fill=PAPER)
    d.text((1000, 100), "What the pilot adds", font=font(44, True), fill=AMBER)
    now = [
        ("Open-Meteo PM2.5 forecast", "24-h mean, recomputed to the EPA NowCast"),
        ("AirNow monitor", "nearest regulatory PM2.5, hourly, 48 km at the test site"),
        ("NASA VIIRS fires", "last 24 h, within 50 km, bearing and distance"),
        ("NWS hourly wind and temperature", "the plume cone per hour; the heat rule"),
        ("NWS alerts", "Red Flag, Heat Advisory, Air Quality Alert"),
        ("Cal/OSHA rulebook as data", "§5141.1 smoke, §3395 heat, EPA breakpoints"),
        ("Crew reports and sky photos", "vision check, 11 of 12 smoke calls right"),
    ]
    nxt = [
        ("Fixed PM2.5 nodes on the poles", "every 15 min through POST /api/crew/report"),
        ("Drone samples at the break", "the Appendix A reading the record needs"),
        ("HRRR-Smoke", "NOAA, 3 km cells hourly, instead of 40 km"),
        ("Terrain", "canyons channel smoke; the cone does not know that"),
        ("Site readings vs forecast", "a correction model trained per site, from the pilot"),
        ("The utility's outage feed", "which span, which crew, which hour"),
    ]
    for items, x, colour in ((now, 120, GREEN), (nxt, 1000, AMBER)):
        y = 180
        for title, sub in items:
            d.ellipse([x, y + 14, x + 16, y + 30], fill=colour)
            d.text((x + 36, y), title, font=font(32, True), fill=PAPER)
            d.text((x + 36, y + 42), sub, font=font(24), fill=MUTED)
            y += 98
    p = BUILD / "ex_model.png"
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
    ("still", "site", 0, 7, "The site: the AQI and heat by the hour, and where the smoke goes.", "Red: VIIRS fires. Green: the AirNow monitor. Orange: three hours of wind downwind of each fire."),
    ("still", "model", 0, 8, "The model: what it takes today, and what the pilot adds.", "Public data now; nodes, drone samples, HRRR-Smoke and site readings next."),
    ("phone", PHONE, 0.5, 9, "The crew’s phone: the fire on the horizon, 21 km east, then the shift plan.", "Filmed at Stanford today. Plan, sky check and report; English and Spanish."),
    ("still", "record", 0, 6, "The sensor task and how the AQI was determined.", "The bearing to the fire, the instrument line (Appendix A), the rule: §5141.1(c)."),
    ("still", "sheet", 0, 7, "The printed record, filled in and signed at the briefing.", "How the AQI was determined, the instrument, the rule, the sign-off: what an inspector asks for."),
    ("story", STORY, 27, 5.5, None, None),
    ("clip", D / "kling_20261025_VIDEO_giant_weat_1950_0.mp4", 0, 5, "The crew goes in at 10:40, not 14:00.", "The same JSON goes to the utility’s dispatch, the DERMS and the home panel."),
    ("story", STORY, 32.5, 3, None, None),
]


def main() -> None:
    stills = {"site": still_site(), "record": still_record(), "sheet": still_sheet(), "model": still_model()}
    inputs: list[str] = []
    chains: list[str] = []
    n = 0
    for i, (kind, src, start, dur, c1, c2) in enumerate(SEQ):
        if kind == "phone":
            # the portrait video centred and as tall as the area above the caption, on the dark paper
            inputs += ["-ss", f"{start:.3f}", "-t", f"{dur + 0.2:.3f}", "-i", str(src)]
            ph = H - BAND - 40
            base = (f"color=c=0x121826:s={W}x{H}:r={FPS}:d={dur:.3f}[bg{i}];"
                    f"[{n}:v]trim=0:{dur:.3f},setpts=PTS-STARTPTS,fps={FPS},scale=-2:{ph}[ph{i}];"
                    f"[bg{i}][ph{i}]overlay=(W-w)/2:20:shortest=1")
        elif kind == "still":
            inputs += ["-loop", "1", "-t", f"{dur + 0.2:.3f}", "-i", str(stills[src])]
            base = f"[{n}:v]fps={FPS},trim=0:{dur:.3f},setpts=PTS-STARTPTS,scale={W}:{H},setsar=1"
        else:
            inputs += ["-ss", f"{start:.3f}", "-t", f"{dur + 0.2:.3f}", "-i", str(src)]
            base = f"[{n}:v]trim=0:{dur:.3f},setpts=PTS-STARTPTS,fps={FPS},scale={W}:{H},setsar=1"
        n += 1
        if c1:
            inputs += ["-loop", "1", "-t", f"{dur + 0.2:.3f}", "-i", str(band(i, c1, c2))]
            chains.append(f"{base}[b{i}]")
            chains.append(f"[b{i}][{n}:v]overlay=0:0:shortest=1,setsar=1,format=yuv420p[v{i}]")
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
