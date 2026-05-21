import Foundation
import SwiftData

@Model
final class WorkoutSession {
    var workoutName: String = ""
    var startedAt: Date = Date()
    var endedAt: Date?
    var notes: String = ""

    @Relationship(deleteRule: .cascade) var exerciseLogs: [ExerciseLog] = []
    @Relationship var workout: Workout?
    @Relationship var split: Split?

    init(workout: Workout, split: Split? = nil) {
        self.workout = workout
        self.workoutName = workout.name
        self.split = split
        self.startedAt = Date()
        // Seed exerciseLogs from the workout's exercises so logging UI has a row per exercise.
        self.exerciseLogs = workout.orderedExercises.map { ExerciseLog(exercise: $0) }
    }

    var isFinished: Bool { endedAt != nil }

    var elapsed: TimeInterval {
        let end = endedAt ?? Date()
        return end.timeIntervalSince(startedAt)
    }

    func finish() {
        if endedAt == nil { endedAt = Date() }
    }
}
