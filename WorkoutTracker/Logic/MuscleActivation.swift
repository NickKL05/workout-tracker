import Foundation

/// Computes per-muscle-group "how much was this trained" intensities in the
/// range 0...1, used to tint the body diagram. Intensities are normalized to
/// the most-trained group so the figure always has a clear peak.
enum MuscleActivation {
    /// Groups the body diagram can actually draw.
    static let mappable: [MuscleGroup] = [
        .chest, .back, .shoulders, .biceps, .triceps, .forearms,
        .quads, .hamstrings, .glutes, .calves, .core, .neck
    ]

    /// How a single exercise's muscle group spreads onto the diagram.
    /// Full-body lifts light up the major movers; cardio / other map to
    /// nothing anatomical.
    static func spread(for group: MuscleGroup) -> [MuscleGroup: Double] {
        switch group {
        case .fullBody:
            return [.chest: 1, .back: 1, .shoulders: 1, .quads: 1, .hamstrings: 1, .glutes: 1, .core: 1]
        case .cardio, .other:
            return [:]
        default:
            return [group: 1]
        }
    }

    /// Activation for one exercise (used in the exercise detail screen).
    static func forMuscle(_ group: MuscleGroup) -> [MuscleGroup: Double] {
        normalize(spread(for: group))
    }

    /// Activation for a workout: every exercise contributes once, normalized
    /// so the most-targeted group reads as fully lit.
    static func forExercises(_ exercises: [Exercise]) -> [MuscleGroup: Double] {
        var raw: [MuscleGroup: Double] = [:]
        for ex in exercises {
            for (g, v) in spread(for: ex.muscleGroup) {
                raw[g, default: 0] += v
            }
        }
        return normalize(raw)
    }

    /// Activation across finished sessions on or after `since`, weighted by
    /// completed set volume (used for the weekly summary on Home).
    static func forSessions(_ sessions: [WorkoutSession], since: Date) -> [MuscleGroup: Double] {
        var raw: [MuscleGroup: Double] = [:]
        for session in sessions where session.isFinished && session.startedAt >= since {
            for log in session.exerciseLogs {
                guard let group = log.exercise?.muscleGroup else { continue }
                let sets = max(1, log.sets.filter(\.completed).count)
                for (g, v) in spread(for: group) {
                    raw[g, default: 0] += v * Double(sets)
                }
            }
        }
        return normalize(raw)
    }

    static func normalize(_ raw: [MuscleGroup: Double]) -> [MuscleGroup: Double] {
        guard let maxValue = raw.values.max(), maxValue > 0 else { return [:] }
        return raw.mapValues { min(1, $0 / maxValue) }
    }

    /// Worked groups sorted strongest-first, for a compact text legend.
    static func workedGroups(_ activation: [MuscleGroup: Double]) -> [MuscleGroup] {
        activation
            .filter { $0.value > 0 }
            .sorted { $0.value > $1.value }
            .map(\.key)
    }
}
