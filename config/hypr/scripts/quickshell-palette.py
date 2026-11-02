#!/usr/bin/env python3
"""Build the shell's Nix-owned palette bundles from the scheme registry.

Nix runs this at build time and links the result under
$XDG_STATE_HOME/quickshell/palettes/<key>.json. Every palette carries the shell
tokens Dyn.qml exposes, the Material-ish roles the templates interpolate, and a
terminal section (foot/ANSI, selection, cursor). theme.py copies the active
bundle to current.json and renders every consumer from it.

Washi is the fixed identity; the scheme palettes keep their own background,
foreground and accent instead of going through matugen, so "scheme" really looks
like the scheme. The containers and text tiers are blended from those three.
"""
import argparse
import json
import sys
from pathlib import Path

from themelib import (
    WASHI_TERMINAL,
    darken,
    is_light,
    lighten,
    load_registry,
    mix,
    on,
    read_foot_theme,
    shift,
)

WASHI = {
    "background": "#211711",
    "on_background": "#e6d6cb",
    "surface": "#211711",
    "on_surface": "#e6d6cb",
    "surface_variant": "#2c2118",
    "on_surface_variant": "#b9a99e",
    "surface_container_lowest": "#1b120d",
    "surface_container_low": "#221813",
    "surface_container": "#2c2118",
    "surface_container_high": "#2e231b",
    "surface_container_highest": "#3b342b",
    "surface_bright": "#3b342b",
    "surface_dim": "#211711",
    "surface_tint": "#e0563b",
    "outline": "#594636",
    "outline_variant": "#3a2a22",
    "primary": "#e0563b",
    "on_primary": "#211711",
    "primary_container": "#a3371f",
    "on_primary_container": "#ffb38a",
    "secondary": "#ff9a64",
    "on_secondary": "#211711",
    "secondary_container": "#633f00",
    "on_secondary_container": "#ffddb3",
    "tertiary": "#f5bd6f",
    "on_tertiary": "#211711",
    "tertiary_container": "#5a3c00",
    "on_tertiary_container": "#ffe0a0",
    "error": "#c0442b",
    "on_error": "#fff6f0",
    "error_container": "#8a2c14",
    "on_error_container": "#ffd9c2",
    "inverse_surface": "#e6d6cb",
    "inverse_on_surface": "#211711",
    "inverse_primary": "#f5bd6f",
    "scrim": "#000000",
    "shadow": "#000000",
    "source_color": "#e0563b",
    "cream": "#e6d6cb",
    "bright": "#fff6f0",
    "subtle": "#b9a99e",
    "dim": "#8a7d74",
    "faint": "#6f635b",
    "icon_dim": "#cdbfb4",
    "tick_rest": "#cbb6a3",
    "on_glow": "#ff9a64",
    "verm": "#c0442b",
    "verm_lit": "#e0563b",
    "verm_deep": "#a3371f",
    "verm_dim": "#8a5440",
    "verm_dim_deep": "#5a3526",
    "verm_burn": "#8a2c14",
    "card_top": "#2e231b",
    "card_bot": "#221813",
    "border": "#3a2a22",
    "tile_bg": "#211711",
    "flame_core": "#ffd9c2",
    "flame_glow": "#ff9a64",
    "flame_ink": "#f0795a",
    "flame_ember": "#7e2812",
    "flame_burn": "#8a2c14",
    "flame_tip": "#ffb38a",
    "today_warm": "#ffb38a",
    "ghost": "#594636",
}


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
        # ramp; the washi overrides below pin the identity exactly.
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


def scheme_bundle(name, spec, path, mode):
    colors = read_foot_theme(path)
    bg, fg = colors["background"], colors["foreground"]
    accent = colors["ansi"][int(spec["accent"])]
    red = colors["ansi"][1]
    p = finalize(base(bg, fg, accent, red, is_light(bg)))
    return {
        **p,
        "key": f"{name}-{mode}",
        "source": "scheme",
        "scheme": name,
        "tone": mode,
        "editor": spec.get("editor", name),
        "terminal": colors,
    }


def washi_bundle():
    p = base("#211711", "#e6d6cb", "#e0563b", "#c0442b", False)
    p.update(WASHI)
    finalize(p)
    return {
        **p,
        "key": "washi",
        "source": "washi",
        "scheme": "washi",
        "tone": "dark",
        "editor": "generated",
        "terminal": WASHI_TERMINAL,
    }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--themes", required=True, type=Path)
    parser.add_argument("--schemes", required=True, type=Path)
    parser.add_argument("--out", required=True, type=Path)
    args = parser.parse_args()

    registry = load_registry(args.schemes)
    schemes = {
        name: spec
        for name, spec in registry["schemes"].items()
        if not spec.get("identity")
    }
    args.out.mkdir(parents=True, exist_ok=True)

    washi = washi_bundle()
    (args.out / "washi.json").write_text(
        json.dumps(washi, indent=2, sort_keys=True) + "\n"
    )
    written = ["washi"]

    for name, spec in sorted(schemes.items()):
        for mode in ("dark", "light"):
            path = args.themes / f"{name}-{mode}.ini"
            if not path.is_file():
                raise SystemExit(f"missing theme: {path}")
            bundle = scheme_bundle(name, spec, path, mode)
            (args.out / f"{bundle['key']}.json").write_text(
                json.dumps(bundle, indent=2, sort_keys=True) + "\n"
            )
            written.append(bundle["key"])

    print(" ".join(written))


if __name__ == "__main__":
    sys.exit(main())
