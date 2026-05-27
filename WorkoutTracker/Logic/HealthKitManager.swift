import Foundation
import HealthKit

/// Thin wrapper around `HKHealthStore` for saving completed sessions into
/// Apple Health. Single-shared instance because HKHealthStore is expensive
/// to create and authorization is per-app, not per-instance.
///
/// All public methods are safe to call without the user having opted in
/// yet. The Settings toggle and the post-session save both call
/// `requestAuthorization()` so the system dialog only appears once.
final class HealthKitManager {
    static let shared = HealthKitManager()
    private let store = HKHealthStore()

    private init() {}

    var isHealthDataAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    /// Has the user already been shown the system permission dialog?
    var hasRequestedAuthorization: Bool {
        guard isHealthDataAvailable else { return false }
        return store.authorizationStatus(for: HKObjectType.workoutType()) != .notDetermined
    }

    /// True when the app is currently allowed to write workouts.
    var isAuthorizedToWriteWorkouts: Bool {
        guard isHealthDataAvailable else { return false }
        return store.authorizationStatus(for: HKObjectType.workoutType()) == .sharingAuthorized
    }

    /// Show the permission sheet if we haven't already.
    func requestAuthorization() async throws {
        guard isHealthDataAvailable else { throw HealthKitError.notAvailable }
        let toShare: Set<HKSampleType> = [HKObjectType.workoutType()]
        try await store.requestAuthorization(toShare: toShare, read: [])
    }

    /// Persist a previously-summarised session as an HKWorkout.
    ///
    /// We take a plain-value `SessionSummary` rather than the SwiftData
    /// `WorkoutSession` so callers can hop off the main thread without
    /// dragging the model context with them.
    func save(_ summary: SessionSummary) async throws {
        guard isHealthDataAvailable else { throw HealthKitError.notAvailable }

        let config = HKWorkoutConfiguration()
        config.activityType = summary.activityType
        config.locationType = .indoor

        let builder = HKWorkoutBuilder(healthStore: store, configuration: config, device: .local())

        try await builder.beginCollection(at: summary.start)
        if !summary.metadata.isEmpty {
            try await builder.addMetadata(summary.metadata)
        }
        try await builder.endCollection(at: summary.end)
        _ = try await builder.finishWorkout()
    }

    // MARK: - Summary

    /// Snapshot the bits of a finished `WorkoutSession` that HK needs. Call
    /// this on the main thread (where SwiftData @Model objects are safe to
    /// read), then hand the result to `save(_:)` from any context.
    static func summary(for session: WorkoutSession) -> SessionSummary? {
        guard let end = session.endedAt else { return nil }

        let exercises = session.exerciseLogs.compactMap(\.exercise)
        let cardio = exercises.filter { $0.type == .cardio }
        let strength = exercises.filter { $0.type != .cardio }

        let activityType: HKWorkoutActivityType
        if cardio.count > strength.count {
            let equipCounts = Dictionary(grouping: cardio) { $0.equipment }.mapValues(\.count)
            let dominant = equipCounts.max { $0.value < $1.value }?.key
            switch dominant {
            case .bike:      activityType = .cycling
            case .treadmill: activityType = .running
            case .rower:     activityType = .rowing
            default:         activityType = .other
            }
        } else {
            activityType = .traditionalStrengthTraining
        }

        var metadata: [String: Any] = [:]
        if !session.workoutName.isEmpty {
            metadata[HKMetadataKeyWorkoutBrandName] = session.workoutName
        }
        let exerciseList = session.exerciseLogs
            .map(\.exerciseName)
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
        if !exerciseList.isEmpty {
            metadata["WorkoutTrackerExercises"] = exerciseList
        }

        return SessionSummary(
            start: session.startedAt,
            end: end,
            activityType: activityType,
            metadata: metadata
        )
    }
}

/// Plain-value snapshot of a finished session, safe to pass across actors.
struct SessionSummary {
    let start: Date
    let end: Date
    let activityType: HKWorkoutActivityType
    let metadata: [String: Any]
}

enum HealthKitError: LocalizedError {
    case notAvailable
    case sessionNotFinished

    var errorDescription: String? {
        switch self {
        case .notAvailable:       return "Apple Health isn't available on this device."
        case .sessionNotFinished: return "This workout hasn't finished yet."
        }
    }
}
