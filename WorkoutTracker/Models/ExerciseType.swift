import Foundation

enum ExerciseType: String, Codable, CaseIterable, Identifiable {
    case weightReps      // bench press, curl
    case weightTime      // weighted plank
    case cardio          // running, rowing — time + intensity

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .weightReps: return "Weight & Reps"
        case .weightTime: return "Weight & Time"
        case .cardio:     return "Cardio"
        }
    }

    /// Short label for segmented pickers where horizontal space is tight.
    var shortLabel: String {
        switch self {
        case .weightReps: return "Reps"
        case .weightTime: return "Time"
        case .cardio:     return "Cardio"
        }
    }

    var tracksReps: Bool { self == .weightReps }
    var tracksTime: Bool { self == .weightTime || self == .cardio }
    var tracksWeight: Bool { self == .weightReps || self == .weightTime }
    var tracksIntensity: Bool { self == .cardio }
}
