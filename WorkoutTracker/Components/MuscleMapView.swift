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

/// Renders anatomical front/back figures from real per-muscle vector artwork
/// (see `MuscleMapData`, adapted from the MIT-licensed react-native-body-
/// highlighter). Each muscle group is its own path, tinted by activation; the
/// body outline sits underneath so gaps between muscles read as dim body.
struct BodyFigure: View {
    enum Side { case front, back }

    let side: Side
    let activation: [MuscleGroup: Double]

    var body: some View {
        Canvas { ctx, size in
            // Unit-space paths (0...1) scaled to fill the canvas. The source
            // viewBox is 724x1448, so the figure keeps its 1:2 proportions
            // when drawn into the aspect-0.5 frame the parent applies.
            let t = CGAffineTransform(scaleX: size.width, y: size.height)
            let outline = Self.outline(for: side).applying(t)

            ctx.fill(outline, with: .color(Color(white: 0.12)))

            for layer in Self.layers(for: side) {
                let path = layer.path.applying(t)
                let mapped = layer.group != nil
                let intensity = layer.group.flatMap { activation[$0] } ?? 0
                ctx.fill(path, with: .color(Self.fillColor(intensity, mapped: mapped)))
                ctx.stroke(path, with: .color(Color(white: 0.30)), lineWidth: 0.5)
            }

            ctx.stroke(outline, with: .color(Color(white: 0.26)), lineWidth: 1.2)
        }
    }

    private static func fillColor(_ intensity: Double, mapped: Bool) -> Color {
        // Structural parts (head, hands, feet, joints) are never "trained".
        guard mapped else { return Color(white: 0.17) }
        if intensity <= 0 { return Color(white: 0.24) }
        // Floor at 0.45 so any worked muscle is clearly lit, scaling to ~white.
        return Color(white: 0.45 + 0.5 * min(1, intensity))
    }

    // MARK: Layers (parsed once into unit space, then transformed per draw)

    struct Layer {
        let group: MuscleGroup?   // nil = structural body part, never tinted
        let path: Path
    }

    static func layers(for side: Side) -> [Layer] {
        side == .front ? frontLayers : backLayers
    }

    static func outline(for side: Side) -> Path {
        side == .front ? frontOutline : backOutline
    }

    private static let frontLayers: [Layer] = MuscleMapData.front.map {
        Layer(group: group(for: $0.0), path: SVGPath.parse($0.1))
    }
    private static let backLayers: [Layer] = MuscleMapData.back.map {
        Layer(group: group(for: $0.0), path: SVGPath.parse($0.1))
    }
    private static let frontOutline = SVGPath.parse(MuscleMapData.frontOutline)
    private static let backOutline = SVGPath.parse(MuscleMapData.backOutline)

    /// Maps an artwork muscle slug to the app's `MuscleGroup`. Slugs with no
    /// counterpart (adductors, tibialis, head, hands, feet, joints, hair)
    /// return nil and render as structural body.
    static func group(for slug: String) -> MuscleGroup? {
        switch slug {
        case "chest":                                  return .chest
        case "biceps":                                 return .biceps
        case "triceps":                                return .triceps
        case "forearm":                                return .forearms
        case "deltoids":                               return .shoulders
        case "abs", "obliques":                        return .core
        case "quadriceps":                             return .quads
        case "hamstring":                              return .hamstrings
        case "gluteal":                                return .glutes
        case "calves":                                 return .calves
        case "neck":                                   return .neck
        case "trapezius", "upper-back", "lower-back":  return .back
        default:                                       return nil
        }
    }
}

// MARK: - Minimal SVG path reader

/// Parses the normalized path strings emitted by
/// `scripts/convert_muscle_paths.py`, which use only absolute M/L/C/Z
/// commands with space-separated coordinates in unit space.
enum SVGPath {
    static func parse(_ s: String) -> Path {
        var path = Path()
        let toks = s.split(separator: " ")
        var i = 0

        func coord() -> CGFloat {
            defer { i += 1 }
            guard i < toks.count, let v = Double(String(toks[i])) else { return 0 }
            return CGFloat(v)
        }
        func point() -> CGPoint { CGPoint(x: coord(), y: coord()) }

        while i < toks.count {
            let cmd = String(toks[i])
            i += 1
            switch cmd {
            case "M": path.move(to: point())
            case "L": path.addLine(to: point())
            case "C":
                let c1 = point(); let c2 = point(); let end = point()
                path.addCurve(to: end, control1: c1, control2: c2)
            case "Z": path.closeSubpath()
            default: break   // skip stray tokens defensively
            }
        }
        return path
    }
}
