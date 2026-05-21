import Foundation
import SwiftData

@Model
final class ExerciseLog {
    var exerciseName: String = ""           // snapshot, in case exercise is deleted
    var exerciseTypeRaw: String = ExerciseType.weightReps.rawValue
    var isUnilateral: Bool = false
    var goalSets: Int = 0
    var goalReps: Int = 0
    var goalDurationSeconds: Int = 0
    var goalIntensity: Int = 0

    @Relationship(deleteRule: .cascade) var sets: [SetLog] = []
    @Relationship var exercise: Exercise?

    init(exercise: Exercise) {
        self.exercise = exercise
        self.exerciseName = exercise.name
        self.exerciseTypeRaw = exercise.typeRaw
        self.isUnilateral = exercise.isUnilateral
        self.goalSets = exercise.goalSets
        self.goalReps = exercise.goalReps
        self.goalDurationSeconds = exercise.goalDurationSeconds
        self.goalIntensity = exercise.goalIntensity
    }

    var exerciseType: ExerciseType {
        ExerciseType(rawValue: exerciseTypeRaw) ?? .weightReps
    }

    var orderedSets: [SetLog] {
        sets.sorted { $0.setNumber < $1.setNumber }
    }

    /// True iff every goal set is completed and meets the rep / duration target.
    var hitGoalAcrossAllSets: Bool {
        let completed = orderedSets.filter { $0.completed }
        guard completed.count >= goalSets, goalSets > 0 else { return false }
        switch exerciseType {
        case .weightReps:
            if isUnilateral {
                return completed.prefix(goalSets).allSatisfy { $0.leftReps >= goalReps && $0.rightReps >= goalReps }
            } else {
                return completed.prefix(goalSets).allSatisfy { $0.reps >= goalReps }
            }
        case .weightTime:
            return completed.prefix(goalSets).allSatisfy { $0.durationSeconds >= goalDurationSeconds }
        case .cardio:
            return completed.prefix(goalSets).allSatisfy {
                $0.durationSeconds >= goalDurationSeconds && $0.intensity >= goalIntensity
            }
        }
    }

    /// Heaviest weight used across this session (for overload anchoring).
    var topWeight: Double {
        sets.map { $0.weight }.max() ?? 0
    }
}
