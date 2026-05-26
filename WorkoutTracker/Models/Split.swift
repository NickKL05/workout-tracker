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

    /// Stored as raw string; access via `scheduleMode`.
    var scheduleModeRaw: String = SplitScheduleMode.asynchronous.rawValue

    /// 7-element array. Index = Weekday rawValue (0 = Sunday … 6 = Saturday).
    /// Each value is a workout UUID string, or "" for a rest day.
    /// Always length 7 — `weeklyAssignments(...)` getters/setters enforce that.
    var weeklyWorkoutUUIDStrings: [String] = ["", "", "", "", "", "", ""]

    @Relationship var workouts: [Workout] = []

    init(name: String, workouts: [Workout] = []) {
        self.uuid = UUID()
        self.name = name
        self.workouts = workouts
        self.orderedWorkoutUUIDs = workouts.map(\.uuid)
        self.createdAt = Date()
        self.weeklyWorkoutUUIDStrings = Array(repeating: "", count: 7)
    }

    var scheduleMode: SplitScheduleMode {
        get { SplitScheduleMode(rawValue: scheduleModeRaw) ?? .asynchronous }
        set { scheduleModeRaw = newValue.rawValue }
    }

    var orderedWorkouts: [Workout] {
        let byID = Dictionary(uniqueKeysWithValues: workouts.map { ($0.uuid, $0) })
        let ordered = orderedWorkoutUUIDs.compactMap { byID[$0] }
        let missing = workouts.filter { w in !orderedWorkoutUUIDs.contains(w.uuid) }
        return ordered + missing
    }

    /// The workout that the home screen should surface. Mode-aware:
    /// - asynchronous: the workout at `currentIndex` in the rotation.
    /// - scheduled: today's assigned workout (nil = rest day).
    var nextWorkout: Workout? {
        switch scheduleMode {
        case .asynchronous:
            let list = orderedWorkouts
            guard !list.isEmpty else { return nil }
            let idx = max(0, currentIndex) % list.count
            return list[idx]
        case .scheduled:
            return workout(for: Weekday.today)
        }
    }

    /// Workout assigned to a given weekday in `.scheduled` mode (nil = rest day).
    func workout(for weekday: Weekday) -> Workout? {
        let arr = paddedWeeklyAssignments()
        let uuidStr = arr[weekday.rawValue]
        guard !uuidStr.isEmpty, let uuid = UUID(uuidString: uuidStr) else { return nil }
        return workouts.first { $0.uuid == uuid }
    }

    /// Assign (or clear) the workout for a given weekday in `.scheduled` mode.
    func assignWorkout(_ workout: Workout?, for weekday: Weekday) {
        var arr = paddedWeeklyAssignments()
        arr[weekday.rawValue] = workout?.uuid.uuidString ?? ""
        weeklyWorkoutUUIDStrings = arr
    }

    /// Guarantees a length-7 view of `weeklyWorkoutUUIDStrings`.
    private func paddedWeeklyAssignments() -> [String] {
        var arr = weeklyWorkoutUUIDStrings
        while arr.count < 7 { arr.append("") }
        if arr.count > 7 { arr = Array(arr.prefix(7)) }
        return arr
    }

    func setWorkouts(_ list: [Workout]) {
        self.workouts = list
        self.orderedWorkoutUUIDs = list.map(\.uuid)
        if currentIndex >= list.count { currentIndex = 0 }

        // Drop weekly assignments that no longer point at workouts in this split.
        let validIDs = Set(list.map(\.uuid.uuidString))
        weeklyWorkoutUUIDStrings = paddedWeeklyAssignments().map { validIDs.contains($0) ? $0 : "" }
    }

    /// Advance the rotation by one. No-op in `.scheduled` mode — schedule is date-driven.
    func advance() {
        guard scheduleMode == .asynchronous else { return }
        guard !orderedWorkouts.isEmpty else { return }
        currentIndex = (currentIndex + 1) % orderedWorkouts.count
    }
}
