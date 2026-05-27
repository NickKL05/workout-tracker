import Foundation

/// Fuzzy-ish text matcher for the exercise list / picker search bars.
///
/// Matches a query against an exercise's name, equipment, and muscle group
/// It also understands common gym abbreviations (DB = dumbbell, BB = barbell,
/// KB = kettlebell, Z2 = zone-2 cardio, OHP = overhead press, RDL = romanian
/// deadlift, etc.) so that typing "db curl" or "bb row" returns what a lifter
/// would expect.
enum ExerciseSearch {
    /// True if `query` matches `exercise` once normalized.
    /// Empty queries match everything.
    static func matches(_ exercise: Exercise, query: String) -> Bool {
        let tokens = tokenize(query)
        if tokens.isEmpty { return true }
        let haystack = haystack(for: exercise)
        for token in tokens {
            let expansions = expansions(for: token)
            let any = expansions.contains { haystack.contains($0) }
            if !any { return false }
        }
        return true
    }

    /// Lower-cased word list, splitting on whitespace.
    private static func tokenize(_ query: String) -> [String] {
        query
            .lowercased()
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .map(String.init)
            .filter { !$0.isEmpty }
    }

    /// All strings that the token should be treated as a match for.
    /// Always includes the token itself so partial matches still work.
    private static func expansions(for token: String) -> [String] {
        var out: [String] = [token]
        if let extras = abbreviationTable[token] { out.append(contentsOf: extras) }
        return out
    }

    /// Lower-cased blob containing every searchable field for the exercise.
    private static func haystack(for ex: Exercise) -> String {
        var parts: [String] = [ex.name.lowercased()]

        let equip = ex.equipment
        parts.append(equip.displayName.lowercased())
        parts.append(contentsOf: equip.searchAliases)

        let muscle = ex.muscleGroup
        parts.append(muscle.displayName.lowercased())
        parts.append(contentsOf: muscle.searchAliases)

        let type = ex.type
        parts.append(type.displayName.lowercased())
        if !ex.notes.isEmpty { parts.append(ex.notes.lowercased()) }

        return parts.joined(separator: " ")
    }

    /// Common gym shorthand → expanded forms that should appear in some field.
    private static let abbreviationTable: [String: [String]] = [
        // Equipment
        "db":  ["dumbbell"],
        "dbs": ["dumbbell"],
        "bb":  ["barbell"],
        "kb":  ["kettlebell"],
        "ez":  ["barbell", "curl"],
        "smith": ["barbell", "machine"],

        // Movements
        "ohp": ["overhead", "press", "shoulder"],
        "rdl": ["romanian", "deadlift", "hamstring"],
        "sldl": ["stiff", "leg", "deadlift", "hamstring"],
        "bor": ["bent", "over", "row", "back"],
        "pulldown": ["pull", "down", "back", "lat"],
        "pullup": ["pull", "up", "back"],
        "chinup": ["chin", "up", "back", "biceps"],
        "dl":  ["deadlift"],

        // Cardio zones
        "z1": ["zone", "cardio"],
        "z2": ["zone 2", "cardio", "low intensity"],
        "z3": ["zone", "cardio"],
        "z4": ["zone", "cardio", "tempo"],
        "z5": ["zone", "cardio", "vo2"],
        "liss": ["low intensity", "cardio"],
        "hiit": ["high intensity", "cardio"],

        // Muscle shortcuts
        "abs":   ["core", "midsection"],
        "ab":    ["core"],
        "lats":  ["back", "lat"],
        "lat":   ["back"],
        "tri":   ["triceps"],
        "tris":  ["triceps"],
        "bi":    ["biceps"],
        "bis":   ["biceps"],
        "delts": ["shoulders", "delt"],
        "delt":  ["shoulders"],
        "quad":  ["quads", "leg"],
        "ham":   ["hamstrings"],
        "hams":  ["hamstrings"],
        "calf":  ["calves"],
        "pec":   ["chest"],
        "pecs":  ["chest"],
        "glute": ["glutes"],
    ]
}
