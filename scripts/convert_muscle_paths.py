#!/usr/bin/env python3
"""Convert react-native-body-highlighter SVG muscle data (MIT, (c) 2022
ELABBASSI Hicham) into a compact normalized path format for SwiftUI.

Output: one Swift file with M/L/C/Z absolute commands, coordinates
normalized to the source viewBox (724 x 1448, aspect 0.5). The Swift side
only has to parse four commands, so correctness lives here where we can test.

Run from the repo root. First fetch the source data into scripts/_bh/:
    base=https://raw.githubusercontent.com/HichamELBSI/react-native-body-highlighter/main
    curl -o scripts/_bh/bodyFront.ts  $base/assets/bodyFront.ts
    curl -o scripts/_bh/bodyBack.ts   $base/assets/bodyBack.ts
    curl -o scripts/_bh/wrapper.tsx   $base/components/SvgMaleWrapper.tsx
Then:  python scripts/convert_muscle_paths.py
"""
import re
import math
import sys

W = 724.0
H = 1448.0
FLOAT_RE = re.compile(r'[+-]?(?:\d*\.\d+|\d+\.?\d*)(?:[eE][+-]?\d+)?')


class Scanner:
    def __init__(self, s):
        self.s = s
        self.i = 0

    def skip(self):
        while self.i < len(self.s) and self.s[self.i] in ' ,\t\n\r':
            self.i += 1

    def eof(self):
        self.skip()
        return self.i >= len(self.s)

    def flag(self):
        self.skip()
        ch = self.s[self.i]
        self.i += 1
        return 1 if ch == '1' else 0

    def num(self):
        self.skip()
        m = FLOAT_RE.match(self.s, self.i)
        if not m:
            raise ValueError(f"expected number at {self.i!r}: {self.s[self.i:self.i+12]!r}")
        self.i = m.end()
        return float(m.group())


def quad_to_cubic(x0, y0, qx, qy, x, y):
    c1x = x0 + 2.0 / 3.0 * (qx - x0)
    c1y = y0 + 2.0 / 3.0 * (qy - y0)
    c2x = x + 2.0 / 3.0 * (qx - x)
    c2y = y + 2.0 / 3.0 * (qy - y)
    return ('C', c1x, c1y, c2x, c2y, x, y)


def arc_to_cubics(x1, y1, rx, ry, phi_deg, large, sweep, x2, y2):
    if rx == 0 or ry == 0 or (x1 == x2 and y1 == y2):
        return [('C', x1, y1, x2, y2, x2, y2)]
    phi = math.radians(phi_deg % 360.0)
    cosp, sinp = math.cos(phi), math.sin(phi)
    dx = (x1 - x2) / 2.0
    dy = (y1 - y2) / 2.0
    x1p = cosp * dx + sinp * dy
    y1p = -sinp * dx + cosp * dy
    rx, ry = abs(rx), abs(ry)
    lam = (x1p * x1p) / (rx * rx) + (y1p * y1p) / (ry * ry)
    if lam > 1:
        s = math.sqrt(lam)
        rx *= s
        ry *= s
    den = rx * rx * y1p * y1p + ry * ry * x1p * x1p
    num = rx * rx * ry * ry - den
    co = 0.0 if den == 0 else math.sqrt(max(0.0, num / den))
    if large == sweep:
        co = -co
    cxp = co * (rx * y1p / ry)
    cyp = co * (-ry * x1p / rx)
    cx = cosp * cxp - sinp * cyp + (x1 + x2) / 2.0
    cy = sinp * cxp + cosp * cyp + (y1 + y2) / 2.0

    def ang(ux, uy, vx, vy):
        dot = ux * vx + uy * vy
        n = math.hypot(ux, uy) * math.hypot(vx, vy)
        a = math.acos(max(-1.0, min(1.0, dot / n))) if n else 0.0
        return -a if (ux * vy - uy * vx) < 0 else a

    ux, uy = (x1p - cxp) / rx, (y1p - cyp) / ry
    vx, vy = (-x1p - cxp) / rx, (-y1p - cyp) / ry
    theta1 = ang(1, 0, ux, uy)
    dtheta = ang(ux, uy, vx, vy)
    if not sweep and dtheta > 0:
        dtheta -= 2 * math.pi
    if sweep and dtheta < 0:
        dtheta += 2 * math.pi

    nseg = max(1, int(math.ceil(abs(dtheta) / (math.pi / 2.0))))
    delta = dtheta / nseg
    t = (4.0 / 3.0) * math.tan(delta / 4.0)

    def point(th):
        return (cosp * rx * math.cos(th) - sinp * ry * math.sin(th) + cx,
                sinp * rx * math.cos(th) + cosp * ry * math.sin(th) + cy)

    def deriv(th):
        return (-cosp * rx * math.sin(th) - sinp * ry * math.cos(th),
                -sinp * rx * math.sin(th) + cosp * ry * math.cos(th))

    out = []
    th = theta1
    px, py = point(th)
    for _ in range(nseg):
        th2 = th + delta
        ex, ey = point(th2)
        d1x, d1y = deriv(th)
        d2x, d2y = deriv(th2)
        out.append(('C', px + t * d1x, py + t * d1y, ex - t * d2x, ey - t * d2y, ex, ey))
        px, py, th = ex, ey, th2
    return out


