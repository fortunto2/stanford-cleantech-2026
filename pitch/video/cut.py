"""Beat-synced pitch cut from the Kling clips: cuts land on the bars of the track (beat_dump JSON), one or
two words per shot, music under it, fade at the end.

    uv run --with pillow python pitch/video/cut.py            # writes pitch/video/crew-air-cut.mp4
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
BUILD.mkdir(exist_ok=True)
MUSIC = Path("/Users/rustam/Music/DJ/Favourites/LINKIN PARK - Lost.mp3")
BEATS = json.load(open("/tmp/claude-501/beats_lost.json"))
DB = BEATS["downbeats"]
FONT = "/System/Library/Fonts/HelveticaNeue.ttc"
W, H, FPS = 1920, 1080, 30

K = {
    "fire": D / "kling_20261025_VIDEO_Aerial_dro_1895_0.mp4",
    "aerial2": D / "kling_20261025_VIDEO_Aerial_dro_1899_0.mp4",
    "crew": D / "kling_20261025_VIDEO_Utility_li_1889_0.mp4",
    "dispatch": D / "kling_20261025_VIDEO_A_utility__1894_0.mp4",
    "sat": D / "kling_20261025_VIDEO_A_weather__1896_0.mp4",
    "nodes": D / "kling_20261025_VIDEO_Small_weat_1900_0.mp4",
    "drone": D / "kling_20261025_VIDEO_A_small_in_1941_0.mp4",
    "lineman": D / "kling_20261025_VIDEO_A_lineman__1909_0.mp4",
    "lights": D / "kling_20261025_VIDEO_Power_line_1912_0.mp4",
    "tenforty": D / "kling_20261025_VIDEO_giant_weat_1950_0.mp4",
    "hero": ROOT / "pitch" / "hero.jpg",
}

# (clip, source offset s, bars, word). Bars are indices into the downbeat list; each shot runs from DB[i] to DB[j].
SHOTS = [
    ("fire", 0.0, 3, "FIRE"),
    ("aerial2", 0.0, 2, "A LINE DOWN"),
    ("crew", 0.0, 2, "06:00"),
    ("dispatch", 0.0, 2, "WAITING"),
    ("crew", 2.5, 2, "48 KM"),
    ("dispatch", 2.5, 1, "NO DATA"),
    ("sat", 0.0, 2, "VIIRS SEES IT"),
    ("nodes", 0.0, 1, "NODES"),
    ("nodes", 2.0, 1, "EVERY 15 MIN"),
    ("drone", 0.0, 2, "DRONE"),
    ("drone", 3.0, 1, "READING 38"),
    ("lineman", 0.0, 1, "RECORD"),
    ("lineman", 1.7, 1, "SIGNED"),
    ("tenforty", 0.0, 2, ""),
    ("lights", 0.0, 2, "LIGHTS ON"),
    ("hero", 0.0, 2, "CREW AIR"),
    ("end", 0.0, 2, ""),
]


def word_png(i: int, word: str) -> Path:
    """The lower-third band with the word, as a transparent PNG to overlay."""
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rectangle([0, H - 250, W, H], fill=(18, 24, 38, 140))
    d.rectangle([96, H - 220, 112, H - 30], fill=(232, 85, 28, 255))
    f = ImageFont.truetype(FONT, 150, index=1)
    d.text((144, H - 232), word, font=f, fill=(251, 247, 242, 255))
    p = BUILD / f"word_{i:02d}.png"
    im.save(p)
    return p


def end_png() -> Path:
    im = Image.new("RGBA", (W, H), (18, 24, 38, 255))
    d = ImageDraw.Draw(im)
    f1 = ImageFont.truetype(FONT, 110, index=1); f2 = ImageFont.truetype(FONT, 40)
    t = "airsignal.app/crew"; w = d.textlength(t, font=f1); d.text(((W - w) / 2, H / 2 - 120), t, font=f1, fill=(251, 247, 242, 255))
    t = "Rustam Salavatov · Asher Popper · Stanford Cleantech Hackathon 2026"; w = d.textlength(t, font=f2); d.text(((W - w) / 2, H / 2 + 30), t, font=f2, fill=(201, 191, 180, 255))
    p = BUILD / "end.png"; im.save(p); return p


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
            chains.append(f"[{i}:v]fps={FPS},trim=0:{dur:.3f},setpts=PTS-STARTPTS,fade=t=out:st={dur-1.2:.3f}:d=1.2,setsar=1,format=yuv420p[v{i}]")
            continue
        if clip == "hero":
            inputs += ["-loop", "1", "-t", f"{dur:.3f}", "-i", str(K[clip])]
            base = f"[{i}:v]scale=2016:1344,zoompan=z='min(1+0.0006*on,1.06)':d={int(dur*FPS)}:x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':s={W}x{H}:fps={FPS},trim=0:{dur:.3f},setpts=PTS-STARTPTS"
            chains.append(f"{base},setsar=1,format=yuv420p[v{i}]")
            continue
        inputs += ["-ss", f"{off:.3f}", "-t", f"{dur + 0.2:.3f}", "-i", str(K[clip])]
        base = f"[{i}:v]trim=0:{dur:.3f},setpts=PTS-STARTPTS,fps={FPS},scale={W}:{H},eq=contrast=1.08:saturation=0.9:gamma=0.98,setsar=1"
        if word:
            words.append((i, word_png(i, word), dur))
            chains.append(f"{base}[c{i}]")
        else:
            chains.append(f"{base},format=yuv420p[v{i}]")
    total = DB[bar] - DB[0]
    n = len(SHOTS)
    # word overlays come after the clip inputs
    for k, (i, png, d) in enumerate(words):
        inputs += ["-loop", "1", "-t", f"{d + 0.2:.3f}", "-i", str(png)]
        chains.append(f"[c{i}][{n + k}:v]overlay=0:0:shortest=1,format=yuv420p[v{i}]")
    music_idx = n + len(words)
    concat = "".join(f"[v{i}]" for i in range(n)) + f"concat=n={n}:v=1:a=0[vout]"
    # The music starts at the first downbeat so bar 0 of the cut is bar 0 of the track.
    audio = f"[{music_idx}:a]atrim={DB[0]:.3f}:{DB[0]+total:.3f},asetpts=PTS-STARTPTS,afade=t=out:st={total-2.5:.3f}:d=2.5,volume=0.9[aout]"
    script = BUILD / "cut_filter.txt"
    script.write_text(";\n".join(chains + [concat, audio]))
    out = V / "crew-air-cut.mp4"
    cmd = ["ffmpeg", "-y", "-loglevel", "error", *inputs, "-i", str(MUSIC),
           "-/filter_complex", str(script),
           "-map", "[vout]", "-map", "[aout]", "-c:v", "libx264", "-crf", "20", "-preset", "medium", "-c:a", "aac", "-b:a", "192k", "-shortest", str(out)]
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode:
        print(r.stderr[-2000:])
        raise SystemExit(r.returncode)
    print(out, f"{total:.1f} s, {n} shots")


if __name__ == "__main__":
    main()
