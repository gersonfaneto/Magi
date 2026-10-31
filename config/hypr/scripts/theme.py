#!/usr/bin/env python3
"""Apply and render the desktop theme.

One palette bundle drives every consumer: the Quickshell pill and lock read
current.json, and the manifest here renders Hyprland, Qt, foot, highlight, the
generated nvim colorscheme, tmux, fzf and the zsh shell from that same file.
The bundle comes from the Nix-built scheme set or from wallcolors.py for the
dynamic mode.

    theme.py apply [--refresh]
    theme.py source scheme|dynamic
    theme.py set SCHEME
    theme.py bg light|dark
    theme.py render
    theme.py status
    theme.py list
    theme.py check
    theme.py apps on|off
"""
import argparse
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

from themelib import darken, is_light, lighten, load_registry, mix, on

HOME = Path.home()
CONFIG = Path(os.environ.get("XDG_CONFIG_HOME") or HOME / ".config")
STATE = Path(os.environ.get("XDG_STATE_HOME") or HOME / ".local" / "state")
SCRIPT_DIR = Path(__file__).resolve().parent
CONFIG_ROOT = Path(os.environ.get("MAGI_CONFIG_DIR") or SCRIPT_DIR.parents[1])
REGISTRY = CONFIG_ROOT / "theme" / "schemes.json"

PALETTES = STATE / "quickshell" / "palettes"
CURRENT = PALETTES / "current.json"
FLAGS = STATE / "quickshell" / "flags.json"
MANIFEST = STATE / "quickshell" / "templates.json"
APPLIED = STATE / "quickshell" / "palette-applied"

WALLCOLORS = SCRIPT_DIR / "wallcolors.py"
FOOT_THEME = CONFIG / "foot" / "theme.ini"
NVIM_STATE = STATE / "nvim" / "colors.json"
WALLPAPER = STATE / "quickshell-wallpaper"
WALLPAPER_STILL = STATE / "quickshell-wallpaper-still.png"

PALETTE_MODES = ("scheme", "dynamic")
REMOVED_FLAGS = ("manualHue", "manualDark", "manualSat")

DEFAULT_FLAGS = {
    "paletteMode": "scheme",
    "scheme": "nano",
    "bg": "dark",
    "appTheme": False,
}

COLOR_TOKEN = re.compile(
    r"\{\{\s*(colors|terminal)\.([a-z0-9_]+)(?:\.(?:default|dark|light))?"
    r"\.(hex_stripped|hex|rgb|ansi38|ansi48)\s*\}\}"
)
BUNDLE_TOKEN = re.compile(r"\{\{\s*bundle\.([a-z0-9_]+)\s*\}\}")


class ThemeError(RuntimeError):
    pass


def read_json(path, default):
    try:
        return json.loads(path.read_text())
    except (OSError, ValueError):
        return default


def write_json(path, data, atomic=True):
    path.parent.mkdir(parents=True, exist_ok=True)
    text = json.dumps(data, indent=2) + "\n"
    if not atomic:
        # Quickshell's FileView watches these two by inode; replacing the file
        # would drop the watch, so write through the existing one.
        path.write_text(text)
        return
    tmp = path.with_name(path.name + ".tmp")
    tmp.write_text(text)
    tmp.replace(path)


def read_flags():
    flags = read_json(FLAGS, {})
    for key, value in DEFAULT_FLAGS.items():
        flags.setdefault(key, value)
    changed = False
    for key in REMOVED_FLAGS:
        if key in flags:
            del flags[key]
            changed = True
    if flags["paletteMode"] not in PALETTE_MODES:
        flags["paletteMode"] = "scheme"
        changed = True
    if changed and FLAGS.is_file():
        write_json(FLAGS, flags, atomic=False)
    return flags


def write_flags(update):
    flags = read_flags()
    flags.update(update)
    write_json(FLAGS, flags, atomic=False)
    return flags


def registry():
    try:
        return load_registry(REGISTRY)
    except OSError as exc:
        raise ThemeError(f"cannot read {REGISTRY}: {exc}") from exc


def selectable(reg):
    return {
        name: spec
        for name, spec in reg["schemes"].items()
        if not spec.get("identity")
    }


