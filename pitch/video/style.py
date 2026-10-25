"""What every video script here shares: paths, frame size, palette, fonts, music, the beat map, ffmpeg."""

from __future__ import annotations

import json
import subprocess
from pathlib import Path

from PIL import ImageFont

ROOT = Path(__file__).resolve().parents[2]
D = Path.home() / "Downloads"  # Kling clips and phone recordings land here
V = ROOT / "pitch" / "video"
BUILD = V / "build"
BUILD.mkdir(exist_ok=True)

W, H, FPS = 1920, 1080, 30
FONT = "/System/Library/Fonts/HelveticaNeue.ttc"
INK, PAPER, MUTED, ACCENT = (18, 24, 38), (251, 247, 242), (201, 191, 180), (232, 85, 28)
GREEN, AMBER = (46, 158, 91), (251, 227, 161)

AMBIENT = Path.home() / "Music" / "!AudioStable" / "ambient.mp3"  # Rustam's own track
ROCK = Path.home() / "Music" / "DJ" / "Favourites" / "LINKIN PARK - Lost.mp3"
# beat_dump (video-generator-agent) of ROCK: bpm, beats, downbeats (bars of ~2.3 s), sections
DOWNBEATS: list[float] = json.loads((V / "beats_lost.json").read_text())["downbeats"]


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(FONT, size, index=1 if bold else 0)


def ffmpeg(*args: str) -> None:
    """Run ffmpeg quietly; on failure print the tail of stderr and exit with its code."""
    r = subprocess.run(["ffmpeg", "-y", "-loglevel", "error", *args], capture_output=True, text=True)
    if r.returncode:
        print(r.stderr[-2000:])
        raise SystemExit(r.returncode)
