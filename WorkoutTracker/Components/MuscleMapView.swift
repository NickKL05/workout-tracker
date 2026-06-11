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
            ctx.fill(body, with: .color(Color(white: 0.10)))

            // Muscle regions, tinted by activation.
            for region in Self.regions(for: side) {
                let intensity = activation[region.group] ?? 0
                ctx.fill(region.path(r), with: .color(Self.fillColor(intensity)))
            }

            // Subtle outline so the figure reads on pure black.
            ctx.stroke(body, with: .color(Color(white: 0.22)), lineWidth: 1)
        }
    }

    private static func fillColor(_ intensity: Double) -> Color {
        if intensity <= 0 { return Color(white: 0.20) }
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

    private static let frontRegions: [Region] = [
        Region(group: .neck)      { bar(0.45, 0.135, 0.10, 0.05, $0) },
        Region(group: .shoulders) { union(blob(0.305, 0.205, 0.072, 0.052, $0), blob(0.695, 0.205, 0.072, 0.052, $0)) },
        Region(group: .chest)     { union(bar(0.355, 0.185, 0.135, 0.10, $0, 0.35), bar(0.510, 0.185, 0.135, 0.10, $0, 0.35)) },
        Region(group: .biceps)    { union(bar(0.205, 0.225, 0.075, 0.14, $0), bar(0.720, 0.225, 0.075, 0.14, $0)) },
        Region(group: .forearms)  { union(bar(0.180, 0.370, 0.070, 0.15, $0), bar(0.750, 0.370, 0.070, 0.15, $0)) },
        Region(group: .core)      { bar(0.40, 0.30, 0.20, 0.155, $0, 0.25) },
        Region(group: .quads)     { union(bar(0.360, 0.515, 0.105, 0.215, $0, 0.4), bar(0.535, 0.515, 0.105, 0.215, $0, 0.4)) },
    ]

    private static let backRegions: [Region] = [
        Region(group: .neck)      { bar(0.45, 0.135, 0.10, 0.05, $0) },
        Region(group: .shoulders) { union(blob(0.305, 0.205, 0.072, 0.052, $0), blob(0.695, 0.205, 0.072, 0.052, $0)) },
        Region(group: .back)      { union(bar(0.35, 0.175, 0.30, 0.115, $0, 0.3), bar(0.36, 0.285, 0.28, 0.12, $0, 0.3)) },
        Region(group: .triceps)   { union(bar(0.205, 0.225, 0.075, 0.14, $0), bar(0.720, 0.225, 0.075, 0.14, $0)) },
        Region(group: .forearms)  { union(bar(0.180, 0.370, 0.070, 0.15, $0), bar(0.750, 0.370, 0.070, 0.15, $0)) },
        Region(group: .glutes)    { union(blob(0.425, 0.515, 0.080, 0.060, $0), blob(0.575, 0.515, 0.080, 0.060, $0)) },
        Region(group: .hamstrings){ union(bar(0.360, 0.570, 0.105, 0.16, $0, 0.4), bar(0.535, 0.570, 0.105, 0.16, $0, 0.4)) },
        Region(group: .calves)    { union(bar(0.370, 0.760, 0.090, 0.16, $0, 0.45), bar(0.545, 0.760, 0.090, 0.16, $0, 0.45)) },
    ]

    // MARK: Silhouette

    private static func silhouette(_ r: CGRect) -> Path {
        var p = Path()
        p.addPath(blob(0.50, 0.075, 0.082, 0.072, r))      // head
        p.addPath(bar(0.45, 0.13, 0.10, 0.06, r, 0.5))     // neck
        p.addPath(bar(0.33, 0.165, 0.34, 0.33, r, 0.28))   // torso
        p.addPath(bar(0.35, 0.45, 0.30, 0.10, r, 0.4))     // hips
        p.addPath(bar(0.20, 0.19, 0.095, 0.34, r, 0.5))    // left arm
        p.addPath(bar(0.705, 0.19, 0.095, 0.34, r, 0.5))   // right arm
        p.addPath(bar(0.355, 0.50, 0.12, 0.47, r, 0.4))    // left leg
        p.addPath(bar(0.525, 0.50, 0.12, 0.47, r, 0.4))    // right leg
        return p
    }

    // MARK: Normalized primitives (coords are fractions of the figure rect)

    private static func blob(_ cx: CGFloat, _ cy: CGFloat, _ rx: CGFloat, _ ry: CGFloat, _ r: CGRect) -> Path {
        Path(ellipseIn: CGRect(
            x: r.minX + (cx - rx) * r.width,
            y: r.minY + (cy - ry) * r.height,
            width: 2 * rx * r.width,
            height: 2 * ry * r.height
        ))
    }

    private static func bar(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ r: CGRect, _ corner: CGFloat = 0.5) -> Path {
        let rect = CGRect(x: r.minX + x * r.width, y: r.minY + y * r.height, width: w * r.width, height: h * r.height)
        let radius = min(rect.width, rect.height) * corner
        return Path(roundedRect: rect, cornerRadius: radius)
    }

    private static func union(_ paths: Path...) -> Path {
        var combined = Path()
        for path in paths { combined.addPath(path) }
        return combined
    }
}
