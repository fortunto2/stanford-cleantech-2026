"""Build the 2-minute Devpost video from live screenshots: caption cards with PIL, motion and music with ffmpeg.

    uv run python pitch/video/build.py            # writes pitch/video/crew-air.mp4

Frames come from pitch/video/frames (Playwright, 1920x1080) and pitch/shots (the app). The music is
Rustam's own track (~/Music/!AudioStable/ambient.mp3), so the video can be public.
"""

from __future__ import annotations

import subprocess
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
V = ROOT / "pitch" / "video"
FRAMES = V / "frames"
OUT = V / "build"
OUT.mkdir(exist_ok=True)
W, H = 1920, 1080
INK = (18, 24, 38)
PAPER = (251, 247, 242)
ACCENT = (232, 85, 28)
FONT = "/System/Library/Fonts/HelveticaNeue.ttc"
MUSIC = Path.home() / "Music" / "!AudioStable" / "ambient.mp3"


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(FONT, size, index=1 if bold else 0)


def caption(src: Path, text: str, dst: Path) -> None:
    """A screenshot with a dark caption band at the bottom."""
    im = Image.open(src).convert("RGB").resize((W, H))
    band = Image.new("RGB", (W, 150), INK)
    im.paste(band, (0, H - 150))
    d = ImageDraw.Draw(im)
    d.rectangle([0, H - 150, 14, H], fill=ACCENT)
    d.text((48, H - 112), text, font=font(40), fill=PAPER)
    im.save(dst)


def card(lines: list[tuple[str, int, bool, tuple[int, int, int]]], dst: Path, bg=INK, top=300) -> None:
    im = Image.new("RGB", (W, H), bg)
    d = ImageDraw.Draw(im)
    y = top
    for text, size, bold, color in lines:
        d.text((128, y), text, font=font(size, bold), fill=color)
        y += int(size * 1.35)
    im.save(dst)


def phones(dst: Path) -> None:
    """Four app screens side by side on the dark paper."""
    im = Image.new("RGB", (W, H), INK)
    shots = ["small-app-plan.png", "small-app-sky.png", "small-app-report.png", "small-app-lead.png"]
    labels = ["Plan", "Check the sky", "Report", "Crew lead"]
    ph = 760
    pw = int(ph * 552 / 1200)
    gap = (W - 4 * pw) // 5
    d = ImageDraw.Draw(im)
    for i, (s, label) in enumerate(zip(shots, labels)):
        p = Image.open(ROOT / "pitch" / "shots" / s).convert("RGB").resize((pw, ph))
        x = gap + i * (pw + gap)
        im.paste(p, (x, 90))
        d.text((x, 90 + ph + 16), label, font=font(30, True), fill=PAPER)
    d.text((48, H - 112), "In the crew’s pocket: the plan, a sky check by a vision model, reports with no name, the crew lead’s board.", font=font(36), fill=PAPER)
    d.rectangle([0, H - 150, 14, H], fill=ACCENT)
    im.save(dst)


def main() -> None:
    seq: list[tuple[Path, float]] = []

    t = OUT / "00-title.png"
    card([
        ("CREW AIR", 150, True, PAPER),
        ("The hour California’s smoke and heat rules start on a shift,", 52, False, PAPER),
        ("from the forecast, checked by satellite, a monitor and the sky.", 52, False, PAPER),
        ("", 30, False, PAPER),
        ("Stanford Cleantech Hackathon 2026 · airsignal.app/crew", 36, False, (201, 191, 180)),
    ], t)
    seq.append((t, 6))

    caps = [
        ("01-plan.png", "Place and shift in. Out: the hour each Cal/OSHA rule starts, and the clean window for heavy work."),
        ("02-hours-home.png", "AQI as the EPA NowCast, the temperature, and the 4–9 pm peak price: pre-cool a house before it, shut windows at the smoke hour."),
        ("03-map.png", "Where the smoke goes: satellite fires, the monitor the plan was checked against, a downwind cone for every hour from the wind."),
    ]
    for name, text in caps:
        dst = OUT / name
        caption(FRAMES / name, text, dst)
        seq.append((dst, 10))

    ph = OUT / "04-phones.png"
    phones(ph)
    seq.append((ph, 11))

    caps2 = [
        ("04-grid.png", "For a utility: thirteen SVCE communities on one map, the fires around them, which city is downwind."),
        ("05-grid-table.png", "City by city: peak AQI, °F, nearest fire, wind, the pre-cool window, the windows-shut hour, a sensor task."),
        ("06-api.png", "Every endpoint on one page, no key: the same day as JSON for a building, a home agent or a sensor node."),
    ]
    for name, text in caps2:
        dst = OUT / name
        caption(FRAMES / name, text, dst)
        seq.append((dst, 9))

    e = OUT / "99-end.png"
    card([
        ("airsignal.app/crew", 72, True, PAPER),
        ("airsignal.app/crew/grid · airsignal.app/api", 44, False, PAPER),
        ("github.com/fortunto2/stanford-cleantech-2026", 44, False, PAPER),
        ("", 30, False, PAPER),
        ("Rust engine, Cloudflare Worker, SwiftUI app. Built in the hacking hours.", 36, False, (201, 191, 180)),
        ("Rustam Salavatov · Asher Popper", 36, False, (201, 191, 180)),
    ], e)
    seq.append((e, 8))

    # One clip per card with a slow push-in, then crossfades, then the music.
    fps = 30
    clips: list[Path] = []
    for i, (png, dur) in enumerate(seq):
        clip = OUT / f"clip{i:02d}.mp4"
        frames = int(dur * fps)
        zoom = f"zoompan=z='min(1+0.0004*on,1.08)':d={frames}:x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':s={W}x{H}:fps={fps}"
        subprocess.run([
            "ffmpeg", "-y", "-loglevel", "error", "-loop", "1", "-i", str(png), "-vf", zoom, "-t", str(dur),
            "-c:v", "libx264", "-pix_fmt", "yuv420p", "-r", str(fps), str(clip),
        ], check=True)
        clips.append(clip)

    # xfade chain
    args: list[str] = ["ffmpeg", "-y", "-loglevel", "error"]
    for c in clips:
        args += ["-i", str(c)]
    xf = 0.7
    filt = ""
    offset = 0.0
    prev = "[0:v]"
    for i in range(1, len(clips)):
        offset += seq[i - 1][1] - xf
        out = f"[v{i}]"
        filt += f"{prev}[{i}:v]xfade=transition=fade:duration={xf}:offset={offset:.2f}{out};"
        prev = out
    total = sum(d for _, d in seq) - xf * (len(clips) - 1)
    filt = filt.rstrip(";")
    silent = OUT / "silent.mp4"
    args += ["-filter_complex", filt, "-map", prev, "-c:v", "libx264", "-pix_fmt", "yuv420p", str(silent)]
    subprocess.run(args, check=True)

    final = V / "crew-air.mp4"
    subprocess.run([
        "ffmpeg", "-y", "-loglevel", "error", "-i", str(silent), "-stream_loop", "-1", "-i", str(MUSIC),
        "-filter_complex", f"[1:a]atrim=0:{total:.2f},afade=t=in:d=1.5,afade=t=out:st={total - 3:.2f}:d=3,volume=0.8[a]",
        "-map", "0:v", "-map", "[a]", "-c:v", "copy", "-c:a", "aac", "-b:a", "160k", "-shortest", str(final),
    ], check=True)
    print(final, f"{total:.1f} s")


if __name__ == "__main__":
    main()
