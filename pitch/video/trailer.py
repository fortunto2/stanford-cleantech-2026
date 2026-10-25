"""The 30-second trailer: fire, the wait, the reading, the phone, the record, cut on the bars of the track
(beat_dump JSON), a few words per shot, the live product at the end.

    uv run --with pillow python pitch/video/trailer.py       # writes pitch/video/crew-air-trailer.mp4
"""

from __future__ import annotations

import json
import subprocess
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
D = Path.home() / "Downloads"
V = ROOT / "pitch" / "video"
BUILD = V / "build"
MUSIC = Path("/Users/rustam/Music/DJ/Favourites/LINKIN PARK - Lost.mp3")
DB = json.load(open("/tmp/claude-501/beats_lost.json"))["downbeats"]  # bars of 2.3 s
FONT = "/System/Library/Fonts/HelveticaNeue.ttc"
W, H, FPS = 1920, 1080, 30

K = {
    "fire": D / "kling_20261025_VIDEO_Aerial_dro_1895_0.mp4",
    "aerial2": D / "kling_20261025_VIDEO_Aerial_dro_1899_0.mp4",
    "crew": D / "kling_20261025_VIDEO_Utility_li_1889_0.mp4",
    "dispatch": D / "kling_20261025_VIDEO_A_utility__1894_0.mp4",
    "sat": D / "kling_20261025_VIDEO_A_weather__1896_0.mp4",
    "drone": D / "kling_20261025_VIDEO_A_small_in_1941_0.mp4",
    "lineman": D / "kling_20261025_VIDEO_A_lineman__1909_0.mp4",
    "lights": D / "kling_20261025_VIDEO_Power_line_1912_0.mp4",
    "phone": D / "WhatsApp Video 2026-10-24 at 16.35.50.mp4",  # portrait, AR at 1 s, the Plan tab at 7.5 s
    "hero": ROOT / "pitch" / "hero.jpg",
}

# (clip, source offset s, bars, line). 13 bars = 29.9 s.
SHOTS = [
    ("fire", 0.0, 2, "A FIRE"),
    ("aerial2", 0.0, 1, "A LINE DOWN"),
    ("crew", 0.0, 1, "THE CREW WAITS"),
    ("dispatch", 0.0, 1, "THE MONITOR IS 48 KM AWAY"),
    ("sat", 0.0, 1, "A SATELLITE SEES THE FIRE"),
    ("drone", 0.0, 1, "A DRONE READS THE AIR"),
    ("phone", 1.0, 1, "FIRE ON THE HORIZON · 21 KM"),
    ("phone", 7.5, 1, "THE SHIFT PLAN"),
    ("lineman", 0.0, 1, "A READING. A RECORD."),
    ("lights", 0.0, 1, "10:40, NOT 14:00"),
    ("hero", 0.0, 1, "CREW AIR · LIVE TODAY"),
    ("end", 0.0, 1, ""),
]


def word_png(i: int, word: str) -> Path:
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    size = 150 if len(word) <= 12 else 110 if len(word) <= 22 else 90
    f = ImageFont.truetype(FONT, size, index=1)
    d.rectangle([0, H - 250, W, H], fill=(18, 24, 38, 140))
    d.rectangle([96, H - 220, 112, H - 30], fill=(232, 85, 28, 255))
    d.text((144, H - 125), word, font=f, fill=(251, 247, 242, 255), anchor="lm")
    p = BUILD / f"tr_word_{i:02d}.png"
    im.save(p)
    return p


def end_png() -> Path:
    im = Image.new("RGBA", (W, H), (18, 24, 38, 255))
    d = ImageDraw.Draw(im)
    f1 = ImageFont.truetype(FONT, 120, index=1); f2 = ImageFont.truetype(FONT, 44); f3 = ImageFont.truetype(FONT, 34)
    for y, f, t, c in ((H / 2 - 150, f1, "airsignal.app/crew", (251, 247, 242, 255)),
                       (H / 2 + 10, f2, "Live now: the site, the API and the iOS app", (251, 227, 161, 255)),
                       (H / 2 + 90, f3, "Rustam Salavatov · Asher Popper · Stanford Cleantech Hackathon 2026", (201, 191, 180, 255))):
        w = d.textlength(t, font=f); d.text(((W - w) / 2, y), t, font=f, fill=c)
    p = BUILD / "tr_end.png"; im.save(p); return p


