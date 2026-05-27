import Foundation
import SwiftData

/// One exercise inside a single workout. Owns its own sets / reps /
/// duration / intensity goals, so the same underlying Exercise can sit in
/// a 5×5 strength day in one workout and a 3×12 hypertrophy day in
/// another (or a 2×8 deload variant in a third) without cross-talk.
///
/// Created when the user adds an exercise to a workout. Goal fields are
/// seeded from the Exercise's default values, then editable per-workout.
@Model
final class WorkoutExercise {
    @Attribute(.unique) var uuid: UUID = UUID()
    var orderIndex: Int = 0

    var goalSets: Int = 3
    var goalReps: Int = 8
    var goalDurationSeconds: Int = 30
    var goalIntensity: Int = 5

    @Relationship var exercise: Exercise?
    @Relationship var workout: Workout?

    init(exercise: Exercise, workout: Workout? = nil, orderIndex: Int = 0) {
        self.uuid = UUID()
        self.exercise = exercise
        self.workout = workout
        self.orderIndex = orderIndex
        // Seed from the exercise's stored defaults.
        self.goalSets = exercise.goalSets
        self.goalReps = exercise.goalReps
        self.goalDurationSeconds = exercise.goalDurationSeconds
        self.goalIntensity = exercise.goalIntensity
    }
}