def check_scheme(reg, name):
    schemes = selectable(reg)
    if name not in schemes:
        raise ThemeError(
            f"unknown scheme: {name} (choose from {', '.join(sorted(schemes))})"
        )
    return schemes[name]


def bundle_key(flags):
    mode = flags["paletteMode"]
    if mode == "scheme":
        name = flags["scheme"]
        bg = flags["bg"]
        return f"{name}-{bg}"
    if mode == "dynamic":
        return mode
    raise ThemeError(f"unknown palette mode: {mode}")


def wallpaper_path():
    try:
        pic = WALLPAPER.read_text().strip()
    except OSError:
        return None
    if not pic:
        return None
    if Path(pic).suffix.lower() in (".mp4", ".webm", ".mkv", ".mov"):
        pic = str(WALLPAPER_STILL)
    return Path(pic) if Path(pic).is_file() else None


def run_wallcolors():
    env = os.environ.copy()
    env["QUICKSHELL_PALETTE"] = "dynamic"
    pic = wallpaper_path()
    if pic is None:
        raise ThemeError("no wallpaper to derive a dynamic palette from")
    subprocess.run([sys.executable, str(WALLCOLORS), str(pic)], env=env, check=True)


def ensure_bundle(flags, refresh=False):
    key = bundle_key(flags)
    path = PALETTES / f"{key}.json"
    if flags["paletteMode"] == "dynamic":
        if refresh or not path.is_file():
            try:
                run_wallcolors()
            except subprocess.CalledProcessError:
                if not path.is_file():
                    raise ThemeError("dynamic palette generation failed")
        if not path.is_file():
            raise ThemeError(f"palette generator wrote no {path}")
        return path
    if not path.is_file():
        raise ThemeError(f"missing Nix palette: {path}")
    return path


def complete_bundle(bundle):
    """Fill roles a runtime generator did not emit.

    The Nix bundles carry the full set. wallcolors.py only needs the shell
    tokens, so the shared template roles are derived here rather than copied
    into a second generator. Anything present wins.
    """
    tone = bundle.get("tone") or (
        "light" if is_light(bundle.get("surface", "#000000")) else "dark"
    )
    bundle["tone"] = tone
    surface = bundle.get("surface", "#211711")
    cream = bundle.get("cream") or bundle.get("on_surface") or "#e6d6cb"
    primary = bundle.get("primary", "#e0563b")
    subtle = bundle.get("subtle") or mix(cream, surface, 0.25)
    container = bundle.get("surface_container") or surface
    low = bundle.get("surface_container_low") or surface
    error = bundle.get("error") or ("#d05a4a" if tone == "dark" else "#b3261e")
    secondary = bundle.get("secondary") or mix(primary, cream, 0.30)
    tertiary = bundle.get("tertiary") or mix(primary, cream, 0.50)
    high = bundle.get("surface_container_high") or (
        mix(surface, cream, 0.08) if tone == "dark" else darken(surface, 0.04)
    )
    bright = bundle.get("bright") or (
        lighten(cream, 0.35) if tone == "dark" else darken(cream, 0.35)
    )

    defaults = {
        "background": surface,
        "on_background": cream,
        "on_surface": cream,
        "surface_variant": container,
        "surface_container": container,
        "surface_container_low": low,
        "surface_container_high": high,
        "surface_container_highest": mix(surface, cream, 0.12)
        if tone == "dark"
        else darken(surface, 0.08),
        "surface_container_lowest": darken(low, 0.12)
        if tone == "dark"
        else lighten(low, 0.12),
        "on_surface_variant": subtle,
        "outline": mix(cream, surface, 0.55),
        "outline_variant": mix(cream, surface, 0.78),
        "primary": primary,
        "on_primary": on(primary),
        "primary_container": mix(surface, primary, 0.45),
        "on_primary_container": mix(primary, cream, 0.55),
        "bright": bright,
        "dim": mix(cream, surface, 0.42),
        "faint": mix(cream, surface, 0.58),
        "icon_dim": mix(cream, surface, 0.12),
        "secondary": secondary,
        "on_secondary": surface,
        "secondary_container": mix(surface, secondary, 0.35),
        "on_secondary_container": mix(secondary, cream, 0.55),
        "tertiary": tertiary,
        "on_tertiary": surface,
        "tertiary_container": mix(surface, tertiary, 0.35),
        "on_tertiary_container": mix(tertiary, cream, 0.55),
        "error": error,
        "on_error": on(error),
        "error_container": mix(surface, error, 0.35),
        "on_error_container": mix(error, cream, 0.55),
        "shadow": "#000000",
    }
    for key, value in defaults.items():
        bundle.setdefault(key, value)
    return bundle


