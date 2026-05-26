import SwiftUI
import SwiftData

@main
struct WorkoutTrackerApp: App {
    let container: ModelContainer

    init() {
        let schema = Schema([
            Exercise.self,
            Workout.self,
            Split.self,
            WorkoutSession.self,
            ExerciseLog.self,
            SetLog.self,
        ])
        do {
            container = try ModelContainer(for: schema)
        } catch {
            fatalError("Failed to initialize SwiftData container: \(error)")
        }
        ExerciseSeeder.seedIfNeeded(context: container.mainContext)
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
                .preferredColorScheme(.dark)
                .tint(Theme.accent)
        }
        .modelContainer(container)
    }
}
