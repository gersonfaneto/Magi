#!/usr/bin/env python3
"""Build the monochrome palette bundles.

Nix runs this at build time and links the result under
$XDG_STATE_HOME/magi/theme/palettes/<tone>.json. Every bundle carries the roles
the templates interpolate plus a terminal section (foot/ANSI, selection,
cursor). theme.py copies the active bundle to current.json and renders every
template from it.

There is one palette family and two tones. The terminal themes in
config/foot/themes/mono-{dark,light}.ini define the background, foreground and
16 ANSI slots; the containers and text tiers are blended from those. The accent
is ANSI 7 in both tones: light gray on the dark bundle, dark gray on the light
one.
"""
import argparse
import json
import sys
from pathlib import Path

from themelib import (
    darken,
    is_light,
    lighten,
    mix,
    on,
    read_foot_theme,
    shift,
)

TONES = ("dark", "light")
ACCENT = 7
ERROR = 1


def base(bg, fg, accent, red, light):
    """The base palette, before fixed/inverse roles are filled in."""
    if light:
        lowest = lighten(bg, 0.60)
        low = lighten(bg, 0.30)
        container = darken(bg, 0.04)
        high = darken(bg, 0.08)
        highest = darken(bg, 0.12)
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
        # Shell tokens Dyn.qml reads. The derived ones mirror the prompt's
        # flame ramp; grayscale keeps them neutral.
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


def mono_bundle(tone, path):
    colors = read_foot_theme(path)
    bg, fg = colors["background"], colors["foreground"]
    accent = colors["ansi"][ACCENT]
    red = colors["ansi"][ERROR]
    p = finalize(base(bg, fg, accent, red, is_light(bg)))
    return {
        **p,
        "key": f"mono-{tone}",
        "source": "mono",
        "tone": tone,
        "editor": "generated",
        "terminal": colors,
    }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--themes", required=True, type=Path)
    parser.add_argument("--out", required=True, type=Path)
    args = parser.parse_args()

    args.out.mkdir(parents=True, exist_ok=True)

    written = []
    for tone in TONES:
        path = args.themes / f"mono-{tone}.ini"
        if not path.is_file():
            raise SystemExit(f"missing theme: {path}")
        bundle = mono_bundle(tone, path)
        (args.out / f"{bundle['key']}.json").write_text(
            json.dumps(bundle, indent=2, sort_keys=True) + "\n"
        )
        written.append(bundle["key"])

    print(" ".join(written))


if __name__ == "__main__":
    sys.exit(main())
