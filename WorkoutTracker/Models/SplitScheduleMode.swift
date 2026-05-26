import Foundation

enum SplitScheduleMode: String, Codable, CaseIterable, Identifiable {
    case asynchronous   // advance one workout each time you finish a session
    case scheduled      // each weekday is bound to a specific workout (or rest)

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .asynchronous: return "Asynchronous"
        case .scheduled:    return "Set schedule"
        }
    }

    var shortLabel: String {
        switch self {
        case .asynchronous: return "Async"
        case .scheduled:    return "Schedule"
        }
    }

    var explainer: String {
        switch self {
        case .asynchronous:
            return "Plays workouts in order. Advances by one after each completed session."
        case .scheduled:
            return "Each day of the week is pinned to a specific workout (or rest)."
        }
    }
}

/// 0 = Sunday … 6 = Saturday (matches Calendar.weekday - 1).
enum Weekday: Int, CaseIterable, Identifiable {
    case sunday = 0, monday, tuesday, wednesday, thursday, friday, saturday

    var id: Int { rawValue }

    var shortName: String {
        switch self {
        case .sunday:    return "Sun"
        case .monday:    return "Mon"
        case .tuesday:   return "Tue"
        case .wednesday: return "Wed"
        case .thursday:  return "Thu"
        case .friday:    return "Fri"
        case .saturday:  return "Sat"
        }
    }

    var displayName: String {
        switch self {
        case .sunday:    return "Sunday"
        case .monday:    return "Monday"
        case .tuesday:   return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday:  return "Thursday"
        case .friday:    return "Friday"
        case .saturday:  return "Saturday"
        }
    }

    /// Order to show in the editor — start week on Monday to feel like a gym week.
    static let displayOrder: [Weekday] = [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday]

    static var today: Weekday {
        let raw = Calendar.current.component(.weekday, from: Date()) - 1
        return Weekday(rawValue: raw) ?? .monday
    }
}