def load_bundle(path):
    bundle = read_json(path, None)
    if not isinstance(bundle, dict):
        raise ThemeError(f"cannot read palette bundle: {path}")
    return complete_bundle(bundle)


def write_current(bundle):
    write_json(CURRENT, bundle, atomic=False)


def token_value(bundle, namespace, key):
    if namespace == "colors":
        value = bundle.get(key)
    else:
        terminal = bundle.get("terminal") or {}
        match = re.fullmatch(r"ansi(\d+)", key)
        if match:
            index = int(match.group(1))
            ansi = terminal.get("ansi") or []
            value = ansi[index] if index < len(ansi) else None
        else:
            value = terminal.get(key)
    if not isinstance(value, str):
        raise ThemeError(f"unknown {namespace} token: {key}")
    if not re.fullmatch(r"#[0-9a-fA-F]{6}", value):
        raise ThemeError(f"invalid colour for {namespace}.{key}: {value}")
    return value


def format_colour(value, fmt):
    if fmt == "hex":
        return value
    if fmt == "hex_stripped":
        return value[1:]
    r, g, b = (int(value[i : i + 2], 16) for i in (1, 3, 5))
    if fmt == "rgb":
        return f"rgb({r}, {g}, {b})"
    if fmt == "ansi48":
        return f"48;2;{r};{g};{b}"
    return f"38;2;{r};{g};{b}"


def render(text, bundle):
    def colour(match):
        namespace, key, fmt = match.groups()
        return format_colour(token_value(bundle, namespace, key), fmt)

    def meta(match):
        key = match.group(1)
        value = bundle.get(key)
        if value is None:
            raise ThemeError(f"unknown bundle token: {key}")
        return str(value)

    text = COLOR_TOKEN.sub(colour, text)
    text = BUNDLE_TOKEN.sub(meta, text)
    if "{{" in text:
        line = next((n for n in text.splitlines() if "{{" in n), "")
        raise ThemeError(f"unresolved template token: {line.strip()}")
    return text


def validate_manifest(entries):
    seen = {}
    for entry in entries:
        name = entry.get("name") or "?"
        target = entry.get("output_path")
        if not target:
            raise ThemeError(f"manifest entry {name} has no output_path")
        path = Path(target)
        if not path.is_absolute():
            raise ThemeError(f"manifest entry {name} has a relative output_path: {path}")
        if path == CONFIG_ROOT or CONFIG_ROOT in path.parents:
            raise ThemeError(f"manifest entry {name} writes into the checkout: {path}")
        if path in seen:
            raise ThemeError(
                f"manifest entries {seen[path]} and {name} both write {path}"
            )
        seen[path] = name
    return entries


def manifest_entries():
    entries = read_json(MANIFEST, [])
    if not isinstance(entries, list):
        raise ThemeError(f"{MANIFEST}: expected a list")
    return validate_manifest(entries)


def run_hook(command):
    if not command:
        return
    # hyprctl eval prints "ok" to stdout; a hook's output is not the renderer's.
    subprocess.run(command, shell=True, check=False, stdout=subprocess.DEVNULL)


def rewrite(path, text):
    try:
        if path.read_text() == text:
            return False
    except OSError:
        pass
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_name(path.name + ".tmp")
    tmp.write_text(text)
    tmp.replace(path)
    return True


def render_manifest(bundle):
    changed = []
    for entry in manifest_entries():
        source = Path(entry.get("input_path", ""))
        target = Path(entry.get("output_path", ""))
        if not entry.get("output_path"):
            raise ThemeError(f"manifest entry {entry.get('name')} has no output_path")
        if not source.is_file():
            raise ThemeError(f"missing template: {source}")
        text = render(source.read_text(), bundle)
        if rewrite(target, text):
            changed.append(str(target))
        # Run the hook even when the text is byte-identical: it is what makes a
        # freshly started Hyprland pick up a palette rendered on a previous boot.
        run_hook(entry.get("post_hook"))
    return changed


