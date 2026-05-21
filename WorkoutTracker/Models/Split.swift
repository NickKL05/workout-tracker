import Foundation
import SwiftData

@Model
final class Split {
    @Attribute(.unique) var uuid: UUID = UUID()
    var name: String = ""
    var orderedWorkoutUUIDs: [UUID] = []
    var currentIndex: Int = 0
    var isActive: Bool = false
    var createdAt: Date = Date()

    @Relationship var workouts: [Workout] = []

    init(name: String, workouts: [Workout] = []) {
        self.uuid = UUID()
        self.name = name
        self.workouts = workouts
        self.orderedWorkoutUUIDs = workouts.map(\.uuid)
        self.createdAt = Date()
    }

    var orderedWorkouts: [Workout] {
        let byID = Dictionary(uniqueKeysWithValues: workouts.map { ($0.uuid, $0) })
        let ordered = orderedWorkoutUUIDs.compactMap { byID[$0] }
        let missing = workouts.filter { w in !orderedWorkoutUUIDs.contains(w.uuid) }
        return ordered + missing
    }

    var nextWorkout: Workout? {
        let list = orderedWorkouts
        guard !list.isEmpty else { return nil }
        let idx = max(0, currentIndex) % list.count
        return list[idx]
    }

    func setWorkouts(_ list: [Workout]) {
        self.workouts = list
        self.orderedWorkoutUUIDs = list.map(\.uuid)
        if currentIndex >= list.count { currentIndex = 0 }
    }

    func advance() {
        guard !orderedWorkouts.isEmpty else { return }
        currentIndex = (currentIndex + 1) % orderedWorkouts.count
    }
}
