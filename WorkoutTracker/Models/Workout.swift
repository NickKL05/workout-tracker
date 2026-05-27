import Foundation
import SwiftData

@Model
final class Workout {
    @Attribute(.unique) var uuid: UUID = UUID()
    var name: String = ""
    var createdAt: Date = Date()

    // Legacy fields. Kept in the schema so SwiftData can lightweight-migrate
    // older stores; we populate `workoutExercises` from these on first
    // launch via `migrateLegacyExercisesIfNeeded(...)`. New writes only ever
    // touch `workoutExercises`.
    var orderedExerciseUUIDs: [UUID] = []
    @Relationship var exercises: [Exercise] = []

    /// Per-workout exercise rows. Owns its own goals.
    @Relationship(deleteRule: .cascade, inverse: \WorkoutExercise.workout)
    var workoutExercises: [WorkoutExercise] = []

    init(name: String) {
        self.uuid = UUID()
        self.name = name
        self.createdAt = Date()
    }

    var orderedWorkoutExercises: [WorkoutExercise] {
        workoutExercises.sorted { $0.orderIndex < $1.orderIndex }
    }

    /// Convenience for views that don't need per-workout goal data, only
    /// the underlying Exercise identities (e.g. muscle-coverage analysis).
    var orderedExercises: [Exercise] {
        orderedWorkoutExercises.compactMap(\.exercise)
    }

    /// Replace the workout's exercise list with new `WorkoutExercise` rows
    /// for the supplied exercises. Reuses existing rows where possible so
    /// per-workout goal customisations survive a re-pick from the picker.
    func setWorkoutExercises(_ list: [WorkoutExercise]) {
        for (i, we) in list.enumerated() { we.orderIndex = i }
        self.workoutExercises = list
    }

    /// One-shot backfill: build `workoutExercises` from the legacy
    /// `exercises` relation. Safe to call repeatedly; no-op once migrated.
    /// `context` is required so we can insert the new rows.
    func migrateLegacyExercisesIfNeeded(context: ModelContext) {
        guard workoutExercises.isEmpty, !exercises.isEmpty else { return }
        let exByID = Dictionary(uniqueKeysWithValues: exercises.map { ($0.uuid, $0) })
        // Preserve the legacy ordering if we still have it; otherwise fall
        // back to the unordered exercises array.
        let orderedSourceIDs = orderedExerciseUUIDs.isEmpty
            ? exercises.map(\.uuid)
            : orderedExerciseUUIDs
        var built: [WorkoutExercise] = []
        for (idx, id) in orderedSourceIDs.enumerated() {
            guard let ex = exByID[id] else { continue }
            let we = WorkoutExercise(exercise: ex, workout: self, orderIndex: idx)
            context.insert(we)
            built.append(we)
        }
        self.workoutExercises = built
    }
}
