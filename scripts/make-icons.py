#!/usr/bin/env python3
"""Regenerates every PNG icon from the SVG artwork in design/.

The PNGs are committed to the repository, so this only needs to be run after
the artwork changes. It needs `rsvg-convert` (macOS: `brew install librsvg`).

    python3 scripts/make-icons.py
"""

import json
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DESIGN = ROOT / "design"
EXTENSION_ICONS = ROOT / "safari-extension" / "icons"
APP_ICONSET = ROOT / "macos-app" / "App" / "Assets.xcassets" / "AppIcon.appiconset"

EXTENSION_SIZES = [48, 96, 128, 256, 512]
TOOLBAR_SIZES = [16, 19, 32, 38, 48, 72]

# (point size, scale) pairs macOS expects for an app icon.
APP_ICON_SLOTS = [
    (16, 1), (16, 2),
    (32, 1), (32, 2),
    (128, 1), (128, 2),
    (256, 1), (256, 2),
    (512, 1), (512, 2),
]


def render(svg: Path, size: int, out: Path) -> None:
    out.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(
        ["rsvg-convert", "--width", str(size), "--height", str(size), "--output", str(out), str(svg)],
        check=True,
    )


def main() -> int:
    if shutil.which("rsvg-convert") is None:
        print("error: rsvg-convert not found. On macOS run: brew install librsvg", file=sys.stderr)
        return 1

    for size in EXTENSION_SIZES:
        render(DESIGN / "extension-icon.svg", size, EXTENSION_ICONS / f"icon-{size}.png")
    for size in TOOLBAR_SIZES:
        render(DESIGN / "toolbar-icon.svg", size, EXTENSION_ICONS / f"toolbar-{size}.png")

    images = []
    for points, scale in APP_ICON_SLOTS:
        pixels = points * scale
        filename = f"icon_{pixels}.png"
        render(DESIGN / "app-icon.svg", pixels, APP_ICONSET / filename)
        images.append(
            {
                "filename": filename,
                "idiom": "mac",
                "scale": f"{scale}x",
                "size": f"{points}x{points}",
            }
        )

    contents = {"images": images, "info": {"author": "xcode", "version": 1}}
    (APP_ICONSET / "Contents.json").write_text(json.dumps(contents, indent=2) + "\n")
    (APP_ICONSET.parent / "Contents.json").write_text(
        json.dumps({"info": {"author": "xcode", "version": 1}}, indent=2) + "\n"
    )

    print("Icons regenerated.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
