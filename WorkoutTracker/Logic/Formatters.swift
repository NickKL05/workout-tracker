import Foundation

enum Format {
    static func elapsed(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%02d:%02d", m, s)
    }

    static func duration(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        if m == 0 { return "\(s)s" }
        if s == 0 { return "\(m)m" }
        return String(format: "%d:%02d", m, s)
    }

    /// Minute-first formatting for cardio: "30 min", "1h 15 min", or
    /// "5 min 30 s" for rare non-round values.
    static func cardioDuration(_ seconds: Int) -> String {
        if seconds <= 0 { return "0 min" }
        if seconds < 60 { return "\(seconds) s" }
        let totalMinutes = seconds / 60
        let remSeconds = seconds % 60
        let h = totalMinutes / 60
        let m = totalMinutes % 60
        if h > 0 {
            if m == 0, remSeconds == 0 { return "\(h)h" }
            if remSeconds == 0 { return "\(h)h \(m) min" }
            return "\(h)h \(m) min \(remSeconds) s"
        }
        if remSeconds == 0 { return "\(m) min" }
        return "\(m) min \(remSeconds) s"
    }

    static func weight(_ value: Double) -> String {
        let int = Int(value)
        if Double(int) == value { return "\(int)" }
        return String(format: "%.1f", value)
    }

    static func date(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: d)
    }

    static func shortDate(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: d)
    }
}
