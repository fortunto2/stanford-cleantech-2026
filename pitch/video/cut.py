"""Beat-synced pitch cut from the Kling clips: cuts land on the bars of the track (beat_dump JSON), one or
two words per shot, music under it, fade at the end. `render()` is shared with trailer.py.

    uv run --with pillow python pitch/video/cut.py            # writes pitch/video/crew-air-cut.mp4
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw

from style import BUILD, D, DOWNBEATS as DB, FPS, H, MUTED, PAPER, ROCK, ROOT, V, W, ffmpeg, font

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
    "phone": D / "WhatsApp Video 2026-10-24 at 16.35.50.mp4",  # portrait: AR at 1 s, the Plan tab at 7.5 s
    "hero": ROOT / "pitch" / "hero.jpg",
}

# (clip, source offset s, bars, word). Each shot runs from DB[bar] to DB[bar + bars].
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
CREDITS = "Rustam Salavatov · Asher Popper · Stanford Cleantech Hackathon 2026"


def word_png(name: str, i: int, word: str) -> Path:
    """The lower-third band with the word, as a transparent PNG to overlay; long lines get a smaller size."""
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    size = 150 if len(word) <= 12 else 110 if len(word) <= 22 else 90
    d.rectangle([0, H - 250, W, H], fill=(18, 24, 38, 140))
    d.rectangle([96, H - 220, 112, H - 30], fill=(232, 85, 28, 255))
    d.text((144, H - 125), word, font=font(size, True), fill=PAPER + (255,), anchor="lm")
    p = BUILD / f"{name}_word_{i:02d}.png"
    im.save(p)
    return p


def end_png(name: str, lines: list[tuple[int, bool, str, tuple[int, int, int]]]) -> Path:
    """A dark end card: (size, bold, text, colour) lines centred from just above the middle."""
    im = Image.new("RGBA", (W, H), (18, 24, 38, 255))
    d = ImageDraw.Draw(im)
    y = H / 2 - 150
    for size, bold, text, colour in lines:
        f = font(size, bold)
        d.text(((W - d.textlength(text, font=f)) / 2, y), text, font=f, fill=colour + (255,))
        y += size * 1.35
    p = BUILD / f"{name}_end.png"
    im.save(p)
    return p


def render(name: str, shots: list, end_lines: list, fade: float, zoom: tuple[float, float]) -> None:
    """One input per shot, a word overlay per shot, cuts on the bars, the track from bar 0."""
    bar = 0
    inputs: list[str] = []
    chains: list[str] = []
    words: list[tuple[int, Path, float]] = []
    for i, (clip, off, bars, word) in enumerate(shots):
        dur = DB[bar + bars] - DB[bar]
        bar += bars
        if clip == "end":
            inputs += ["-loop", "1", "-t", f"{dur:.3f}", "-i", str(end_png(name, end_lines))]
            chains.append(f"[{i}:v]fps={FPS},trim=0:{dur:.3f},setpts=PTS-STARTPTS,fade=t=out:st={dur - fade:.3f}:d={fade},setsar=1,format=yuv420p[v{i}]")
            continue
        if clip == "hero":
            inputs += ["-loop", "1", "-t", f"{dur:.3f}", "-i", str(K[clip])]
            base = (f"[{i}:v]scale=2016:1344,zoompan=z='min(1+{zoom[0]}*on,{zoom[1]})':d={int(dur * FPS)}"
                    f":x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':s={W}x{H}:fps={FPS},trim=0:{dur:.3f},setpts=PTS-STARTPTS,setsar=1")
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
            words.append((i, word_png(name, i, word), dur))
            chains.append(f"{base}[c{i}]")
        else:
            chains.append(f"{base},format=yuv420p[v{i}]")
    total = DB[bar] - DB[0]
    n = len(shots)
    # word overlays come after the shot inputs
    for k, (i, png, d) in enumerate(words):
        inputs += ["-loop", "1", "-t", f"{d + 0.2:.3f}", "-i", str(png)]
        chains.append(f"[c{i}][{n + k}:v]overlay=0:0:shortest=1,format=yuv420p[v{i}]")
    concat = "".join(f"[v{i}]" for i in range(n)) + f"concat=n={n}:v=1:a=0[vout]"
    # The music starts at the first downbeat so bar 0 of the cut is bar 0 of the track.
    audio = f"[{n + len(words)}:a]atrim={DB[0]:.3f}:{DB[0] + total:.3f},asetpts=PTS-STARTPTS,afade=t=out:st={total - 2 * fade:.3f}:d={2 * fade},volume=0.9[aout]"
    script = BUILD / f"{name}_filter.txt"
    script.write_text(";\n".join(chains + [concat, audio]))
    out = V / f"crew-air-{name}.mp4"
    ffmpeg(*inputs, "-i", str(ROCK), "-/filter_complex", str(script), "-map", "[vout]", "-map", "[aout]",
           "-c:v", "libx264", "-crf", "20", "-preset", "medium", "-c:a", "aac", "-b:a", "192k", "-shortest", str(out))
    print(out, f"{total:.1f} s, {n} shots")


if __name__ == "__main__":
    render("cut", SHOTS, [(110, True, "airsignal.app/crew", PAPER), (40, False, CREDITS, MUTED)], fade=1.2, zoom=(0.0006, 1.06))
