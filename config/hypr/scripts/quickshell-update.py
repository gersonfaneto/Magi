#!/usr/bin/env python3
"""Update face for the Quickshell Updates surface (config/quickshell/pill/Updates.qml).

Magi is a live git checkout rebuilt through `magi sync` (see README/AGENTS), not a
packaged install the shell can patch in place. So in-app updating is off: this
reports devmode, which makes the surface show the "Developer install" note and
points at git instead of offering buttons. The checkout's current commit rides
along as the version line.
"""

import json
import subprocess
from pathlib import Path

# hypr/scripts/quickshell-update.py -> config/hypr/scripts -> config -> checkout
CHECKOUT = Path(__file__).resolve().parents[2]


def git(*args):
    return subprocess.run(
        ["git", "-C", str(CHECKOUT), *args],
        capture_output=True,
        text=True,
        check=False,
    ).stdout.strip()


def main():
    out = {"status": "devmode"}
    sha = git("rev-parse", "--short", "HEAD")
    date = git("log", "-1", "--format=%cs")
    if sha:
        out["version"] = f"{sha} {date}"
    print(json.dumps(out))


if __name__ == "__main__":
    main()
