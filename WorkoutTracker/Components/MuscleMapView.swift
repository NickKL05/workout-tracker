import SwiftUI

/// Front + back stylized body figures that light up the muscle groups a
/// workout / exercise / week of training hit. Monochrome to match the app:
/// untrained muscles sit dim, trained ones glow brighter the more volume
/// they got.
struct MuscleMapView: View {
    let activation: [MuscleGroup: Double]
    var showLegend: Bool = true
    var figureHeight: CGFloat = 200

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 18) {
                figureColumn(side: .front, label: "Front")
                figureColumn(side: .back, label: "Back")
            }
            .frame(height: figureHeight)

            if showLegend { legend }
        }
    }

    private func figureColumn(side: BodyFigure.Side, label: String) -> some View {
        VStack(spacing: 6) {
            BodyFigure(side: side, activation: activation)
                .aspectRatio(0.5, contentMode: .fit)
                .frame(maxWidth: .infinity)
            Text(label.uppercased())
                .font(.system(size: 9, weight: .semibold))
                .tracking(1.0)
                .foregroundStyle(Theme.textMuted)
        }
    }

    @ViewBuilder
    private var legend: some View {
        let worked = MuscleActivation.workedGroups(activation)
        if worked.isEmpty {
            Text("No muscles trained yet")
                .font(.caption)
                .foregroundStyle(Theme.textMuted)
        } else {
            Text(worked.map(\.displayName).joined(separator: " · "))
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Body figure

struct BodyFigure: View {
    enum Side { case front, back }

    let side: Side
    let activation: [MuscleGroup: Double]

    var body: some View {
        Canvas { ctx, size in
            let r = CGRect(origin: .zero, size: size)

            // Body silhouette underneath.
            let body = Self.silhouette(r)
            ctx.fill(body, with: .color(Color(white: 0.13)))

            // Muscle regions, tinted by activation, each with a faint edge so
            // individual muscles stay legible even when dim.
            for region in Self.regions(for: side) {
                let intensity = activation[region.group] ?? 0
                let path = region.path(r)
                ctx.fill(path, with: .color(Self.fillColor(intensity)))
                ctx.stroke(path, with: .color(Color(white: 0.30)), lineWidth: 0.6)
            }

            // Silhouette outline so the figure reads on pure black.
            ctx.stroke(body, with: .color(Color(white: 0.24)), lineWidth: 1)
        }
    }

    private static func fillColor(_ intensity: Double) -> Color {
        if intensity <= 0 { return Color(white: 0.22) }
        // Floor at 0.45 so any worked muscle is clearly lit, scaling to ~white.
        return Color(white: 0.45 + 0.5 * min(1, intensity))
    }

    // MARK: Regions

    struct Region {
        let group: MuscleGroup
        let path: (CGRect) -> Path
    }

    private static func regions(for side: Side) -> [Region] {
        switch side {
        case .front: return frontRegions
        case .back:  return backRegions
        }
    }

    // Muscle outlines are described as normalized point clouds (fractions of
    // the figure rect) and rendered as smooth closed curves. `pair` mirrors a
    // left-side shape across the vertical centerline to make a symmetric pair.

    private static let frontRegions: [Region] = [
        Region(group: .neck)      { shape(neckFront, $0) },
        Region(group: .shoulders) { pair(deltoid, $0) },
        Region(group: .chest)     { pair(pec, $0) },
        Region(group: .biceps)    { pair(upperArm, $0) },
        Region(group: .forearms)  { pair(forearm, $0) },
        Region(group: .core)      { shape(abs, $0) },
        Region(group: .quads)     { pair(quad, $0) },
    ]

    private static let backRegions: [Region] = [
        Region(group: .neck)      { shape(neckBack, $0) },
        Region(group: .shoulders) { pair(deltoid, $0) },
        Region(group: .back)      { backComplex($0) },
        Region(group: .triceps)   { pair(upperArm, $0) },
        Region(group: .forearms)  { pair(forearm, $0) },
        Region(group: .glutes)    { pair(glute, $0) },
        Region(group: .hamstrings){ pair(hamstring, $0) },
        Region(group: .calves)    { pair(calf, $0) },
    ]

    // MARK: Muscle point clouds (left side; x < 0.5)

    private static let deltoid: [CGPoint] = [
        p(0.30, 0.155), p(0.355, 0.175), p(0.365, 0.235),
        p(0.315, 0.255), p(0.272, 0.215), p(0.282, 0.172),
    ]
    private static let pec: [CGPoint] = [
        p(0.495, 0.182), p(0.385, 0.198), p(0.368, 0.248),
        p(0.425, 0.288), p(0.495, 0.282),
    ]
    private static let upperArm: [CGPoint] = [   // biceps (front) / triceps (back)
        p(0.302, 0.215), p(0.345, 0.225), p(0.332, 0.350),
        p(0.286, 0.365), p(0.262, 0.300), p(0.272, 0.232),
    ]
    private static let forearm: [CGPoint] = [
        p(0.272, 0.378), p(0.312, 0.388), p(0.258, 0.512),
        p(0.205, 0.518), p(0.222, 0.430),
    ]
    private static let abs: [CGPoint] = [
        p(0.435, 0.288), p(0.565, 0.288), p(0.560, 0.395),
        p(0.50, 0.455), p(0.440, 0.395),
    ]
    private static let quad: [CGPoint] = [
        p(0.362, 0.520), p(0.452, 0.532), p(0.456, 0.660),
        p(0.408, 0.712), p(0.360, 0.700), p(0.346, 0.585),
    ]
    private static let glute: [CGPoint] = [
        p(0.498, 0.498), p(0.498, 0.582), p(0.428, 0.592),
        p(0.388, 0.548), p(0.418, 0.500),
    ]
    private static let hamstring: [CGPoint] = [
        p(0.360, 0.600), p(0.456, 0.600), p(0.450, 0.700),
        p(0.402, 0.716), p(0.356, 0.662),
    ]
    private static let calf: [CGPoint] = [
        p(0.366, 0.748), p(0.452, 0.748), p(0.456, 0.852),
        p(0.412, 0.902), p(0.366, 0.852), p(0.356, 0.788),
    ]
    private static let neckFront: [CGPoint] = [
        p(0.458, 0.120), p(0.542, 0.120), p(0.552, 0.158), p(0.448, 0.158),
    ]
    private static let neckBack: [CGPoint] = [
        p(0.50, 0.118), p(0.575, 0.158), p(0.50, 0.205), p(0.425, 0.158),
    ]

    // Back complex: upper traps diamond + the two lats tapering to the waist.
    private static func backComplex(_ r: CGRect) -> Path {
        let traps: [CGPoint] = [p(0.50, 0.158), p(0.60, 0.215), p(0.50, 0.262), p(0.40, 0.215)]
        let lat: [CGPoint] = [p(0.40, 0.232), p(0.478, 0.250), p(0.478, 0.380), p(0.412, 0.408), p(0.362, 0.300)]
        return union(shape(traps, r), pair(lat, r))
    }

    // MARK: Silhouette

    private static func silhouette(_ r: CGRect) -> Path {
        var p = Path()
        // Head.
        p.addPath(Path(ellipseIn: CGRect(
            x: r.minX + 0.418 * r.width, y: r.minY + 0.005 * r.height,
            width: 0.164 * r.width, height: 0.105 * r.height
        )))
        p.addPath(shape(torso, r))
        p.addPath(pair(arm, r))
        p.addPath(pair(leg, r))
        return p
    }

    private static let torso: [CGPoint] = [
        p(0.428, 0.118), p(0.335, 0.158), p(0.358, 0.262),
        p(0.388, 0.400), p(0.358, 0.500), p(0.468, 0.540),
        p(0.532, 0.540), p(0.642, 0.500), p(0.612, 0.400),
        p(0.665, 0.262), p(0.572, 0.158),
    ]
    private static let arm: [CGPoint] = [
        p(0.298, 0.165), p(0.345, 0.200), p(0.300, 0.380),
        p(0.222, 0.530), p(0.165, 0.560), p(0.182, 0.520),
        p(0.255, 0.378),
    ]
    private static let leg: [CGPoint] = [
        p(0.358, 0.500), p(0.342, 0.680), p(0.356, 0.730),
        p(0.360, 0.840), p(0.398, 0.960), p(0.452, 0.958),
        p(0.456, 0.840), p(0.456, 0.730), p(0.476, 0.600),
        p(0.486, 0.520),
    ]

    // MARK: Path builders

    private static func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }

    private static func mirror(_ pts: [CGPoint]) -> [CGPoint] {
        pts.map { CGPoint(x: 1 - $0.x, y: $0.y) }
    }

    /// Smooth closed curve through normalized points using a Catmull-Rom
    /// spline, which renders organic muscle shapes instead of hard polygons.
    private static func shape(_ norm: [CGPoint], _ r: CGRect) -> Path {
        let pts = norm.map { CGPoint(x: r.minX + $0.x * r.width, y: r.minY + $0.y * r.height) }
        var path = Path()
        let n = pts.count
        guard n >= 3 else {
            if let first = pts.first {
                path.move(to: first)
                pts.dropFirst().forEach { path.addLine(to: $0) }
                path.closeSubpath()
            }
            return path
        }
        path.move(to: pts[0])
        for i in 0..<n {
            let p0 = pts[(i - 1 + n) % n]
            let p1 = pts[i]
            let p2 = pts[(i + 1) % n]
            let p3 = pts[(i + 2) % n]
            let c1 = CGPoint(x: p1.x + (p2.x - p0.x) / 6.0, y: p1.y + (p2.y - p0.y) / 6.0)
            let c2 = CGPoint(x: p2.x - (p3.x - p1.x) / 6.0, y: p2.y - (p3.y - p1.y) / 6.0)
            path.addCurve(to: p2, control1: c1, control2: c2)
        }
        path.closeSubpath()
        return path
    }

    /// A left-side shape plus its mirror image, for symmetric muscle pairs.
    private static func pair(_ norm: [CGPoint], _ r: CGRect) -> Path {
        union(shape(norm, r), shape(mirror(norm), r))
    }

    private static func union(_ paths: Path...) -> Path {
        var combined = Path()
        for path in paths { combined.addPath(path) }
        return combined
    }
}