def to_abs(d):
    parts = re.findall(r'([MmLlHhVvCcSsQqTtAaZz])([^MmLlHhVvCcSsQqTtAaZz]*)', d)
    segs = []
    cx = cy = sx = sy = 0.0
    last_curve = None       # 'C', 'Q', or None
    prev_c2 = prev_q = None
    for letter, param in parts:
        rel = letter.islower()
        L = letter.upper()
        sc = Scanner(param)
        if L == 'Z':
            segs.append(('Z',))
            cx, cy = sx, sy
            last_curve = None
            continue
        if L == 'M':
            x = sc.num(); y = sc.num()
            if rel: x += cx; y += cy
            segs.append(('M', x, y)); sx, sy = x, y; cx, cy = x, y
            last_curve = None
            while not sc.eof():
                x = sc.num(); y = sc.num()
                if rel: x += cx; y += cy
                segs.append(('L', x, y)); cx, cy = x, y
            continue
        while not sc.eof():
            if L == 'L':
                x = sc.num(); y = sc.num()
                if rel: x += cx; y += cy
                segs.append(('L', x, y)); cx, cy = x, y; last_curve = None
            elif L == 'H':
                x = sc.num()
                if rel: x += cx
                segs.append(('L', x, cy)); cx = x; last_curve = None
            elif L == 'V':
                y = sc.num()
                if rel: y += cy
                segs.append(('L', cx, y)); cy = y; last_curve = None
            elif L == 'C':
                x1 = sc.num(); y1 = sc.num(); x2 = sc.num(); y2 = sc.num(); x = sc.num(); y = sc.num()
                if rel: x1 += cx; y1 += cy; x2 += cx; y2 += cy; x += cx; y += cy
                segs.append(('C', x1, y1, x2, y2, x, y)); cx, cy = x, y
                prev_c2 = (x2, y2); last_curve = 'C'
            elif L == 'S':
                x2 = sc.num(); y2 = sc.num(); x = sc.num(); y = sc.num()
                if rel: x2 += cx; y2 += cy; x += cx; y += cy
                if last_curve == 'C' and prev_c2:
                    x1 = 2 * cx - prev_c2[0]; y1 = 2 * cy - prev_c2[1]
                else:
                    x1, y1 = cx, cy
                segs.append(('C', x1, y1, x2, y2, x, y)); cx, cy = x, y
                prev_c2 = (x2, y2); last_curve = 'C'
            elif L == 'Q':
                qx = sc.num(); qy = sc.num(); x = sc.num(); y = sc.num()
                if rel: qx += cx; qy += cy; x += cx; y += cy
                segs.append(quad_to_cubic(cx, cy, qx, qy, x, y)); cx, cy = x, y
                prev_q = (qx, qy); last_curve = 'Q'
            elif L == 'T':
                x = sc.num(); y = sc.num()
                if rel: x += cx; y += cy
                if last_curve == 'Q' and prev_q:
                    qx = 2 * cx - prev_q[0]; qy = 2 * cy - prev_q[1]
                else:
                    qx, qy = cx, cy
                segs.append(quad_to_cubic(cx, cy, qx, qy, x, y)); cx, cy = x, y
                prev_q = (qx, qy); last_curve = 'Q'
            elif L == 'A':
                rx = sc.num(); ry = sc.num(); rot = sc.num()
                large = sc.flag(); sweep = sc.flag()
                x = sc.num(); y = sc.num()
                if rel: x += cx; y += cy
                segs.extend(arc_to_cubics(cx, cy, rx, ry, rot, large, sweep, x, y))
                cx, cy = x, y; last_curve = None
            else:
                raise ValueError(f"unhandled command {L}")
    return segs


