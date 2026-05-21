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
    /// Compute a target for the upcoming session based on the previous session.
    static func suggest(for exercise: Exercise, previous: ExerciseLog?) -> OverloadSuggestion {
        guard let prev = previous else {
            // First time doing this exercise: anchor on goals only.
            return baseline(for: exercise)
        }

        let metGoal = prev.hitGoalAcrossAllSets

        switch exercise.type {
        case .weightReps:
            let baseWeight = prev.topWeight
            if metGoal {
                let newW = baseWeight + exercise.weightIncrement
                return OverloadSuggestion(
                    summary: "Hit goal last time — try \(format(newW)) lbs × \(exercise.goalReps) reps",
                    suggestedWeight: newW,
                    suggestedDurationSeconds: nil,
                    suggestedIntensity: nil,
                    metGoalPreviously: true
                )
            } else {
                return OverloadSuggestion(
                    summary: "Last time: \(format(baseWeight)) lbs — push for \(exercise.goalSets)×\(exercise.goalReps)",
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
                    summary: "Hit goal — try \(format(newW)) lbs × \(formatDuration(exercise.goalDurationSeconds))",
                    suggestedWeight: newW,
                    suggestedDurationSeconds: exercise.goalDurationSeconds,
                    suggestedIntensity: nil,
                    metGoalPreviously: true
                )
            } else {
                return OverloadSuggestion(
                    summary: "Last: \(format(baseWeight)) lbs × \(formatDuration(lastDuration)) — aim for \(formatDuration(exercise.goalDurationSeconds))",
                    suggestedWeight: baseWeight,
                    suggestedDurationSeconds: exercise.goalDurationSeconds,
                    suggestedIntensity: nil,
                    metGoalPreviously: false
                )
            }

        case .cardio:
            let lastDuration = prev.orderedSets.map { $0.durationSeconds }.max() ?? 0
            let lastIntensity = prev.orderedSets.map { $0.intensity }.max() ?? 0
            if metGoal {
                // Prefer bumping intensity; if at max (10), bump duration.
                if lastIntensity < 10 {
                    let newI = min(10, lastIntensity + exercise.intensityIncrement)
                    return OverloadSuggestion(
                        summary: "Hit goal — try intensity \(newI) for \(formatDuration(exercise.goalDurationSeconds))",
                        suggestedWeight: nil,
                        suggestedDurationSeconds: exercise.goalDurationSeconds,
                        suggestedIntensity: newI,
                        metGoalPreviously: true
                    )
                } else {
                    let newD = lastDuration + exercise.durationIncrementSeconds
                    return OverloadSuggestion(
                        summary: "Maxed intensity — try \(formatDuration(newD)) at intensity 10",
                        suggestedWeight: nil,
                        suggestedDurationSeconds: newD,
                        suggestedIntensity: 10,
                        metGoalPreviously: true
                    )
                }
            } else {
                return OverloadSuggestion(
                    summary: "Last: \(formatDuration(lastDuration)) @ int \(lastIntensity) — aim for goal",
                    suggestedWeight: nil,
                    suggestedDurationSeconds: exercise.goalDurationSeconds,
                    suggestedIntensity: exercise.goalIntensity,
                    metGoalPreviously: false
                )
            }
        }
    }

    private static func baseline(for ex: Exercise) -> OverloadSuggestion {
        let summary: String
        switch ex.type {
        case .weightReps:
            summary = "Goal: \(ex.goalSets)×\(ex.goalReps)"
        case .weightTime:
            summary = "Goal: \(ex.goalSets)×\(formatDuration(ex.goalDurationSeconds))"
        case .cardio:
            summary = "Goal: \(formatDuration(ex.goalDurationSeconds)) @ intensity \(ex.goalIntensity)"
        }
        return OverloadSuggestion(
            summary: summary,
            suggestedWeight: nil,
            suggestedDurationSeconds: ex.type == .weightReps ? nil : ex.goalDurationSeconds,
            suggestedIntensity: ex.type == .cardio ? ex.goalIntensity : nil,
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
