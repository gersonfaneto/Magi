#!/usr/bin/env python3
"""Apply and render the monochrome desktop theme.

One palette family has two tones. Every consumer -- Hyprland, Qt, fsel,
qutebrowser, GTK, foot, highlight, nvim, tmux, fzf and the zsh shell -- renders
from the same mono-<tone> bundle.

    theme.py apply
    theme.py bg light|dark
    theme.py render
    theme.py status
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

HOME = Path.home()
CONFIG = Path(os.environ.get("XDG_CONFIG_HOME") or HOME / ".config")
STATE = Path(os.environ.get("XDG_STATE_HOME") or HOME / ".local" / "state")
DATA = Path(os.environ.get("XDG_DATA_HOME") or HOME / ".local" / "share")
SCRIPT_DIR = Path(__file__).resolve().parent
CONFIG_ROOT = Path(os.environ.get("MAGI_CONFIG_DIR") or SCRIPT_DIR.parents[2])

PALETTES = STATE / "magi" / "theme" / "palettes"
CURRENT = PALETTES / "current.json"
FLAGS = PALETTES.parent / "flags.json"
MANIFEST = PALETTES.parent / "templates.json"
APPLIED = PALETTES.parent / "palette-applied"
INFO = DATA / "magi" / "info.json"

WALLCOLORS = SCRIPT_DIR / "wallcolors.py"
WALLPAPER = SCRIPT_DIR / "wallpaper.sh"
FOOT_THEME = CONFIG / "foot" / "theme.ini"
NVIM_STATE = STATE / "nvim" / "colors.json"

TONES = ("dark", "light")
REMOVED_FLAGS = ("paletteMode", "scheme", "manualHue", "manualDark", "manualSat")
DEFAULT_FLAGS = {
    "bg": "dark",
    "appTheme": True,
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
        # The theme path unit watches these two; writing in place keeps the
        # inode stable so a watcher does not see a rename.
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
    legacy = any(key in flags for key in REMOVED_FLAGS)
    for key in REMOVED_FLAGS:
        if key in flags:
            del flags[key]
            changed = True
    # The old registry could leave app theming off; an upgrade should land on
    # the mono GTK override, which is the default now. A later `theme apps off`
    # is a deliberate choice and survives because the legacy keys are gone.
    if legacy and not flags.get("appTheme"):
        flags["appTheme"] = True
        changed = True
    if flags["bg"] not in TONES:
        flags["bg"] = "dark"
        changed = True
    if changed and FLAGS.is_file():
        write_json(FLAGS, flags, atomic=False)
    return flags


def write_flags(update):
    flags = read_flags()
    flags.update(update)
    write_json(FLAGS, flags, atomic=False)
    return flags


def bundle_key(flags):
    return f"mono-{flags['bg']}"


def bundle_path(flags):
    return PALETTES / f"{bundle_key(flags)}.json"


def load_bundle(path):
    bundle = read_json(path, None)
    if not isinstance(bundle, dict):
        raise ThemeError(f"cannot read palette bundle: {path}")
    if not bundle.get("tone"):
        raise ThemeError(f"palette bundle has no tone: {path}")
    return bundle


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
        scope = entry.get("scope") or "desktop"
        if scope not in ("desktop", "terminal"):
            raise ThemeError(
                f"manifest entry {name} has an unknown scope: {scope} "
                f"(use desktop or terminal)"
            )
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
    scope_bundles = {"desktop": bundle, "terminal": bundle}
    for entry in manifest_entries():
        source = Path(entry.get("input_path", ""))
        target = Path(entry.get("output_path", ""))
        if not source.is_file():
            raise ThemeError(f"missing template: {source}")
        text = render(source.read_text(), scope_bundles[entry.get("scope") or "desktop"])
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


def info_theme():
    info = read_json(INFO, {})
    theme = info.get("theme") if isinstance(info, dict) else None
    return theme if isinstance(theme, dict) else {}


def set_gsetting(key, value):
    if shutil.which("gsettings") is None:
        return
    subprocess.run(
        ["gsettings", "set", "org.gnome.desktop.interface", key, value],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=False,
    )


def apply_desktop_extras(bundle):
    light = bundle.get("tone") == "light"
    theme = info_theme()
    icons = theme.get("icons") or {}
    cursor = theme.get("cursor") or {}

    icon = icons.get("lightName" if light else "name") or (
        "Mono" if light else "Mono-Dark"
    )
    cursor_name = cursor.get("lightName" if light else "name") or (
        "phinger-cursors-light" if light else "phinger-cursors-dark"
    )
    size = str(cursor.get("size") or 32)

    set_gsetting("icon-theme", icon)
    set_gsetting("cursor-theme", cursor_name)

    if shutil.which("hyprctl") is not None:
        subprocess.run(
            ["hyprctl", "setcursor", cursor_name, size],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=False,
        )


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


def switch_wallpaper(tone):
    if not os.environ.get("HYPRLAND_INSTANCE_SIGNATURE"):
        return
    if not WALLPAPER.is_file() or not os.access(WALLPAPER, os.X_OK):
        return
    subprocess.run(
        ["bash", str(WALLPAPER), "tone", tone],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        timeout=60,
        check=False,
    )


def apply():
    flags = read_flags()
    bundle = load_bundle(bundle_path(flags))
    write_current(bundle)
    changed = render_manifest(bundle)
    app_theme(bundle, bool(flags.get("appTheme")))
    apply_desktop_extras(bundle)
    push_nvim(bundle)
    reload_foot()
    return changed, bundle, flags


def cmd_apply(_args):
    changed, bundle, _ = apply()
    for path in changed:
        print(f"rendered {path}")
    print(f"applied {bundle.get('key')}")
    return 0


def cmd_render(_args):
    flags = read_flags()
    if CURRENT.is_file():
        bundle = load_bundle(CURRENT)
    else:
        bundle = load_bundle(bundle_path(flags))
    write_current(bundle)
    for path in render_manifest(bundle):
        print(f"rendered {path}")
    return 0


def cmd_bg(args):
    tone = args.tone
    if tone is None:
        print(read_flags()["bg"])
        return 0
    if tone not in TONES:
        raise ThemeError(f"unknown background: {tone} (use light or dark)")
    write_flags({"bg": tone})
    changed, bundle, _ = apply()
    for path in changed:
        print(f"rendered {path}")
    switch_wallpaper(tone)
    print(f"applied {bundle.get('key')}")
    return 0


def cmd_apps(args):
    flags = read_flags()
    write_flags({"appTheme": args.mode == "on"})
    bundle = (
        load_bundle(CURRENT)
        if CURRENT.is_file()
        else load_bundle(bundle_path(flags))
    )
    app_theme(bundle, args.mode == "on")
    return 0


def cmd_status(_args):
    flags = read_flags()
    path = bundle_path(flags)
    bundle = read_json(path, {})
    print(f"bg:       {flags['bg']}")
    print(f"palette:  {path}{'' if path.is_file() else ' (missing)'}")
    print(f"current:  {CURRENT}{'' if CURRENT.is_file() else ' (missing)'}")
    print(f"editor:   {bundle.get('editor', '(none)')}")
    print(f"theme:    {FOOT_THEME}{'' if FOOT_THEME.is_file() else ' (missing)'}")
    return 0


def cmd_check(_args):
    errors = []
    for tone in TONES:
        path = PALETTES / f"mono-{tone}.json"
        if not path.is_file():
            errors.append(f"missing palette bundle: {path}")
        foot = CONFIG_ROOT / "config" / "foot" / "themes" / f"mono-{tone}.ini"
        if not foot.is_file():
            errors.append(f"missing foot theme: {foot}")

    if not MANIFEST.is_file():
        errors.append(f"missing manifest: {MANIFEST}")
    else:
        for entry in manifest_entries():
            source = Path(entry.get("input_path", ""))
            if not source.is_file():
                errors.append(f"missing template: {source}")

    if not errors:
        for tone in TONES:
            path = PALETTES / f"mono-{tone}.json"
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

    sub.add_parser("apply").set_defaults(func=cmd_apply)
    sub.add_parser("render").set_defaults(func=cmd_render)

    p = sub.add_parser("bg")
    p.add_argument("tone", nargs="?")
    p.set_defaults(func=cmd_bg)

    p = sub.add_parser("apps")
    p.add_argument("mode", choices=("on", "off"))
    p.set_defaults(func=cmd_apps)

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
