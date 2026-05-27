import Foundation

enum Equipment: String, Codable, CaseIterable, Identifiable {
    case barbell
    case dumbbell
    case cable
    case machine
    case bodyweight
    case kettlebell
    case bike
    case treadmill
    case rower
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .barbell:    return "Barbell"
        case .dumbbell:   return "Dumbbell"
        case .cable:      return "Cable"
        case .machine:    return "Machine"
        case .bodyweight: return "Bodyweight"
        case .kettlebell: return "Kettlebell"
        case .bike:       return "Bike"
        case .treadmill:  return "Treadmill"
        case .rower:      return "Rower"
        case .other:      return "Other"
        }
    }

    /// Alternate names / abbreviations searchable in the exercise picker.
    /// Pure lowercase, no display names (those are matched separately).
    var searchAliases: [String] {
        switch self {
        case .barbell:    return ["bb", "bar"]
        case .dumbbell:   return ["db", "dbs"]
        case .cable:      return ["pulley"]
        case .machine:    return ["selectorized", "plate loaded"]
        case .bodyweight: return ["bw", "no weight"]
        case .kettlebell: return ["kb"]
        case .bike:       return ["cycle", "spin", "cardio"]
        case .treadmill:  return ["run", "walk", "cardio"]
        case .rower:      return ["row", "erg", "cardio"]
        case .other:      return []
        }
    }

    /// Default progressive-overload weight step (lbs) for this equipment.
    var defaultWeightIncrement: Double {
        switch self {
        case .barbell:    return 5.0
        case .dumbbell:   return 2.5
        case .cable:      return 2.5
        case .machine:    return 5.0
        case .kettlebell: return 4.0
        case .bodyweight: return 2.5
        default:          return 5.0
        }
    }
}
