"""Shared colour and terminal-palette helpers for the theme pipeline.

The Nix build (palette.py) needs HSV/HLS mixing and one idea of a terminal
palette, so they live here instead of being copied into the generator.
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
