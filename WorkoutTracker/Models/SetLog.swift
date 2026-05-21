import Foundation
import SwiftData

@Model
final class SetLog {
    var setNumber: Int = 1
    var weight: Double = 0          // lbs
    var reps: Int = 0               // bilateral or aggregate
    var leftReps: Int = 0           // unilateral left
    var rightReps: Int = 0          // unilateral right
    var durationSeconds: Int = 0    // for timed exercises
    var intensity: Int = 0          // 1-10 for cardio
    var completed: Bool = false
    var loggedAt: Date = Date()

    init(setNumber: Int = 1) {
        self.setNumber = setNumber
        self.loggedAt = Date()
    }
}
