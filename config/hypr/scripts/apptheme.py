#!/usr/bin/env python3
"""Point GTK apps at the active curated palette.

theme.py owns the palette bundle and writes it to current.json. This script
turns that bundle into the named GTK colours and the alternating
Quickshell-a/b GTK3 wrapper, so desktop apps follow the same curated scheme as
the pill and terminal. It never derives a palette from a wallpaper.
"""
import colorsys
import fcntl
import json
import os
import shutil
import subprocess
import sys
import time
from pathlib import Path

STATE = Path(os.environ.get("XDG_STATE_HOME") or Path.home() / ".local" / "state") / "quickshell"
PALETTES = STATE / "palettes"
CURRENT = PALETTES / "current.json"
GTK4 = Path(os.environ.get("XDG_CONFIG_HOME") or Path.home() / ".config") / "gtk-4.0"
GTK3 = GTK4.parent / "gtk-3.0"
THEMES = Path(os.environ.get("XDG_DATA_HOME") or Path.home() / ".local" / "share") / "themes"
OVERRIDES = Path(os.environ.get("XDG_DATA_HOME") or Path.home() / ".local" / "share") / "flatpak" / "overrides" / "global"
FLATPAK_FS = ["xdg-config/gtk-4.0:ro", "xdg-data/themes:ro"]
IFACE = "org.gnome.desktop.interface"
MARK = "/** Quickshell app theme, turn it off in Settings > Appearance */\n"
QUICKSHELL_THEMES = ["Quickshell-a", "Quickshell-b", "Quickshell-base", "Quickshell-base-dark"]
# The default scheme's bundle, used only when App theme is switched on before
# theme.py has written current.json.
DEFAULT_FALLBACK = {"surface": "#2e3440", "surface_container_low": "#323844", "surface_container": "#363c47",
                    "surface_container_high": "#3b404c", "outline_variant": "#515660", "primary": "#81a1c0",
                    "cream": "#cbced2", "bright": "#dddfe2"}


def current_bundle():
    """The bundle theme.py last applied, so GTK follows the active scheme."""
    try:
        return json.loads(CURRENT.read_text())
    except (OSError, ValueError):
        return None


def active_palette(pill):
    return current_bundle() or pill


def gget(key):
    if shutil.which("gsettings") is None:
        return ""
    out = subprocess.run(["gsettings", "get", IFACE, key], capture_output=True, text=True)
    return out.stdout.strip().strip("'")


def gset(key, value):
    if shutil.which("gsettings") is None:
        return
    subprocess.run(["gsettings", "set", IFACE, key, value], capture_output=True)


def set_scheme(scheme, force):
    """GTK4 only re-reads its user CSS when the colour scheme changes, so an unchanged tone flips out and back."""
    if gget("color-scheme") == scheme:
        if not force:
            return
        gset("color-scheme", "prefer-light" if scheme == "prefer-dark" else "prefer-dark")
        time.sleep(0.25)
    gset("color-scheme", scheme)


def notify(summary, body):
    return subprocess.run(["gdbus", "call", "--session", "--dest", "org.freedesktop.Notifications",
                           "--object-path", "/org/freedesktop/Notifications",
                           "--method", "org.freedesktop.Notifications.Notify",
                           "Quickshell", "0", "", summary, body, "[]", "{}", "8000"],
                          capture_output=True).returncode == 0


def fs_path(fs):
    return fs.lstrip("!").split(":")[0]


def flatpak_shares():
    """Flatpak keys filesystems by path, so any existing entry for a path, whatever its mode, belongs to the user."""
    shares = []
    for f in (OVERRIDES, Path("/var/lib/flatpak/overrides/global")):
        try:
            for line in f.read_text().splitlines():
                if line.startswith("filesystems="):
                    shares += [fs_path(fs) for fs in line[len("filesystems="):].split(";") if fs]
        except OSError:
            pass
    return shares


def apps_lock():
    STATE.mkdir(parents=True, exist_ok=True)
    lock = open(STATE / "apptheme.lock", "w")
    fcntl.flock(lock, fcntl.LOCK_EX)
    return lock


