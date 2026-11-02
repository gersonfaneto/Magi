#!/usr/bin/env python3
"""Deprecated name for the theme pipeline.

Kept so an old keybind or hook that still calls quickshell-theme.py keeps
working; new code should use theme.py, which owns apply/render/status/check.
"""
import sys

from theme import main

if __name__ == "__main__":
    if len(sys.argv) == 1:
        sys.argv.append("apply")
    sys.exit(main())
