import Foundation

enum MuscleGroup: String, Codable, CaseIterable, Identifiable {
    case chest
    case back
    case shoulders
    case biceps
    case triceps
    case forearms
    case quads
    case hamstrings
    case glutes
    case calves
    case core
    case neck
    case cardio
    case fullBody
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .chest:      return "Chest"
        case .back:       return "Back"
        case .shoulders:  return "Shoulders"
        case .biceps:     return "Biceps"
        case .triceps:    return "Triceps"
        case .forearms:   return "Forearms"
        case .quads:      return "Quads"
        case .hamstrings: return "Hamstrings"
        case .glutes:     return "Glutes"
        case .calves:     return "Calves"
        case .core:       return "Core"
        case .neck:       return "Neck"
        case .cardio:     return "Cardio"
        case .fullBody:   return "Full Body"
        case .other:      return "Other"
        }
    }

    /// Canonical display order used in grouped lists.
    static let displayOrder: [MuscleGroup] = [
        .chest, .back, .shoulders, .biceps, .triceps, .forearms,
        .quads, .hamstrings, .glutes, .calves,
        .core, .neck, .fullBody, .cardio, .other
    ]

    /// Searchable aliases for this muscle group (used in the exercise picker
    /// so e.g. "abs" finds Core exercises, "lats" finds Back exercises).
    var searchAliases: [String] {
        switch self {
        case .chest:      return ["pec", "pecs", "push"]
        case .back:       return ["lat", "lats", "rhomboid", "trap", "traps", "pull"]
        case .shoulders:  return ["delt", "delts", "deltoid", "ohp"]
        case .biceps:     return ["bi", "bis", "arm"]
        case .triceps:    return ["tri", "tris", "arm"]
        case .forearms:   return ["grip", "wrist"]
        case .quads:      return ["quad", "thigh", "leg"]
        case .hamstrings: return ["ham", "hams", "posterior", "leg"]
        case .glutes:     return ["glute", "butt", "hip", "posterior"]
        case .calves:     return ["calf", "leg"]
        case .core:       return ["ab", "abs", "midsection", "obliques"]
        case .neck:       return []
        case .cardio:     return ["conditioning", "aerobic", "z2", "zone 2", "endurance"]
        case .fullBody:   return ["compound", "olympic"]
        case .other:      return []
        }
    }

    /// Keywords that, if found in a workout name, suggest exercises from this group.
    /// Matching is case-insensitive substring.
    var workoutNameKeywords: [String] {
        switch self {
        case .chest:      return ["chest", "push", "bench"]
        case .back:       return ["back", "pull", "row", "lat"]
        case .shoulders:  return ["shoulder", "delt", "push", "overhead"]
        case .biceps:     return ["bicep", "arm", "curl", "pull"]
        case .triceps:    return ["tricep", "arm", "push", "press"]
        case .forearms:   return ["forearm", "arm", "grip"]
        case .quads:      return ["quad", "leg", "squat"]
        case .hamstrings: return ["hamstring", "leg", "ham", "posterior"]
        case .glutes:     return ["glute", "leg", "hip", "posterior"]
        case .calves:     return ["calf", "calves", "leg"]
        case .core:       return ["core", "ab", "abs", "midsection"]
        case .neck:       return ["neck"]
        case .cardio:     return ["cardio", "conditioning", "z2", "ride", "run", "bike"]
        case .fullBody:   return ["full body", "olympic", "athletic"]
        case .other:      return []
        }
    }
}
