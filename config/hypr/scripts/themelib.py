"""Shared colour and terminal-palette helpers for the theme pipeline.

The Nix build (quickshell-palette.py) and the runtime generator
(wallcolors.py/theme.py) both need the same HSV/HLS mixing and the same idea of
a terminal palette, so they live here instead of being copied between scripts.
"""

import colorsys
import configparser
from pathlib import Path

def rgb(value):
    value = value.strip().lstrip("#")
    return tuple(int(value[i : i + 2], 16) for i in (0, 2, 4))


def hexs(r, g, b):
    def byte(v):
        return max(0, min(255, round(v)))

    return "#%02x%02x%02x" % (byte(r), byte(g), byte(b))


def norm(value):
    return "#" + value.strip().lstrip("#").lower()


def mix(a, b, t):
    ar, ag, ab = rgb(a)
    br, bg, bb = rgb(b)
    return hexs(ar + (br - ar) * t, ag + (bg - ag) * t, ab + (bb - ab) * t)


def hls(c):
    r, g, b = rgb(c)
    return colorsys.rgb_to_hls(r / 255, g / 255, b / 255)


def from_hls(h, l, s):
    r, g, b = colorsys.hls_to_rgb(
        h % 1.0, max(0.0, min(1.0, l)), max(0.0, min(1.0, s))
    )
    return hexs(r * 255, g * 255, b * 255)


def lighten(c, t):
    return mix(c, "#ffffff", t)


def darken(c, t):
    return mix(c, "#000000", t)


def luma(c):
    def channel(v):
        v = v / 255
        return v / 12.92 if v <= 0.03928 else ((v + 0.055) / 1.055) ** 2.4

    r, g, b = rgb(c)
    return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b)


def is_light(c):
    return luma(c) > 0.45


def on(c):
    return "#000000" if luma(c) > 0.179 else "#ffffff"


def shift(c, degrees, sat=1.0, light=1.0):
    h, l, s = hls(c)
    return from_hls(h + degrees / 360.0, l * light, s * sat)


def load_registry(path):
    """The scheme registry as {name: {...}}, identity and all."""
    import json

    data = json.loads(Path(path).read_text())
    if not isinstance(data.get("schemes"), dict):
        raise SystemExit(f"{path}: no schemes object")
    for name, spec in data["schemes"].items():
        if not spec.get("identity") and "accent" not in spec:
            raise SystemExit(f"{path}: {name} has no accent")
    return data


def read_foot_theme(path):
    """A foot theme file as the pipeline's terminal bundle section.

    The include chain carries both a foreground/background and the 16 ANSI
    slots; selection and cursor are optional in upstream themes, so fall back
    to the foreground/background rather than inventing a colour.
    """
    parser = configparser.ConfigParser(interpolation=None)
    parser.read(path)
    section = next(
        (parser[s] for s in parser.sections() if s.startswith("colors")), None
    )
    if section is None:
        raise SystemExit(f"{path}: no colors section")

    def get(key, default):
        return norm(section.get(key, default))

    fg = get("foreground", "#ffffff")
    bg = get("background", "#000000")
    ansi = [
        get(f"regular{i}", fg) for i in range(8)
    ] + [
        get(f"bright{i}", fg) for i in range(8)
    ]
    cursor = section.get("cursor", "").split()
    return {
        "background": bg,
        "foreground": fg,
        "ansi": ansi,
        "cursor": norm(cursor[-1]) if cursor else fg,
        "selection_background": get("selection-background", bg),
        "selection_foreground": get("selection-foreground", fg),
        "urls": get("urls", ansi[4]),
    }


# The fixed washi identity needs a terminal palette too, or falling back to it
# leaves foot on whatever scheme was last active. The values mirror the WASHI
# roles in quickshell-palette.py; keep them in sync with it.
WASHI_TERMINAL = {
    "background": "#211711",
    "foreground": "#e6d6cb",
    "ansi": [
        "#1b120d",
        "#c0442b",
        "#8a9a5b",
        "#f5bd6f",
        "#6d8a96",
        "#a06a7a",
        "#7f9f9f",
        "#b9a99e",
        "#594636",
        "#e0563b",
        "#a7b87a",
        "#ffd9a0",
        "#8fa9b5",
        "#c08a9a",
        "#9fbfbf",
        "#fff6f0",
    ],
    "cursor": "#e0563b",
    "selection_background": "#3a2a22",
    "selection_foreground": "#e6d6cb",
    "urls": "#8fa9b5",
}