def main() -> None:
    bar = 0
    inputs: list[str] = []
    chains: list[str] = []
    words: list[tuple[int, Path, float]] = []
    for i, (clip, off, bars, word) in enumerate(SHOTS):
        t0, t1 = DB[bar], DB[bar + bars]
        dur = t1 - t0
        bar += bars
        if clip == "end":
            inputs += ["-loop", "1", "-t", f"{dur:.3f}", "-i", str(end_png())]
            chains.append(f"[{i}:v]fps={FPS},trim=0:{dur:.3f},setpts=PTS-STARTPTS,fade=t=out:st={dur-1.0:.3f}:d=1.0,setsar=1,format=yuv420p[v{i}]")
            continue
        if clip == "hero":
            inputs += ["-loop", "1", "-t", f"{dur:.3f}", "-i", str(K[clip])]
            base = f"[{i}:v]scale=2016:1344,zoompan=z='min(1+0.0012*on,1.08)':d={int(dur*FPS)}:x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':s={W}x{H}:fps={FPS},trim=0:{dur:.3f},setpts=PTS-STARTPTS,setsar=1"
        elif clip == "phone":
            # the portrait video centred over a blurred, darkened copy of itself
            inputs += ["-ss", f"{off:.3f}", "-t", f"{dur + 0.2:.3f}", "-i", str(K[clip])]
            base = (f"[{i}:v]trim=0:{dur:.3f},setpts=PTS-STARTPTS,fps={FPS},split[pa{i}][pb{i}];"
                    f"[pa{i}]scale={W}:{H}:force_original_aspect_ratio=increase,crop={W}:{H},gblur=sigma=40,eq=brightness=-0.25[bg{i}];"
                    f"[pb{i}]scale=-2:{H}[fg{i}];[bg{i}][fg{i}]overlay=(W-w)/2:0,setsar=1")
        else:
            inputs += ["-ss", f"{off:.3f}", "-t", f"{dur + 0.2:.3f}", "-i", str(K[clip])]
            base = f"[{i}:v]trim=0:{dur:.3f},setpts=PTS-STARTPTS,fps={FPS},scale={W}:{H},eq=contrast=1.08:saturation=0.9:gamma=0.98,setsar=1"
        if word:
            words.append((i, word_png(i, word), dur))
            chains.append(f"{base}[c{i}]")
        else:
            chains.append(f"{base},format=yuv420p[v{i}]")
    total = DB[bar] - DB[0]
    n = len(SHOTS)
    for k, (i, png, d) in enumerate(words):
        inputs += ["-loop", "1", "-t", f"{d + 0.2:.3f}", "-i", str(png)]
        chains.append(f"[c{i}][{n + k}:v]overlay=0:0:shortest=1,format=yuv420p[v{i}]")
    music_idx = n + len(words)
    concat = "".join(f"[v{i}]" for i in range(n)) + f"concat=n={n}:v=1:a=0[vout]"
    audio = f"[{music_idx}:a]atrim={DB[0]:.3f}:{DB[0]+total:.3f},asetpts=PTS-STARTPTS,afade=t=out:st={total-2.0:.3f}:d=2.0,volume=0.9[aout]"
    script = BUILD / "trailer_filter.txt"
    script.write_text(";\n".join(chains + [concat, audio]))
    out = V / "crew-air-trailer.mp4"
    cmd = ["ffmpeg", "-y", "-loglevel", "error", *inputs, "-i", str(MUSIC), "-/filter_complex", str(script),
           "-map", "[vout]", "-map", "[aout]", "-c:v", "libx264", "-crf", "20", "-preset", "medium", "-c:a", "aac", "-b:a", "192k", "-shortest", str(out)]
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode:
        print(r.stderr[-2000:])
        raise SystemExit(r.returncode)
    print(out, f"{total:.1f} s, {n} shots")


if __name__ == "__main__":
    main()
