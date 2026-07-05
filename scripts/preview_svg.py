#!/usr/bin/env python3
"""Render the normalized muscle data as an SVG to eyeball the conversion
(mirrors what the SwiftUI BodyFigure draws). Writes scripts/_bh/preview.svg."""
import re
from convert_muscle_paths import parse_muscles, convert_muscle, W

FW, FH = 200, 400          # per-figure draw size (1:2 like the source)
GAP = 40

GROUP = {
    "chest": 1, "biceps": 1, "triceps": 1, "forearm": 1, "deltoids": 1,
    "abs": 1, "obliques": 1, "quadriceps": 1, "hamstring": 1, "gluteal": 1,
    "calves": 1, "neck": 1, "trapezius": 1, "upper-back": 1, "lower-back": 1,
}


def scaled_d(tokstr, ox):
    out, toks, i = [], tokstr.split(" "), 0
    def num():
        nonlocal i
        v = float(toks[i]); i += 1
        return v
    while i < len(toks):
        c = toks[i]; i += 1
        if c in ("M", "L"):
            x = num() * FW + ox; y = num() * FH
            out.append(f"{c}{x:.2f} {y:.2f}")
        elif c == "C":
            vals = [num() for _ in range(6)]
            pts = []
            for k in range(0, 6, 2):
                pts.append(f"{vals[k]*FW+ox:.2f} {vals[k+1]*FH:.2f}")
            out.append("C" + " ".join(pts))
        elif c == "Z":
            out.append("Z")
    return " ".join(out)


def main():
    bh = "scripts/_bh"
    front = parse_muscles(open(f"{bh}/bodyFront.ts").read())
    back = parse_muscles(open(f"{bh}/bodyBack.ts").read())
    wrapper = open(f"{bh}/wrapper.tsx").read()
    outlines = re.findall(r'd="([^"]+)"', wrapper)
    front_outline = convert_muscle([outlines[0]], 0)
    back_outline = convert_muscle([outlines[1]], W)

    vw = FW * 2 + GAP
    svg = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {vw} {FH}">']
    svg.append(f'<rect width="{vw}" height="{FH}" fill="#0a0a0a"/>')

    for outline_str, muscles, ox in [
        (front_outline, front, 0),
        (back_outline, back, FW + GAP),
    ]:
        svg.append(f'<path d="{scaled_d(outline_str, ox)}" fill="#1f1f1f" stroke="#444" stroke-width="1"/>')
        for slug, paths in muscles:
            d = scaled_d(convert_muscle(paths, 0 if ox == 0 else W), ox)
            fill = "#3a3a3a" if slug in GROUP else "#2a2a2a"
            svg.append(f'<path d="{d}" fill="{fill}" stroke="#5a5a5a" stroke-width="0.5"/>')
    svg.append("</svg>")
    open(f"{bh}/preview.svg", "w").write("\n".join(svg))
    print(f"wrote {bh}/preview.svg")


if __name__ == "__main__":
    main()
