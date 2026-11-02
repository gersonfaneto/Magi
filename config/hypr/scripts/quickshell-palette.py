#!/usr/bin/env python3
"""Build the shell's Nix-owned palette bundles from the canonical themes.

Nix runs this at build time and links the result under
$XDG_STATE_HOME/quickshell/palettes/<key>.json. Every palette carries the shell
tokens Dyn.qml exposes, the Material-ish roles the templates interpolate, and a
terminal section (foot/ANSI, selection, cursor). It also writes the static foot
fallbacks under foot/. theme.py copies the active bundle to current.json and
renders every consumer from it.

The scheme palettes keep their own background, foreground and accent, so
"scheme" really looks like the scheme. The containers and text tiers are
blended from those three.
"""
import argparse
import json
import sys
from pathlib import Path

from themelib import (
    is_light,
    load_registry,
    read_colors_toml,
    theme_bundle,
)


def scheme_bundle(name, spec, path, mode):
    colors = read_colors_toml(path)
    if colors["mode"] != mode:
        raise SystemExit(f"{path}: mode is {colors['mode']}, expected {mode}")
    bg = colors["background"]
    if (colors["mode"] == "light") != is_light(bg):
        raise SystemExit(f"{path}: mode {colors['mode']} does not match background {bg}")
    return theme_bundle(
        colors,
        f"{name}-{mode}",
        "scheme",
        name,
        mode,
        spec.get("editor", "generated"),
    )


def foot_ini(bundle):
    """A foot palette for the scheme, used for the fallback include."""
    terminal = bundle["terminal"]
    ansi = terminal["ansi"]
    tone = bundle["tone"]

    def strip(value):
        return value.lstrip("#")

    lines = [
        "[main]",
        f"initial-color-theme={tone}",
        "",
        f"[colors-{tone}]",
        f"foreground={strip(terminal['foreground'])}",
        f"background={strip(terminal['background'])}",
        "",
    ]
    for index in range(8):
        lines.append(f"regular{index}={strip(ansi[index])}")
    lines.append("")
    for index in range(8):
        lines.append(f"bright{index}={strip(ansi[index + 8])}")
    lines += [
        "",
        f"selection-foreground={strip(terminal['selection_foreground'])}",
        f"selection-background={strip(terminal['selection_background'])}",
        f"urls={strip(terminal['urls'])}",
        f"cursor={strip(terminal['background'])} {strip(terminal['cursor'])}",
    ]
    return "\n".join(lines) + "\n"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--themes", required=True, type=Path)
    parser.add_argument("--schemes", required=True, type=Path)
    parser.add_argument("--out", required=True, type=Path)
    args = parser.parse_args()

    registry = load_registry(args.schemes)
    args.out.mkdir(parents=True, exist_ok=True)
    foot = args.out / "foot"
    foot.mkdir()

    written = []
    for name, spec in sorted(registry["schemes"].items()):
        modes = [
            mode
            for mode in ("dark", "light")
            if (args.themes / f"{name}-{mode}.toml").is_file()
        ]
        if not modes:
            raise SystemExit(f"no colors.toml for scheme: {name}")
        for mode in modes:
            path = args.themes / f"{name}-{mode}.toml"
            bundle = scheme_bundle(name, spec, path, mode)
            (args.out / f"{bundle['key']}.json").write_text(
                json.dumps(bundle, indent=2, sort_keys=True) + "\n"
            )
            (foot / f"{bundle['key']}.ini").write_text(foot_ini(bundle))
            written.append(bundle["key"])

    print(" ".join(written))


if __name__ == "__main__":
    sys.exit(main())
