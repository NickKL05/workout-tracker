import Foundation

enum SplitScheduleMode: String, Codable, CaseIterable, Identifiable {
    case scheduled      // each weekday is bound to a specific workout (or rest)
    case asynchronous   // advance one workout each time you finish a session

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .scheduled:    return "Weekly schedule"
        case .asynchronous: return "Rotation"
        }
    }

    var shortLabel: String {
        switch self {
        case .scheduled:    return "Weekly"
        case .asynchronous: return "Rotation"
        }
    }

    var explainer: String {
        switch self {
        case .scheduled:
            return "Pin each day of the week to a specific workout (or rest day). Best when your training days are consistent, like Monday is always legs."
        case .asynchronous:
            return "Keeps your workouts in a loop and just picks up wherever you left off. Finish a session and the next one in the list becomes “up next”, no calendar required. Great when your week is unpredictable."
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

    /// Order to show in the editor. Starts on Monday to feel like a gym week.
    static let displayOrder: [Weekday] = [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday]

    static var today: Weekday {
        let raw = Calendar.current.component(.weekday, from: Date()) - 1
        return Weekday(rawValue: raw) ?? .monday
    }
}
