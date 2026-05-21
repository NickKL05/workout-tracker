import Foundation
import SwiftData

@Model
final class Exercise {
    @Attribute(.unique) var uuid: UUID = UUID()
    var name: String = ""
    var typeRaw: String = ExerciseType.weightReps.rawValue
    var isUnilateral: Bool = false

    // Goals
    var goalSets: Int = 3
    var goalReps: Int = 8
    var goalDurationSeconds: Int = 30      // weightTime / cardio
    var goalIntensity: Int = 5             // 1-10 for cardio

    // Progressive overload steps
    var weightIncrement: Double = 5.0      // lbs
    var intensityIncrement: Int = 1
    var durationIncrementSeconds: Int = 30

    var createdAt: Date = Date()
    var notes: String = ""

    init(
        name: String,
        type: ExerciseType = .weightReps,
        isUnilateral: Bool = false,
        goalSets: Int = 3,
        goalReps: Int = 8,
        goalDurationSeconds: Int = 30,
        goalIntensity: Int = 5,
        weightIncrement: Double = 5.0,
        intensityIncrement: Int = 1,
        durationIncrementSeconds: Int = 30,
        notes: String = ""
    ) {
        self.uuid = UUID()
        self.name = name
        self.typeRaw = type.rawValue
        self.isUnilateral = isUnilateral
        self.goalSets = goalSets
        self.goalReps = goalReps
        self.goalDurationSeconds = goalDurationSeconds
        self.goalIntensity = goalIntensity
        self.weightIncrement = weightIncrement
        self.intensityIncrement = intensityIncrement
        self.durationIncrementSeconds = durationIncrementSeconds
        self.notes = notes
        self.createdAt = Date()
    }

    var type: ExerciseType {
        get { ExerciseType(rawValue: typeRaw) ?? .weightReps }
        set { typeRaw = newValue.rawValue }
    }
}
