"""Generate a 1024x1024 AppIcon PNG: white dumbbell on pure black.

Output:
    WorkoutTracker/Assets.xcassets/AppIcon.appiconset/icon.png

Run from the repo root with Python 3 + Pillow installed.
"""

import os
from pathlib import Path
from PIL import Image, ImageDraw


SIZE = 1024
OUT = Path(__file__).resolve().parent.parent / "WorkoutTracker" / "Assets.xcassets" / "AppIcon.appiconset" / "icon.png"


def draw_icon() -> Image.Image:
    img = Image.new("RGB", (SIZE, SIZE), (0, 0, 0))
    draw = ImageDraw.Draw(img)

    cy = SIZE / 2
    handle_left = SIZE * 0.30
    handle_right = SIZE * 0.70
    handle_h = SIZE * 0.06
    handle_radius = handle_h * 0.4

    # Handle bar
    draw.rounded_rectangle(
        [handle_left, cy - handle_h / 2, handle_right, cy + handle_h / 2],
        radius=handle_radius,
        fill=(255, 255, 255),
    )

    # Plates — rounded rectangles flanking the handle
    plate_w = SIZE * 0.11
    plate_h = SIZE * 0.34
    plate_radius = SIZE * 0.045
    inner_gap = SIZE * 0.02

    # Outer plate (thicker)
    outer_w = plate_w
    # Inner plate (thinner, tucked next to the bar)
    inner_w = SIZE * 0.05
    inner_h = SIZE * 0.22

    # Left side
    draw.rounded_rectangle(
        [handle_left - inner_w - inner_gap - outer_w,
         cy - plate_h / 2,
         handle_left - inner_w - inner_gap,
         cy + plate_h / 2],
        radius=plate_radius,
        fill=(255, 255, 255),
    )
    draw.rounded_rectangle(
        [handle_left - inner_w,
         cy - inner_h / 2,
         handle_left,
         cy + inner_h / 2],
        radius=plate_radius * 0.7,
        fill=(255, 255, 255),
    )

    # Right side (mirror)
    draw.rounded_rectangle(
        [handle_right + inner_w + inner_gap,
         cy - plate_h / 2,
         handle_right + inner_w + inner_gap + outer_w,
         cy + plate_h / 2],
        radius=plate_radius,
        fill=(255, 255, 255),
    )
    draw.rounded_rectangle(
        [handle_right,
         cy - inner_h / 2,
         handle_right + inner_w,
         cy + inner_h / 2],
        radius=plate_radius * 0.7,
        fill=(255, 255, 255),
    )

    return img


def main() -> None:
    OUT.parent.mkdir(parents=True, exist_ok=True)
    img = draw_icon()
    img.save(OUT, "PNG", optimize=True)
    print(f"Wrote {OUT} ({os.path.getsize(OUT)} bytes)")


if __name__ == "__main__":
    main()