def fmt(v):
    s = f"{v:.4f}".rstrip('0').rstrip('.')
    return '0' if s in ('', '-0') else s


def emit(segs, xoff):
    out = []
    for s in segs:
        if s[0] == 'Z':
            out.append('Z'); continue
        nums = s[1:]
        toks = [s[0]]
        for i in range(0, len(nums), 2):
            toks.append(fmt((nums[i] - xoff) / W))
            toks.append(fmt(nums[i + 1] / H))
        out.append(' '.join(toks))
    return ' '.join(out)


def parse_muscles(ts):
    blocks = re.split(r'slug:\s*', ts)[1:]
    muscles = []
    for b in blocks:
        slug = re.match(r'"([^"]+)"', b).group(1)
        paths = [p for p in re.findall(r'"([^"]*)"', b) if p[:1] in ('M', 'm')]
        muscles.append((slug, paths))
    return muscles


def convert_muscle(paths, xoff):
    pieces = []
    for d in paths:
        pieces.append(emit(to_abs(d), xoff))
    return ' '.join(pieces)


def bounds(path_str):
    toks = path_str.split(' ')
    xs, ys = [], []
    i = 0
    while i < len(toks):
        t = toks[i]
        if t in ('M', 'L'):
            xs.append(float(toks[i + 1])); ys.append(float(toks[i + 2])); i += 3
        elif t == 'C':
            for k in range(3):
                xs.append(float(toks[i + 1 + 2 * k])); ys.append(float(toks[i + 2 + 2 * k]))
            i += 7
        else:
            i += 1
    return (min(xs), max(xs), min(ys), max(ys)) if xs else (0, 0, 0, 0)


def main():
    bh = "scripts/_bh"
    front_ts = open(f"{bh}/bodyFront.ts").read()
    back_ts = open(f"{bh}/bodyBack.ts").read()
    wrapper = open(f"{bh}/wrapper.tsx").read()

    front = parse_muscles(front_ts)
    back = parse_muscles(back_ts)

    outlines = re.findall(r'd="([^"]+)"', wrapper)
    # Two outlines in wrapper: front first, back second.
    front_outline = convert_muscle([outlines[0]], 0)
    back_outline = convert_muscle([outlines[1]], W)

    front_conv = [(slug, convert_muscle(paths, 0)) for slug, paths in front]
    back_conv = [(slug, convert_muscle(paths, W)) for slug, paths in back]

    # Sanity: report normalized bounds.
    allb = [bounds(p) for _, p in front_conv + back_conv] + [bounds(front_outline), bounds(back_outline)]
    gminx = min(b[0] for b in allb); gmaxx = max(b[1] for b in allb)
    gminy = min(b[2] for b in allb); gmaxy = max(b[3] for b in allb)
    sys.stderr.write(f"normalized bounds x[{gminx:.3f},{gmaxx:.3f}] y[{gminy:.3f},{gmaxy:.3f}]\n")
    sys.stderr.write(f"front muscles: {len(front_conv)}, back muscles: {len(back_conv)}\n")

    def swift_array(name, items):
        lines = [f"    static let {name}: [(String, String)] = ["]
        for slug, path in items:
            lines.append(f'        ("{slug}", "{path}"),')
        lines.append("    ]")
        return "\n".join(lines)

    out = []
    out.append("// Auto-generated by scripts/convert_muscle_paths.py — do not edit by hand.")
    out.append("// Source: react-native-body-highlighter muscle artwork.")
    out.append("// MIT License, Copyright (c) 2022 ELABBASSI Hicham.")
    out.append("// Paths are normalized to a unit space (source viewBox 724x1448, aspect 0.5),")
    out.append("// using only absolute M/L/C/Z commands so the Swift parser stays trivial.")
    out.append("")
    out.append("import Foundation")
    out.append("")
    out.append("enum MuscleMapData {")
    out.append(swift_array("front", front_conv))
    out.append("")
    out.append(swift_array("back", back_conv))
    out.append("")
    out.append(f'    static let frontOutline = "{front_outline}"')
    out.append("")
    out.append(f'    static let backOutline = "{back_outline}"')
    out.append("}")
    out.append("")

    dest = "WorkoutTracker/Components/MuscleMapData.swift"
    open(dest, "w", encoding="utf-8").write("\n".join(out))
    sys.stderr.write(f"wrote {dest}\n")


if __name__ == "__main__":
    main()
