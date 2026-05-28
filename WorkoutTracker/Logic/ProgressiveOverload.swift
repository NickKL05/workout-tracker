import Foundation

struct OverloadSuggestion {
    /// Human-readable suggestion line, e.g. "Try 135 lbs × 8 reps"
    let summary: String
    /// New weight for weightReps / weightTime exercises (lbs)
    let suggestedWeight: Double?
    /// New duration in seconds for weightTime / cardio
    let suggestedDurationSeconds: Int?
    /// New intensity for cardio
    let suggestedIntensity: Int?
    /// True when the prior session hit all goal sets at goal reps/duration
    let metGoalPreviously: Bool
}

enum ProgressiveOverload {
    /// Compute a target for the current session based on the previous one.
    /// Goals come from the live `current` log (session-editable). Increment
    /// sizes come from the underlying Exercise (physics of the equipment).
    static func suggest(current: ExerciseLog, previous: ExerciseLog?, exercise: Exercise) -> OverloadSuggestion {
        guard let prev = previous else {
            return baseline(for: current)
        }

        let metGoal = prev.hitGoalAcrossAllSets

        switch current.exerciseType {
        case .weightReps:
            let baseWeight = prev.topWeight
            if metGoal {
                let newW = baseWeight + exercise.weightIncrement
                return OverloadSuggestion(
                    summary: "Hit goal last time. Try \(format(newW)) lbs × \(current.goalReps) reps",
                    suggestedWeight: newW,
                    suggestedDurationSeconds: nil,
                    suggestedIntensity: nil,
                    metGoalPreviously: true
                )
            } else {
                return OverloadSuggestion(
                    summary: "Last time: \(format(baseWeight)) lbs. Push for \(current.goalSets)×\(current.goalReps)",
                    suggestedWeight: baseWeight,
                    suggestedDurationSeconds: nil,
                    suggestedIntensity: nil,
                    metGoalPreviously: false
                )
            }

        case .weightTime:
            let baseWeight = prev.topWeight
            let lastDuration = prev.orderedSets.map { $0.durationSeconds }.max() ?? 0
            if metGoal {
                let newW = baseWeight + exercise.weightIncrement
                return OverloadSuggestion(
                    summary: "Hit goal. Try \(format(newW)) lbs × \(formatDuration(current.goalDurationSeconds))",
                    suggestedWeight: newW,
                    suggestedDurationSeconds: current.goalDurationSeconds,
                    suggestedIntensity: nil,
                    metGoalPreviously: true
                )
            } else {
                return OverloadSuggestion(
                    summary: "Last: \(format(baseWeight)) lbs × \(formatDuration(lastDuration)). Aim for \(formatDuration(current.goalDurationSeconds))",
                    suggestedWeight: baseWeight,
                    suggestedDurationSeconds: current.goalDurationSeconds,
                    suggestedIntensity: nil,
                    metGoalPreviously: false
                )
            }

        case .cardio:
            let lastDuration = prev.orderedSets.map { $0.durationSeconds }.max() ?? 0
            let lastIntensity = prev.orderedSets.map { $0.intensity }.max() ?? 0
            if metGoal {
                if lastIntensity < 10 {
                    let newI = min(10, lastIntensity + exercise.intensityIncrement)
                    return OverloadSuggestion(
                        summary: "Hit goal. Try intensity \(newI) for \(Format.cardioDuration(current.goalDurationSeconds))",
                        suggestedWeight: nil,
                        suggestedDurationSeconds: current.goalDurationSeconds,
                        suggestedIntensity: newI,
                        metGoalPreviously: true
                    )
                } else {
                    let newD = lastDuration + exercise.durationIncrementSeconds
                    return OverloadSuggestion(
                        summary: "Maxed intensity. Try \(Format.cardioDuration(newD)) at intensity 10",
                        suggestedWeight: nil,
                        suggestedDurationSeconds: newD,
                        suggestedIntensity: 10,
                        metGoalPreviously: true
                    )
                }
            } else {
                return OverloadSuggestion(
                    summary: "Last: \(Format.cardioDuration(lastDuration)) @ int \(lastIntensity). Aim for goal",
                    suggestedWeight: nil,
                    suggestedDurationSeconds: current.goalDurationSeconds,
                    suggestedIntensity: current.goalIntensity,
                    metGoalPreviously: false
                )
            }
        }
    }

    private static func baseline(for log: ExerciseLog) -> OverloadSuggestion {
        let summary: String
        switch log.exerciseType {
        case .weightReps:
            summary = "Goal: \(log.goalSets)×\(log.goalReps)"
        case .weightTime:
            summary = "Goal: \(log.goalSets)×\(formatDuration(log.goalDurationSeconds))"
        case .cardio:
            summary = "Goal: \(Format.cardioDuration(log.goalDurationSeconds)) @ intensity \(log.goalIntensity)"
        }
        return OverloadSuggestion(
            summary: summary,
            suggestedWeight: nil,
            suggestedDurationSeconds: log.exerciseType == .weightReps ? nil : log.goalDurationSeconds,
            suggestedIntensity: log.exerciseType == .cardio ? log.goalIntensity : nil,
            metGoalPreviously: false
        )
    }

    private static func format(_ weight: Double) -> String {
        let int = Int(weight)
        if Double(int) == weight { return "\(int)" }
        return String(format: "%.1f", weight)
    }

    static func formatDuration(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        if m == 0 { return "\(s)s" }
        if s == 0 { return "\(m)m" }
        return String(format: "%d:%02d", m, s)
    }
}
