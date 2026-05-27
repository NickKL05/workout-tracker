import SwiftUI
import SwiftData

/// Renders one or two line charts showing how the lifter's numbers for a given
/// exercise have moved over time across their finished sessions.
///
/// What's plotted depends on the exercise type:
/// - weightReps  → top weight + best reps
/// - weightTime  → top weight + longest hold
/// - cardio      → longest duration + peak intensity
struct ExerciseProgressionView: View {
    let exercise: Exercise

    @Query(sort: \WorkoutSession.startedAt) private var sessions: [WorkoutSession]

    var body: some View {
        let s = series()
        let hasAny = s.contains(where: { $0.points.count >= 2 })

        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Progression")
            if hasAny {
                VStack(spacing: 12) {
                    ForEach(s.indices, id: \.self) { idx in
                        if s[idx].points.count >= 2 {
                            ProgressionChart(series: s[idx])
                        }
                    }
                }
            } else {
                Card {
                    Text("Log this exercise in at least two sessions to see your progress over time.")
                        .font(.bodyMd)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
    }

    private func series() -> [ProgressionSeries] {
        let logs: [(Date, ExerciseLog)] = sessions.compactMap { s in
            guard s.isFinished else { return nil }
            guard let log = s.exerciseLogs.first(where: { $0.exercise?.uuid == exercise.uuid }) else { return nil }
            return (s.startedAt, log)
        }

        switch exercise.type {
        case .weightReps:
            return [
                ProgressionSeries(title: "Top weight", unit: "lbs", style: .decimal, points: logs.compactMap { date, log in
                    let w = log.topWeight
                    return w > 0 ? .init(date: date, value: w) : nil
                }),
                ProgressionSeries(title: "Best reps", unit: "reps", style: .integer, points: logs.compactMap { date, log in
                    let r: Int
                    if log.isUnilateral {
                        r = log.sets.filter(\.completed).map { min($0.leftReps, $0.rightReps) }.max() ?? 0
                    } else {
                        r = log.sets.filter(\.completed).map(\.reps).max() ?? 0
                    }
                    return r > 0 ? .init(date: date, value: Double(r)) : nil
                }),
            ]
        case .weightTime:
            return [
                ProgressionSeries(title: "Top weight", unit: "lbs", style: .decimal, points: logs.compactMap { date, log in
                    let w = log.topWeight
                    return w > 0 ? .init(date: date, value: w) : nil
                }),
                ProgressionSeries(title: "Longest hold", unit: "sec", style: .duration, points: logs.compactMap { date, log in
                    let d = log.sets.filter(\.completed).map(\.durationSeconds).max() ?? 0
                    return d > 0 ? .init(date: date, value: Double(d)) : nil
                }),
            ]
        case .cardio:
            return [
                ProgressionSeries(title: "Longest session", unit: "", style: .duration, points: logs.compactMap { date, log in
                    let d = log.sets.filter(\.completed).map(\.durationSeconds).max() ?? 0
                    return d > 0 ? .init(date: date, value: Double(d)) : nil
                }),
                ProgressionSeries(title: "Peak intensity", unit: "/10", style: .integer, points: logs.compactMap { date, log in
                    let i = log.sets.filter(\.completed).map(\.intensity).max() ?? 0
                    return i > 0 ? .init(date: date, value: Double(i)) : nil
                }),
            ]
        }
    }
}

// MARK: - Series & chart

struct ProgressionPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

enum ProgressionValueStyle {
    case decimal     // weight
    case integer     // reps, intensity
    case duration    // seconds → "1:30"
}

struct ProgressionSeries {
    let title: String
    let unit: String
    let style: ProgressionValueStyle
    let points: [ProgressionPoint]
}

private struct ProgressionChart: View {
    let series: ProgressionSeries

    var body: some View {
        Card(padding: 14) {
            VStack(alignment: .leading, spacing: 10) {
                header
                ChartCanvas(points: series.points)
                    .frame(height: 92)
                xAxisLabels
            }
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(series.title.uppercased())
                .font(.caption)
                .tracking(1.2)
                .foregroundStyle(Theme.textMuted)
            Spacer()
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(format(series.points.last?.value ?? 0))
                    .font(.titleLg)
                    .foregroundStyle(Theme.textPrimary)
                if !series.unit.isEmpty {
                    Text(series.unit)
                        .font(.caption)
                        .foregroundStyle(Theme.textMuted)
                }
                if let delta = delta() {
                    deltaBadge(delta)
                }
            }
        }
    }

    @ViewBuilder
    private func deltaBadge(_ delta: Double) -> some View {
        let positive = delta >= 0
        Text("\(positive ? "+" : "")\(format(delta))")
            .font(.caption)
            .foregroundStyle(positive ? Theme.accent : Theme.textSecondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Theme.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .padding(.leading, 4)
    }

    private func delta() -> Double? {
        guard series.points.count >= 2 else { return nil }
        let last = series.points.last!.value
        let prev = series.points[series.points.count - 2].value
        return last - prev
    }

    private var xAxisLabels: some View {
        HStack {
            Text(Format.shortDate(series.points.first?.date ?? Date()))
                .font(.caption)
                .foregroundStyle(Theme.textMuted)
            Spacer()
            Text("\(series.points.count) session\(series.points.count == 1 ? "" : "s")")
                .font(.caption)
                .foregroundStyle(Theme.textMuted)
            Spacer()
            Text(Format.shortDate(series.points.last?.date ?? Date()))
                .font(.caption)
                .foregroundStyle(Theme.textMuted)
        }
    }

    private func format(_ value: Double) -> String {
        switch series.style {
        case .decimal:  return Format.weight(value)
        case .integer:  return "\(Int(value.rounded()))"
        case .duration: return Format.duration(Int(value.rounded()))
        }
    }
}

/// Pure Path-based line chart. Monochrome to match the rest of the app.
private struct ChartCanvas: View {
    let points: [ProgressionPoint]

    var body: some View {
        GeometryReader { geo in
            let values = points.map(\.value)
            let lo = values.min() ?? 0
            let hi = values.max() ?? 1
            let span = max(hi - lo, 1)
            // Pad the y range so flat lines aren't pinned to the edges.
            let pad = span * 0.15
            let yMin = lo - pad
            let yMax = hi + pad
            let yRange = yMax - yMin

            let inset: CGFloat = 4
            let w = geo.size.width - inset * 2
            let h = geo.size.height - inset * 2
            let stepX = points.count > 1 ? w / CGFloat(points.count - 1) : 0

            func point(_ i: Int) -> CGPoint {
                let v = points[i].value
                let normalized = CGFloat((v - yMin) / yRange)
                let x = inset + CGFloat(i) * stepX
                let y = inset + h - normalized * h
                return CGPoint(x: x, y: y)
            }

            ZStack(alignment: .topLeading) {
                // Subtle grid (3 horizontal lines).
                Path { p in
                    for i in 0...2 {
                        let y = inset + h * CGFloat(i) / 2
                        p.move(to: CGPoint(x: inset, y: y))
                        p.addLine(to: CGPoint(x: inset + w, y: y))
                    }
                }
                .stroke(Theme.stroke.opacity(0.5), style: StrokeStyle(lineWidth: 0.5, dash: [2, 3]))

                // Fill under line.
                Path { p in
                    guard points.count >= 2 else { return }
                    p.move(to: CGPoint(x: point(0).x, y: inset + h))
                    for i in 0..<points.count {
                        p.addLine(to: point(i))
                    }
                    p.addLine(to: CGPoint(x: point(points.count - 1).x, y: inset + h))
                    p.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [Theme.accent.opacity(0.18), Theme.accent.opacity(0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                // Line.
                Path { p in
                    guard !points.isEmpty else { return }
                    p.move(to: point(0))
                    for i in 1..<points.count {
                        p.addLine(to: point(i))
                    }
                }
                .stroke(Theme.accent, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

                // Dots.
                ForEach(points.indices, id: \.self) { i in
                    let pt = point(i)
                    Circle()
                        .fill(Theme.accent)
                        .frame(width: 5, height: 5)
                        .position(x: pt.x, y: pt.y)
                }

                // Highlight the latest dot.
                if let last = points.indices.last {
                    let pt = point(last)
                    Circle()
                        .stroke(Theme.accent, lineWidth: 2)
                        .frame(width: 10, height: 10)
                        .position(x: pt.x, y: pt.y)
                }
            }
        }
    }
}
