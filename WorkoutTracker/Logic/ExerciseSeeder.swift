import Foundation
import SwiftData

enum ExerciseSeeder {
    /// Insert all preset exercises if the store has none. Safe to call on every launch.
    static func seedIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<Exercise>()
        let existingCount = (try? context.fetchCount(descriptor)) ?? 0
        guard existingCount == 0 else { return }

        for preset in ExerciseSeed.all {
            let ex = Exercise(
                name: preset.name,
                type: preset.type,
                isUnilateral: preset.isUnilateral,
                muscleGroup: preset.muscleGroup,
                equipment: preset.equipment,
                goalSets: preset.goalSets,
                goalReps: preset.goalReps,
                goalDurationSeconds: preset.goalDurationSeconds,
                goalIntensity: preset.goalIntensity,
                weightIncrement: preset.equipment.defaultWeightIncrement
            )
            context.insert(ex)
        }
        try? context.save()
    }
}
