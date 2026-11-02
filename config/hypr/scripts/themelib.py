"""Shared colour and terminal-palette helpers for the theme pipeline.

The Nix build (quickshell-palette.py) and the runtime renderer (theme.py) both
need the same HSV/HLS mixing and the same idea of a terminal palette, so they
live here instead of being copied between scripts.
"""

import colorsys
import tomllib
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


def base(bg, fg, accent, red, light):
    """The base palette, before fixed/inverse roles are filled in."""
    if light:
        lowest = lighten(bg, 0.60)
        low = lighten(bg, 0.30)
        container = lighten(bg, 0.12)
        high = darken(bg, 0.04)
        highest = darken(bg, 0.08)
        bright = lighten(bg, 0.45)
        dim = darken(bg, 0.10)
        container_mix = 0.20
        on_mix = "#000000"
    else:
        lowest = darken(bg, 0.20)
        low = mix(bg, fg, 0.025)
        container = mix(bg, fg, 0.05)
        high = mix(bg, fg, 0.08)
        highest = mix(bg, fg, 0.12)
        bright = mix(bg, fg, 0.16)
        dim = bg
        container_mix = 0.45
        on_mix = "#ffffff"

    secondary = shift(accent, 35, 0.65)
    tertiary = shift(accent, -45, 0.75)

    p = {
        "background": bg,
        "on_background": fg,
        "surface": bg,
        "on_surface": fg,
        "surface_variant": container,
        "on_surface_variant": mix(fg, bg, 0.22),
        "surface_container_lowest": lowest,
        "surface_container_low": low,
        "surface_container": container,
        "surface_container_high": high,
        "surface_container_highest": highest,
        "surface_bright": bright,
        "surface_dim": dim,
        "surface_tint": accent,
        "outline": mix(fg, bg, 0.55),
        "outline_variant": mix(fg, bg, 0.78),
        "primary": accent,
        "on_primary": on(accent),
        "primary_container": mix(bg, accent, container_mix),
        "on_primary_container": mix(accent, on_mix, 0.55),
        "secondary": secondary,
        "on_secondary": on(secondary),
        "secondary_container": mix(bg, secondary, container_mix),
        "on_secondary_container": mix(secondary, on_mix, 0.55),
        "tertiary": tertiary,
        "on_tertiary": on(tertiary),
        "tertiary_container": mix(bg, tertiary, container_mix),
        "on_tertiary_container": mix(tertiary, on_mix, 0.55),
        "error": red,
        "on_error": on(red),
        "error_container": mix(bg, red, container_mix),
        "on_error_container": mix(red, on_mix, 0.55),
        "inverse_surface": fg,
        "inverse_on_surface": bg,
        "inverse_primary": accent,
        "scrim": "#000000",
        "shadow": "#000000",
        "source_color": accent,
        # Shell tokens Dyn.qml reads. The derived ones mirror the pill's flame
        # ramp.
        "cream": fg,
        "bright": lighten(fg, 0.35) if not light else darken(fg, 0.35),
        "subtle": mix(fg, bg, 0.22),
        "dim": mix(fg, bg, 0.42),
        "faint": mix(fg, bg, 0.58),
        "icon_dim": mix(fg, bg, 0.12),
        "tick_rest": mix(fg, bg, 0.30),
        "on_glow": lighten(accent, 0.25),
        "verm": darken(accent, 0.18),
        "verm_lit": accent,
        "verm_deep": mix(bg, accent, container_mix),
        "verm_dim": darken(accent, 0.34),
        "verm_dim_deep": darken(accent, 0.55),
        "verm_burn": darken(mix(bg, accent, container_mix), 0.10),
        "card_top": high,
        "card_bot": low,
        "border": mix(fg, bg, 0.78),
        "tile_bg": bg,
        "flame_core": lighten(accent, 0.62),
        "flame_glow": lighten(accent, 0.25),
        "flame_ink": accent,
        "flame_ember": mix(bg, accent, container_mix),
        "flame_burn": mix(bg, accent, container_mix),
        "flame_tip": mix(accent, on_mix, 0.55),
        "today_warm": lighten(accent, 0.45),
        "ghost": highest,
    }
    return p


def finalize(p):
    """Fixed roles are tints of whatever primary/secondary/tertiary ended up as."""
    for role in ("primary", "secondary", "tertiary"):
        c = p[role]
        p[f"{role}_fixed"] = c
        p[f"{role}_fixed_dim"] = mix(c, p["background"], 0.20)
        p[f"on_{role}_fixed"] = on(c)
        p[f"on_{role}_fixed_variant"] = mix(c, p["background"], 0.45)
    return p


def theme_bundle(colors, key, source, scheme, tone, editor="generated"):
    """A full shell bundle from a terminal-shaped palette."""
    bg, fg = colors["background"], colors["foreground"]
    p = finalize(base(bg, fg, colors["accent"], colors["ansi"][1], tone == "light"))
    return {
        **p,
        "key": key,
        "source": source,
        "scheme": scheme,
        "tone": tone,
        "editor": editor,
        "terminal": {
            field: colors[field]
            for field in (
                "background",
                "foreground",
                "ansi",
                "cursor",
                "selection_background",
                "selection_foreground",
                "urls",
            )
        },
    }


def load_registry(path):
    """The scheme registry as {name: {...}}."""
    import json

    data = json.loads(Path(path).read_text())
    if not isinstance(data.get("schemes"), dict):
        raise SystemExit(f"{path}: no schemes object")
    for name, spec in data["schemes"].items():
        if not isinstance(spec, dict):
            raise SystemExit(f"{path}: {name} is not an object")
    return data


def read_colors_toml(path):
    """A canonical colors.toml as the pipeline's terminal bundle section.

    The schema is Omarchy's: background/foreground, the named ANSI roles,
    selection/muted and the bright variants. Themes carry one tone each and
    mode says which; selection_foreground is optional and falls back to the
    foreground like foot's own themes did.
    """
    data = tomllib.loads(Path(path).read_text())

    def get(key, *aliases, default=None):
        for name in (key, *aliases):
            value = data.get(name)
            if value is not None:
                return norm(value)
        if default is not None:
            return default
        raise SystemExit(f"{path}: missing {key}")

    fg = get("foreground")
    bg = get("background")
    accent = get("accent")
    ansi = [
        get("ansi0", default=bg),
        get("red"),
        get("green"),
        get("yellow"),
        get("blue"),
        get("magenta", "purple"),
        get("cyan"),
        get("ansi7", default=fg),
        get("muted"),
        get("bright_red"),
        get("bright_green"),
        get("bright_yellow"),
        get("bright_blue"),
        get("bright_magenta", "bright_purple"),
        get("bright_cyan"),
        get("bright_foreground"),
    ]
    return {
        "background": bg,
        "foreground": fg,
        "ansi": ansi,
        "cursor": get("cursor", default=accent),
        "selection_background": get("selection", default=bg),
        "selection_foreground": get("selection_foreground", default=fg),
        "urls": get("urls", default=ansi[4]),
        "accent": accent,
        "mode": data.get("mode", "dark"),
    }
