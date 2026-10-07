#!/usr/bin/env python3
"""Desaturate a copy of Papirus into the Mono icon themes.

Run by packages/mono-icons.nix on the two theme directories it copied out of
papirus-icon-theme. Every literal colour in an SVG becomes its luminance gray;
named colours and currentColor are left to the theme's own palette.
"""

import os
import re
import sys
from pathlib import Path

HEX = re.compile(r"#([0-9a-fA-F]{8}|[0-9a-fA-F]{6}|[0-9a-fA-F]{4}|[0-9a-fA-F]{3})\b")
RGB = re.compile(
    r"\brgba?\(\s*(\d{1,3})\s*,\s*(\d{1,3})\s*,\s*(\d{1,3})(?:\s*,\s*([0-9.]+))?\s*\)"
)


def gray_hex(value):
    digits = value
    if len(digits) in (3, 4):
        digits = "".join(ch * 2 for ch in digits)
    r, g, b = (int(digits[i : i + 2], 16) for i in (0, 2, 4))
    alpha = digits[6:8] if len(digits) == 8 else ""
    # ITU-R BT.601 luma, rounded; this keeps contrast ratios close to the
    # original while removing every hue.
    value = round(0.299 * r + 0.587 * g + 0.114 * b)
    return f"#{value:02x}{value:02x}{value:02x}{alpha}"


def gray_rgb(match):
    r, g, b, alpha = match.groups()
    value = round(0.299 * int(r) + 0.587 * int(g) + 0.114 * int(b))
    if alpha is None:
        return f"rgb({value}, {value}, {value})"
    return f"rgba({value}, {value}, {value}, {alpha})"


def gray_svg(path):
    text = path.read_text(errors="ignore")
    new = HEX.sub(lambda m: gray_hex(m.group(1)), text)
    new = RGB.sub(gray_rgb, new)
    if new != text:
        path.write_text(new)


def fix_links(root):
    """Papirus-Dark borrows files from its Papirus sibling; point those at Mono."""
    for dirpath, dirnames, filenames in os.walk(root, followlinks=False):
        for name in dirnames + filenames:
            path = Path(dirpath) / name
            if not path.is_symlink():
                continue
            target = os.readlink(path)
            if re.match(r"(?:\.\./)+Papirus(?:/|$)", target):
                path.unlink()
                path.symlink_to(target.replace("Papirus", "Mono", 1))


def main():
    for root in map(Path, sys.argv[1:]):
        fix_links(root)
        for path in root.rglob("*.svg"):
            if path.is_symlink():
                continue
            gray_svg(path)
        index = root / "index.theme"
        if index.is_file():
            text = index.read_text()
            text = re.sub(r"^Name=.*$", f"Name={root.name}", text, count=1, flags=re.M)
            index.write_text(text)


if __name__ == "__main__":
    main()
