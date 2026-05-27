import Foundation

/// Coverage analyzer for a split. Looks at every exercise across every
/// workout in the split and reports which "core" muscle groups go untrained.
/// Used by SplitEditorView to nudge the lifter toward a balanced rotation
/// and surface suggested exercises from their library.
enum SplitCoverage {
    /// Muscle groups most lifters want represented somewhere in the week.
    /// Deliberately excludes Other / Neck / Cardio / Full body, since they
    /// either aren't strength targets or are too broad to flag as "missed".
    static let coreCoverageGroups: [MuscleGroup] = [
        .chest, .back, .shoulders,
        .biceps, .triceps,
        .quads, .hamstrings, .glutes, .calves,
        .core
    ]

    struct Report {
        /// Every muscle group hit by at least one exercise in the split.
        let covered: Set<MuscleGroup>
        /// Core groups not covered, sorted by canonical display order.
        let missed: [MuscleGroup]
        /// Muscle group → number of distinct exercises hitting it.
        let exerciseCountByGroup: [MuscleGroup: Int]

        var isComplete: Bool { missed.isEmpty }
    }

    /// Compute coverage from a flat list of workouts.
    static func report(for workouts: [Workout]) -> Report {
        var counts: [MuscleGroup: Int] = [:]
        for workout in workouts {
            for ex in workout.orderedExercises {
                counts[ex.muscleGroup, default: 0] += 1
            }
        }
        let covered = Set(counts.keys)
        let missed = coreCoverageGroups.filter { !covered.contains($0) }
        return Report(covered: covered, missed: missed, exerciseCountByGroup: counts)
    }

    /// Up to `limit` exercises from `library` that target `group`, sorted by name.
    static func suggestions(for group: MuscleGroup, in library: [Exercise], limit: Int = 3) -> [Exercise] {
        Array(
            library
                .filter { $0.muscleGroup == group }
                .sorted { $0.name < $1.name }
                .prefix(limit)
        )
    }
}