def app_theme(bundle, enabled):
    marker = APPLIED
    previous = marker.read_text().strip() if marker.is_file() else ""
    if enabled:
        wanted = f"on {bundle.get('key', '')}"
        if previous == wanted:
            return False
        subprocess.run(
            [sys.executable, str(WALLCOLORS), "--apps", "on"], check=False
        )
    else:
        if not previous.startswith("on"):
            return False
        subprocess.run(
            [sys.executable, str(WALLCOLORS), "--apps", "off"], check=False
        )
        wanted = "off"
    marker.parent.mkdir(parents=True, exist_ok=True)
    marker.write_text(wanted + "\n")
    return True


def nvim_expr(editor, bg):
    def esc(value):
        return value.replace("'", "''")

    return (
        'execute("if get(g:, \'colors_name\', \'\') !=# \'%s\' | '
        "let g:script_set_colors=1 | silent! colors %s | "
        "unlet g:script_set_colors | endif | "
        "if &bg !=# '%s' | let g:script_set_bg=1 | set bg=%s | "
        'unlet g:script_set_bg | endif")' % (esc(editor), editor, bg, bg)
    )


def push_nvim(bundle):
    editor = bundle.get("editor") or "generated"
    bg = "light" if bundle.get("tone") == "light" else "dark"
    write_json(NVIM_STATE, {"bg": bg, "colors_name": editor})

    if shutil.which("nvim") is None or shutil.which("nvim-socks") is None:
        return
    try:
        sockets = subprocess.run(
            ["timeout", "1", "nvim-socks"],
            capture_output=True,
            text=True,
            timeout=2,
        ).stdout.split()
    except (OSError, subprocess.SubprocessError):
        return
    for sock in sockets:
        try:
            subprocess.run(
                [
                    "timeout",
                    "2",
                    "nvim",
                    "--clean",
                    "--headless",
                    "--server",
                    sock,
                    "--remote-expr",
                    nvim_expr(editor, bg),
                ],
                timeout=3,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
        except (OSError, subprocess.SubprocessError):
            continue


def reload_foot():
    if not FOOT_THEME.is_file():
        return
    if shutil.which("magi") is not None:
        subprocess.run(
            ["magi", "@foot", "reload-colors", str(FOOT_THEME)],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            timeout=10,
            check=False,
        )
        return
    foot_ini = CONFIG / "foot" / "foot.ini"
    if os.access(foot_ini, os.W_OK):
        foot_ini.touch()


def apply(refresh=False):
    flags = read_flags()
    path = ensure_bundle(flags, refresh=refresh)
    bundle = load_bundle(path)
    write_current(bundle)
    changed = render_manifest(bundle)
    app_theme(bundle, bool(flags.get("appTheme")))
    push_nvim(bundle)
    reload_foot()
    return changed, bundle, flags


def cmd_apply(args):
    changed, bundle, _ = apply(refresh=args.refresh)
    for path in changed:
        print(f"rendered {path}")
    print(f"applied {bundle.get('key')}")
    return 0


def cmd_render(_args):
    flags = read_flags()
    if CURRENT.is_file():
        bundle = load_bundle(CURRENT)
    else:
        bundle = load_bundle(ensure_bundle(flags))
    write_current(bundle)
    for path in render_manifest(bundle):
        print(f"rendered {path}")
    return 0


def cmd_source(args):
    reg = registry()
    mode = args.mode
    if mode not in PALETTE_MODES:
        raise ThemeError(f"unknown palette mode: {mode} (use scheme or dynamic)")
    if mode == "scheme":
        check_scheme(reg, read_flags()["scheme"])
    write_flags({"paletteMode": mode})
    changed, bundle, _ = apply(refresh=mode == "dynamic")
    for path in changed:
        print(f"rendered {path}")
    print(f"applied {bundle.get('key')}")
    return 0


def cmd_set(args):
    reg = registry()
    name = args.scheme or reg["default"]["scheme"]
    check_scheme(reg, name)
    write_flags({"scheme": name, "paletteMode": "scheme"})
    changed, bundle, _ = apply()
    for path in changed:
        print(f"rendered {path}")
    print(f"applied {bundle.get('key')}")
    return 0


def cmd_bg(args):
    tone = args.tone or registry()["default"]["bg"]
    if tone not in ("light", "dark"):
        raise ThemeError(f"unknown background: {tone} (use light or dark)")
    write_flags({"bg": tone, "paletteMode": "scheme"})
    changed, bundle, _ = apply()
    for path in changed:
        print(f"rendered {path}")
    print(f"applied {bundle.get('key')}")
    return 0


def cmd_apps(args):
    flags = read_flags()
    write_flags({"appTheme": args.mode == "on"})
    bundle = (
        load_bundle(CURRENT)
        if CURRENT.is_file()
        else load_bundle(ensure_bundle(flags))
    )
    app_theme(bundle, args.mode == "on")
    return 0


def cmd_list(_args):
    for name in sorted(selectable(registry())):
        print(name)
    return 0


def cmd_status(_args):
    flags = read_flags()
    key = bundle_key(flags)
    path = PALETTES / f"{key}.json"
    bundle = read_json(path, {})
    print(f"mode:    {flags['paletteMode']}")
    print(f"scheme:  {flags['scheme']}")
    print(f"bg:      {flags['bg']}")
    print(f"key:     {key}")
    print(f"bundle:  {path}{'' if path.is_file() else ' (missing)'}")
    print(f"current: {CURRENT}{'' if CURRENT.is_file() else ' (missing)'}")
    print(f"editor:  {bundle.get('editor', '(none)')}")
    print(f"theme:   {FOOT_THEME}{'' if FOOT_THEME.is_file() else ' (missing)'}")
    return 0


def cmd_check(_args):
    reg = registry()
    errors = []
    themes = CONFIG_ROOT / "foot" / "themes"
    for name in selectable(reg):
        for mode in ("dark", "light"):
            path = themes / f"{name}-{mode}.ini"
            if not path.is_file():
                errors.append(f"missing scheme file: {path}")
    if not MANIFEST.is_file():
        errors.append(f"missing manifest: {MANIFEST}")
    else:
        for entry in manifest_entries():
            source = Path(entry.get("input_path", ""))
            if not source.is_file():
                errors.append(f"missing template: {source}")

    path = CURRENT if CURRENT.is_file() else PALETTES / "washi.json"
    if not path.is_file():
        errors.append(f"missing palette bundle: {path}")
    else:
        bundle = load_bundle(path)
        try:
            for entry in manifest_entries():
                source = Path(entry.get("input_path", ""))
                if source.is_file():
                    render(source.read_text(), bundle)
        except ThemeError as exc:
            errors.append(str(exc))

    for error in errors:
        print(error, file=sys.stderr)
    if errors:
        return 1
    print("theme: ok")
    return 0


def main(argv=None):
    parser = argparse.ArgumentParser(prog="theme.py")
    sub = parser.add_subparsers(dest="command", required=True)

    p = sub.add_parser("apply")
    p.add_argument("--refresh", action="store_true")
    p.set_defaults(func=cmd_apply)

    p = sub.add_parser("render")
    p.set_defaults(func=cmd_render)

    p = sub.add_parser("source")
    p.add_argument("mode")
    p.set_defaults(func=cmd_source)

    p = sub.add_parser("set")
    p.add_argument("scheme", nargs="?")
    p.set_defaults(func=cmd_set)

    p = sub.add_parser("bg")
    p.add_argument("tone", nargs="?")
    p.set_defaults(func=cmd_bg)

    p = sub.add_parser("apps")
    p.add_argument("mode", choices=("on", "off"))
    p.set_defaults(func=cmd_apps)

    sub.add_parser("list").set_defaults(func=cmd_list)
    sub.add_parser("status").set_defaults(func=cmd_status)
    sub.add_parser("check").set_defaults(func=cmd_check)

    args = parser.parse_args(argv)
    try:
        return args.func(args)
    except ThemeError as exc:
        print(f"theme: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
