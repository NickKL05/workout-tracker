import SwiftUI
import SwiftData

@main
struct WorkoutTrackerApp: App {
    let container: ModelContainer
    @StateObject private var appleSignIn = AppleSignInController()

    init() {
        let schema = Schema([
            Exercise.self,
            Workout.self,
            WorkoutExercise.self,
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
        Self.migrateWorkoutsToWorkoutExercises(context: container.mainContext)
    }

    /// One-shot data backfill from legacy `Workout.exercises` into the new
    /// `WorkoutExercise` rows. Idempotent: each workout self-checks and
    /// no-ops once it already has WorkoutExercise children.
    private static func migrateWorkoutsToWorkoutExercises(context: ModelContext) {
        let descriptor = FetchDescriptor<Workout>()
        guard let workouts = try? context.fetch(descriptor) else { return }
        var migrated = false
        for workout in workouts where workout.workoutExercises.isEmpty && !workout.exercises.isEmpty {
            workout.migrateLegacyExercisesIfNeeded(context: context)
            migrated = true
        }
        if migrated {
            try? context.save()
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appleSignIn)
                .preferredColorScheme(.dark)
                .tint(Theme.accent)
                .task {
                    // Validate the cached credential once per launch. If the
                    // user revoked the app from Apple ID settings we fall
                    // back to the gate; otherwise this is a no-op.
                    await appleSignIn.revalidate()
                }
        }
        .modelContainer(container)
    }
}

/// Swaps between the sign-in gate and the main app based on auth state.
/// Stays reactive: signing out from Settings flips it back to the gate.
private struct RootView: View {
    @EnvironmentObject private var appleSignIn: AppleSignInController

    var body: some View {
        if appleSignIn.isSignedIn {
            HomeView()
        } else {
            SignInGateView()
        }
    }
}