def write_if_changed(path, text):
    try:
        if path.read_text() == text:
            return False
    except OSError:
        pass
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text)
    return True


def gtk_colors(p, light):
    named = {
        "accent_bg_color": p["primary"], "accent_fg_color": p["bright"] if light else p["surface"],
        "accent_color": p["primary"],
        "window_bg_color": p["surface_container_low"], "view_bg_color": p["surface"],
        "headerbar_bg_color": p["surface_container"], "headerbar_backdrop_color": p["surface_container_low"],
        "headerbar_border_color": p["outline_variant"],
        "sidebar_bg_color": p["surface_container"], "sidebar_backdrop_color": p["surface_container_low"],
        "secondary_sidebar_bg_color": p["surface_container_low"],
        "card_bg_color": p["surface_container_high"], "dialog_bg_color": p["surface_container_high"],
        "popover_bg_color": p["surface_container_high"], "thumbnail_bg_color": p["surface_container_high"],
    }
    for part in ("window", "view", "headerbar", "sidebar", "secondary_sidebar", "card", "dialog",
                 "popover", "thumbnail"):
        named[part + "_fg_color"] = p["cream"]
    return "".join(f"@define-color {k} {v};\n" for k, v in named.items())


def find_theme(name):
    for root in (Path("/usr/share/themes"), Path("/usr/local/share/themes"), THEMES):
        if (root / name / "gtk-3.0" / "gtk.css").is_file():
            return root / name
    return None


def base_theme(light):
    """Flatpak apps only see ~/.local/share/themes, so adw-gtk3 is mirrored there for the wrappers to import."""
    src = find_theme("adw-gtk3" if light else "adw-gtk3-dark")
    if not src:
        return None
    dst = THEMES / ("Quickshell-base" if light else "Quickshell-base-dark")
    css = dst / "gtk-3.0" / "gtk.css"
    if not css.is_file() or (src / "gtk-3.0" / "gtk.css").stat().st_mtime > css.stat().st_mtime:
        shutil.rmtree(dst, ignore_errors=True)
        shutil.copytree(src, dst)
    return dst.name


def enable_apps():
    state = {"gtk-theme": gget("gtk-theme"), "color-scheme": gget("color-scheme"),
             "backups": [], "flatpak": [], "notified": False}
    for d in [GTK4] + ([GTK3] if find_theme("adw-gtk3-dark") else []):
        css = d / "gtk.css"
        if css.is_file() and not css.read_text(errors="ignore").startswith(MARK):
            bak = next(b for b in [d / "gtk.css.bak"] + [d / f"gtk.css.bak.{n}" for n in range(1, 100)]
                       if not b.exists())
            css.rename(bak)
            state["backups"].append(str(bak))
    if shutil.which("flatpak"):
        have = flatpak_shares()
        state["flatpak"] = [fs for fs in FLATPAK_FS if fs_path(fs) not in have]
        if state["flatpak"]:
            subprocess.run(["flatpak", "override", "--user"]
                           + ["--filesystem=" + fs for fs in state["flatpak"]], capture_output=True)
    STATE.mkdir(parents=True, exist_ok=True)
    (STATE / "apptheme.json").write_text(json.dumps(state, indent=2) + "\n")


def remind_backups():
    """The first apply can run at login before the pill owns the notification bus, so the toast retries until it lands."""
    f = STATE / "apptheme.json"
    state = json.loads(f.read_text())
    if state.get("backups") and not state.get("notified") and notify(
            "App theme is on", "Your own gtk.css was moved to "
            + ", ".join(b.replace(str(Path.home()), "~") for b in state["backups"])
            + ". Turning App theme off puts it back."):
        state["notified"] = True
        f.write_text(json.dumps(state, indent=2) + "\n")


