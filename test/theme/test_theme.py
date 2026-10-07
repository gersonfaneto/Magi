"""Build-time checks for the mono palette generator and template renderer.

Run with the repository root as the only argument. It builds both tone bundles,
renders every registered template against each one, and fails on an unknown
token, a leftover placeholder, a non-gray colour or a missing mono asset.
"""

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

# In a Nix sandbox the checkout is copied away from /etc/magi, so the real
# template write guard has to point at the tree this test was handed.
pipeline.CONFIG_ROOT = root

templates = sorted(root.glob("config/**/*.template.*"))
tones = ("dark", "light")
errors = []

COLOR = re.compile(r"#[0-9a-fA-F]{6}")


def fail(message):
    errors.append(message)


def is_gray(value):
    r, g, b = (int(value[i : i + 2], 16) for i in (1, 3, 5))
    return r == g == b


if not templates:
    fail("no templates found")

for tone in tones:
    relative = f"config/foot/themes/mono-{tone}.ini"
    if not (root / relative).is_file():
        fail(f"missing mono asset: {relative}")

for path in templates:
    if not path.is_file():
        fail(f"missing template: {path}")

with tempfile.TemporaryDirectory() as tmp:
    out = Path(tmp)
    subprocess.run(
        [
            sys.executable,
            str(scripts / "palette.py"),
            "--themes",
            str(root / "config/foot/themes"),
            "--out",
            str(out),
        ],
        check=True,
        stdout=subprocess.DEVNULL,
    )

    bundles = sorted(out.glob("*.json"))
    expected = [f"mono-{tone}.json" for tone in tones]
    if [path.name for path in bundles] != expected:
        fail(f"generated {[p.name for p in bundles]}, expected {expected}")

    for bundle_path in bundles:
        bundle = json.loads(bundle_path.read_text())
        tone = bundle_path.stem.removeprefix("mono-")
        if bundle.get("key") != bundle_path.stem:
            fail(f"{bundle_path.name}: key is {bundle.get('key')!r}")
        if bundle.get("tone") != tone:
            fail(f"{bundle_path.name}: tone is {bundle.get('tone')!r}")
        for role in ("background", "surface", "primary", "cream", "tone", "editor"):
            if role not in bundle:
                fail(f"{bundle_path.name}: missing {role}")
        terminal = bundle.get("terminal") or {}
        if len(terminal.get("ansi") or []) != 16:
            fail(f"{bundle_path.name}: terminal needs 16 ANSI colours")

        # The whole point of the theme: every colour is a shade of gray.
        for value in COLOR.findall(bundle_path.read_text()):
            if not is_gray(value):
                fail(f"{bundle_path.name}: non-gray colour {value}")

        for template in templates:
            try:
                text = pipeline.render(template.read_text(), bundle)
            except Exception as exc:  # noqa: BLE001 - report every template
                fail(f"{template.name} with {bundle_path.name}: {exc}")
                continue
            if "{{" in text:
                fail(f"{template.name} with {bundle_path.name}: leftover token")

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

        # scopes are still part of the manifest format, even though both ends
        # now render the same mono bundle.
        bundle = json.loads((out / "mono-dark.json").read_text())
        scope_template = out / "scope.template"
        scope_template.write_text("{{colors.primary.hex}}")
        scoped = out / "scoped-manifest.json"
        scoped.write_text(
            json.dumps(
                [
                    {
                        "name": "desktop",
                        "input_path": str(scope_template),
                        "output_path": str(out / "desktop.out"),
                    },
                    {
                        "name": "terminal",
                        "input_path": str(scope_template),
                        "output_path": str(out / "terminal.out"),
                        "scope": "terminal",
                    },
                ]
            )
        )
        pipeline.MANIFEST = scoped
        pipeline.render_manifest(bundle)
        for name in ("desktop.out", "terminal.out"):
            if (out / name).read_text() != bundle["primary"]:
                fail(f"{name} did not use the mono bundle")

        unknown = out / "unknown-scope-manifest.json"
        unknown.write_text(
            json.dumps(
                [
                    {
                        "name": "unknown",
                        "input_path": str(scope_template),
                        "output_path": str(out / "unknown.out"),
                        "scope": "shell",
                    }
                ]
            )
        )
        pipeline.MANIFEST = unknown
        try:
            pipeline.manifest_entries()
        except pipeline.ThemeError:
            pass
        else:
            fail("unknown scope did not raise")
    finally:
        pipeline.MANIFEST = original_manifest

    # The old registry flags are gone; bg survives, and app theming is on by
    # default so a fresh checkout matches the rice.
    original_flags = pipeline.FLAGS
    try:
        flags_path = out / "legacy-flags.json"
        flags_path.write_text(
            json.dumps(
                {
                    "paletteMode": "scheme",
                    "scheme": "nano",
                    "bg": "light",
                    "appTheme": False,
                    "manualHue": 30,
                    "manualDark": True,
                    "manualSat": 0.5,
                    "wallpaperFit": "cover",
                }
            )
        )
        pipeline.FLAGS = flags_path
        migrated = pipeline.read_flags()
        if migrated["bg"] != "light":
            fail("migration lost the background tone")
        if migrated["appTheme"] is not True:
            fail("app theming did not default on")
        if migrated.get("wallpaperFit") != "cover":
            fail("migration dropped an unrelated flag")
        for key in pipeline.REMOVED_FLAGS:
            if key in migrated:
                fail(f"migration kept {key}")
    finally:
        pipeline.FLAGS = original_flags

    if pipeline.bundle_key({"bg": "dark"}) != "mono-dark":
        fail("dark background does not resolve mono-dark")
    if pipeline.bundle_key({"bg": "light"}) != "mono-light":
        fail("light background does not resolve mono-light")

    # Unknown roles must fail loudly rather than reach a config file.
    try:
        pipeline.render("{{colors.not_a_role.hex}}", json.loads(bundles[0].read_text()))
    except pipeline.ThemeError:
        pass
    else:
        fail("unknown role did not raise")

if errors:
    print("\n".join(errors), file=sys.stderr)
    raise SystemExit(1)

print(f"theme: {len(bundles)} bundles, {len(templates)} templates ok")
