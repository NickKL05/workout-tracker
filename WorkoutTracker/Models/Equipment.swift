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
