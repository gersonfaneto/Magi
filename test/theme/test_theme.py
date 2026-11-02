"""Build-time checks for the palette generator and template renderer.

Run with the repository root as the only argument. It builds every Nix-owned
bundle, renders every registered template against each one, and fails on an
unknown token, a leftover placeholder or a missing scheme variant.
"""

import contextlib
import io
import json
import re
import subprocess
import sys
import tempfile
from pathlib import Path

root = Path(sys.argv[1]).resolve()
scripts = root / "config" / "hypr" / "scripts"
sys.path.insert(0, str(scripts))

import theme as pipeline  # noqa: E402
from themelib import load_registry  # noqa: E402

templates = sorted(root.glob("config/**/*.template.*"))

errors = []


def fail(message):
    errors.append(message)


if not templates:
    fail("no templates found")


registry_path = root / "config/theme/schemes.json"
try:
    registry = load_registry(registry_path)
except SystemExit as exc:
    fail(str(exc))
    print("\n".join(errors), file=sys.stderr)
    raise SystemExit(1)

schemes = registry["schemes"]

tones = {}
for name in schemes:
    tones[name] = [
        mode
        for mode in ("dark", "light")
        if (root / "config/theme/themes" / f"{name}-{mode}.toml").is_file()
    ]
    if not tones[name]:
        fail(f"missing scheme: config/theme/themes/{name}-dark.toml")

# Every selectable scheme needs a bundled wallpaper: theme.py applies the
# first file in that directory on a scheme switch.
wallpaper_root = root / "assets" / "wallpapers"
original_wallpapers = pipeline.WALLPAPERS
pipeline.WALLPAPERS = wallpaper_root
try:
    for name in schemes:
        folder = wallpaper_root / name
        files = sorted(
            path
            for path in folder.iterdir()
            if path.is_file() and path.suffix.lower() in pipeline.WALLPAPER_SUFFIXES
        ) if folder.is_dir() else []
        if not files:
            fail(f"missing theme wallpaper: {folder}")
        elif pipeline.default_wallpaper(name) != files[0]:
            fail(f"default wallpaper does not pick the first file: {folder}")
finally:
    pipeline.WALLPAPERS = original_wallpapers

for path in templates:
    if not path.is_file():
        fail(f"missing template: {path}")

