"""Build-time checks for the palette generator and template renderer.

Run with the repository root as the only argument. It builds every Nix-owned
bundle, renders every registered template against each one, and fails on an
unknown token, a leftover placeholder or a missing scheme variant.
"""

import json
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

schemes = {
    name: spec
    for name, spec in registry["schemes"].items()
    if not spec.get("identity")
}

for name in schemes:
    for mode in ("dark", "light"):
        path = root / "config/foot/themes" / f"{name}-{mode}.ini"
        if not path.is_file():
            fail(f"missing foot scheme: {path}")
        path = root / "config/highlight/themes" / f"{name}-{mode}.theme"
        if not path.is_file():
            fail(f"missing highlight scheme: {path}")

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
            str(root / "config/foot/themes"),
            "--schemes",
            str(registry_path),
            "--out",
            str(out),
        ],
        check=True,
        stdout=subprocess.DEVNULL,
    )

    bundles = sorted(out.glob("*.json"))
    if len(bundles) != 1 + len(schemes) * 2:
        fail(f"generated {len(bundles)} bundles, expected {1 + len(schemes) * 2}")

    for bundle_path in bundles:
        bundle = json.loads(bundle_path.read_text())
        for role in ("background", "surface", "primary", "cream", "tone", "editor"):
            if role not in bundle:
                fail(f"{bundle_path.name}: missing {role}")
        terminal = bundle.get("terminal") or {}
        if len(terminal.get("ansi") or []) != 16:
            fail(f"{bundle_path.name}: terminal needs 16 ANSI colours")
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

    # wallcolors.py only emits the shell tokens; complete_bundle has to fill
    # the shared template roles or a wallpaper switch breaks rendering.
    seed = json.loads(bundles[0].read_text())
    runtime = {
        "key": "dynamic",
        "source": "dynamic",
        "scheme": "dynamic",
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

    # Legacy static/manual modes collapse to scheme and are persisted so the
    # Quickshell adapter does not keep reading a removed mode.
    original_flags = pipeline.FLAGS
    try:
        for legacy in ("static", "manual"):
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
            if migrated["paletteMode"] != "scheme":
                fail(f"{legacy} palette mode did not migrate")
            if persisted["paletteMode"] != "scheme":
                fail(f"{legacy} palette mode was not persisted")
            for key in pipeline.REMOVED_FLAGS:
                if key in migrated or key in persisted:
                    fail(f"{legacy} migration kept {key}")
    finally:
        pipeline.FLAGS = original_flags

    for mode in ("static", "manual"):
        try:
            pipeline.bundle_key({"paletteMode": mode})
        except pipeline.ThemeError:
            pass
        else:
            fail(f"{mode} mode still resolves a bundle")

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