def apply_apps(p):
    """Theme GTK3 and GTK4 apps from the active bundle; the alternating Quickshell-a/b name makes running GTK3 apps reload."""
    if shutil.which("gsettings") is None:
        print("apptheme: app theme skipped: gsettings not found", file=sys.stderr)
        return
    if not (STATE / "apptheme.json").is_file():
        enable_apps()
    r, g, b = (int(p["surface"][i:i + 2], 16) / 255 for i in (1, 3, 5))
    light = colorsys.rgb_to_hls(r, g, b)[1] > 0.5
    colors = gtk_colors(p, light)
    root = ":root { --accent-bg-color: @accent_bg_color; --accent-fg-color: @accent_fg_color; --accent-color: %s; }\n"
    changed = write_if_changed(GTK4 / "quickshell.css", colors + root % p["primary"])
    if not (GTK4 / "gtk.css").exists():
        write_if_changed(GTK4 / "gtk.css", MARK + '@import url("quickshell.css");\n')
    base = base_theme(light)
    if base:
        css3 = MARK + f'@import url("../../{base}/gtk-3.0/gtk.css");\n' + colors
        current = gget("gtk-theme")
        try:
            same = current in QUICKSHELL_THEMES[:2] and (THEMES / current / "gtk-3.0" / "gtk.css").read_text() == css3
        except OSError:
            same = False
        if not same:
            target = "Quickshell-b" if current == "Quickshell-a" else "Quickshell-a"
            write_if_changed(THEMES / target / "gtk-3.0" / "gtk.css", css3)
            write_if_changed(THEMES / target / "gtk-4.0" / "gtk.css", f'@import url("../../{base}/gtk-4.0/gtk.css");\n')
            gset("gtk-theme", target)
            changed = True
    set_scheme("prefer-light" if light else "prefer-dark", changed)
    remind_backups()


def disable_apps():
    """Put the user's own GTK setup back; the stock light Linux default comes back dark to match the rice."""
    try:
        state = json.loads((STATE / "apptheme.json").read_text())
    except (OSError, ValueError):
        state = None
    css = GTK4 / "gtk.css"
    if css.is_file() and css.read_text(errors="ignore").startswith(MARK):
        css.unlink()
    (GTK4 / "quickshell.css").unlink(missing_ok=True)
    if state is None and gget("gtk-theme") not in QUICKSHELL_THEMES:
        return
    state = state or {}
    for bak in map(Path, state.get("backups", [])):
        if bak.is_file() and not (bak.parent / "gtk.css").exists():
            bak.rename(bak.parent / "gtk.css")
    theme = state.get("gtk-theme", "")
    if theme in ("", "Adwaita", *QUICKSHELL_THEMES):
        theme = "adw-gtk3-dark" if find_theme("adw-gtk3-dark") else "Adwaita-dark"
    gset("gtk-theme", theme)
    scheme = state.get("color-scheme", "")
    set_scheme("prefer-dark" if scheme in ("", "default") else scheme, True)
    for name in QUICKSHELL_THEMES:
        shutil.rmtree(THEMES / name, ignore_errors=True)
    if state.get("flatpak"):
        try:
            lines = OVERRIDES.read_text().splitlines()
            out = []
            for line in lines:
                if line.startswith("filesystems="):
                    keep = [fs for fs in line[len("filesystems="):].split(";") if fs and fs not in state["flatpak"]]
                    if not keep:
                        continue
                    line = "filesystems=" + ";".join(keep) + ";"
                out.append(line)
            if out == ["[Context]"]:
                OVERRIDES.unlink()
            else:
                OVERRIDES.write_text("\n".join(out) + "\n")
        except OSError:
            pass
    (STATE / "apptheme.json").unlink(missing_ok=True)


def sync_apps(pill):
    try:
        with apps_lock():
            apply_apps(active_palette(pill))
    except (OSError, ValueError, subprocess.SubprocessError) as exc:
        print(f"apptheme: app theme skipped: {exc}", file=sys.stderr)


def main():
    if sys.argv[1:3] == ["--apps", "off"]:
        with apps_lock():
            disable_apps()
        return 0
    if sys.argv[1:3] == ["--apps", "on"]:
        sync_apps(current_bundle() or DEFAULT_FALLBACK)
        return 0
    print("usage: apptheme.py --apps on|off", file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main())