with tempfile.TemporaryDirectory() as tmp:
    out = Path(tmp)
    subprocess.run(
        [
            sys.executable,
            str(scripts / "quickshell-palette.py"),
            "--themes",
            str(root / "config/theme/themes"),
            "--schemes",
            str(registry_path),
            "--out",
            str(out),
        ],
        check=True,
        stdout=subprocess.DEVNULL,
    )

    bundles = sorted(out.glob("*.json"))
    expected = sum(len(modes) for modes in tones.values())
    if len(bundles) != expected:
        fail(f"generated {len(bundles)} bundles, expected {expected}")

    for bundle_path in bundles:
        bundle = json.loads(bundle_path.read_text())
        for role in ("background", "surface", "primary", "cream", "tone", "editor"):
            if role not in bundle:
                fail(f"{bundle_path.name}: missing {role}")
        terminal = bundle.get("terminal") or {}
        if len(terminal.get("ansi") or []) != 16:
            fail(f"{bundle_path.name}: terminal needs 16 ANSI colours")
        foot = out / "foot" / f"{bundle['key']}.ini"
        if not foot.is_file():
            fail(f"{foot.name}: missing generated foot palette")
        elif len(re.findall(r"^(?:regular|bright)\d=", foot.read_text(), re.M)) != 16:
            fail(f"{foot.name}: expected 16 generated ANSI slots")
        for template in templates:
            if not template.is_file():
                continue
            try:
                text = pipeline.render(template.read_text(), bundle)
            except Exception as exc:  # noqa: BLE001 - report every template
                fail(f"{template.name} with {bundle_path.name}: {exc}")
                continue
            if "{{" in text:
                fail(f"{template.name} with {bundle_path.name}: leftover token")

    # A runtime bundle may still be older than the current manifest;
    # complete_bundle has to fill shared template roles or a theme switch
    # breaks rendering.
    seed = json.loads(bundles[0].read_text())
    runtime = {
        "key": "runtime",
        "source": "scheme",
        "scheme": "nano",
        "tone": "dark",
        "editor": "generated",
        "surface": "#101010",
        "surface_container": "#181818",
        "primary": "#e0563b",
        "primary_container": "#7a2a1a",
        "on_primary_container": "#ffb38a",
        "cream": "#e6d6cb",
        "terminal": seed["terminal"],
    }
    runtime = pipeline.complete_bundle(runtime)
    for template in templates:
        if not template.is_file():
            continue
        try:
            pipeline.render(template.read_text(), runtime)
        except Exception as exc:  # noqa: BLE001
            fail(f"{template.name} with a runtime bundle: {exc}")

    # Two targets writing the same file (or into the live checkout) would make
    # the renderer's result depend on Nix attribute ordering.
    probe_template = templates[0] if templates else root / "config/theme/qtct.template.conf"
    original_manifest = pipeline.MANIFEST
    try:
        duplicate = out / "duplicate-manifest.json"
        duplicate.write_text(
            json.dumps(
                [
                    {
                        "name": "one",
                        "input_path": str(probe_template),
                        "output_path": str(out / "same"),
                    },
                    {
                        "name": "two",
                        "input_path": str(probe_template),
                        "output_path": str(out / "same"),
                    },
                ]
            )
        )
        pipeline.MANIFEST = duplicate
        try:
            pipeline.manifest_entries()
        except pipeline.ThemeError:
            pass
        else:
            fail("duplicate output paths did not raise")

        inside = out / "inside-manifest.json"
        inside.write_text(
            json.dumps(
                [
                    {
                        "name": "inside",
                        "input_path": str(probe_template),
                        "output_path": str(root / "config" / "generated"),
                    }
                ]
            )
        )
        pipeline.MANIFEST = inside
        try:
            pipeline.manifest_entries()
        except pipeline.ThemeError:
            pass
        else:
            fail("output inside the checkout did not raise")
    finally:
        pipeline.MANIFEST = original_manifest

    # Old palette modes and manual controls are gone. read_flags drops them
    # from the persisted file so the Quickshell adapter cannot keep reading a
    # removed mode.
    original_flags = pipeline.FLAGS
    try:
        for legacy in ("static", "manual", "dynamic"):
            flags_path = out / f"{legacy}-flags.json"
            flags_path.write_text(
                json.dumps(
                    {
                        "paletteMode": legacy,
                        "scheme": "nano",
                        "bg": "dark",
                        "manualHue": 30,
                        "manualDark": True,
                        "manualSat": 0.5,
                    }
                )
            )
            pipeline.FLAGS = flags_path
            migrated = pipeline.read_flags()
            persisted = json.loads(flags_path.read_text())
            if migrated.get("scheme") != "nano" or persisted.get("scheme") != "nano":
                fail(f"{legacy} migration lost the scheme")
            for key in pipeline.REMOVED_FLAGS:
                if key in migrated or key in persisted:
                    fail(f"{legacy} migration kept {key}")
    finally:
        pipeline.FLAGS = original_flags

    with contextlib.redirect_stderr(io.StringIO()):
        try:
            pipeline.main(["source", "dynamic"])
        except SystemExit:
            pass
        else:
            fail("source command still exists")

    # The Quickshell picker reads this catalog instead of parsing TOMLs itself.
    original_palettes = pipeline.PALETTES
    try:
        pipeline.PALETTES = out
        captured = io.StringIO()
        with contextlib.redirect_stdout(captured):
            pipeline.cmd_catalog(None)
        catalog = json.loads(captured.getvalue())
        if len(catalog.get("themes") or []) != len(schemes):
            fail("theme catalog has the wrong scheme count")
        for theme in catalog.get("themes") or []:
            if not theme.get("tones"):
                fail(f"theme catalog: {theme.get('name')} has no tones")
            for tone in theme.get("tones") or []:
                for role in ("tone", "background", "surface", "primary", "cream"):
                    if not tone.get(role):
                        fail(f"theme catalog: {theme.get('name')} missing {role}")
    finally:
        pipeline.PALETTES = original_palettes

    # Unknown roles must fail loudly rather than reach a config file.
    try:
        pipeline.render("{{colors.not_a_role.hex}}", json.loads(bundles[0].read_text()))
    except pipeline.ThemeError:
        pass
    else:
        fail("unknown role did not raise")

    # Only the TUI handles SIGUSR2; the service and one-shot subcommands must
    # not be signalled, or they would take the default action and die.
    for args, expected in (
        (["/usr/bin/opencode2"], True),
        (["/usr/bin/opencode2", "--standalone"], True),
        (["/usr/bin/.opencode2-wrapped"], True),
        (["/usr/bin/opencode2", "serve", "--service"], False),
        (["/usr/bin/opencode2", "run", "hello"], False),
        (["/usr/bin/zsh"], False),
        ([], False),
    ):
        if pipeline.is_opencode_tui(args) != expected:
            fail(f"opencode TUI detection wrong for {args!r}")

if errors:
    print("\n".join(errors), file=sys.stderr)
    raise SystemExit(1)

print(f"theme: {len(bundles)} bundles, {len(templates)} templates ok")
