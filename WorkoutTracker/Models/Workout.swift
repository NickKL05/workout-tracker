import Foundation
import SwiftData

@Model
final class Workout {
    @Attribute(.unique) var uuid: UUID = UUID()
    var name: String = ""
    var orderedExerciseUUIDs: [UUID] = []
    var createdAt: Date = Date()

    @Relationship var exercises: [Exercise] = []

    init(name: String, exercises: [Exercise] = []) {
        self.uuid = UUID()
        self.name = name
        self.exercises = exercises
        self.orderedExerciseUUIDs = exercises.map(\.uuid)
        self.createdAt = Date()
    }

    var orderedExercises: [Exercise] {
        let byID = Dictionary(uniqueKeysWithValues: exercises.map { ($0.uuid, $0) })
        let ordered = orderedExerciseUUIDs.compactMap { byID[$0] }
        let missing = exercises.filter { ex in !orderedExerciseUUIDs.contains(ex.uuid) }
        return ordered + missing
    }

    func setExercises(_ list: [Exercise]) {
        self.exercises = list
        self.orderedExerciseUUIDs = list.map(\.uuid)
    }
}
