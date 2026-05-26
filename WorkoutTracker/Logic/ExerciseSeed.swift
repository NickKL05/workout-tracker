import Foundation
import SwiftData

/// A seed-only blueprint for an Exercise. Converted into an `Exercise` row by `ExerciseSeeder`.
struct PresetExercise {
    let name: String
    let type: ExerciseType
    let muscleGroup: MuscleGroup
    let equipment: Equipment
    var isUnilateral: Bool = false
    var goalSets: Int = 3
    var goalReps: Int = 8
    var goalDurationSeconds: Int = 30
    var goalIntensity: Int = 5
}

// MARK: - Compact builders

private func bb(_ name: String, _ m: MuscleGroup, sets: Int = 3, reps: Int = 8, unilateral: Bool = false) -> PresetExercise {
    PresetExercise(name: name, type: .weightReps, muscleGroup: m, equipment: .barbell,
                   isUnilateral: unilateral, goalSets: sets, goalReps: reps)
}

private func db(_ name: String, _ m: MuscleGroup, sets: Int = 3, reps: Int = 10, unilateral: Bool = false) -> PresetExercise {
    PresetExercise(name: name, type: .weightReps, muscleGroup: m, equipment: .dumbbell,
                   isUnilateral: unilateral, goalSets: sets, goalReps: reps)
}

private func cb(_ name: String, _ m: MuscleGroup, sets: Int = 3, reps: Int = 12, unilateral: Bool = false) -> PresetExercise {
    PresetExercise(name: name, type: .weightReps, muscleGroup: m, equipment: .cable,
                   isUnilateral: unilateral, goalSets: sets, goalReps: reps)
}

private func mc(_ name: String, _ m: MuscleGroup, sets: Int = 3, reps: Int = 10, unilateral: Bool = false) -> PresetExercise {
    PresetExercise(name: name, type: .weightReps, muscleGroup: m, equipment: .machine,
                   isUnilateral: unilateral, goalSets: sets, goalReps: reps)
}

private func bw(_ name: String, _ m: MuscleGroup, sets: Int = 3, reps: Int = 10, unilateral: Bool = false) -> PresetExercise {
    PresetExercise(name: name, type: .weightReps, muscleGroup: m, equipment: .bodyweight,
                   isUnilateral: unilateral, goalSets: sets, goalReps: reps)
}

private func kb(_ name: String, _ m: MuscleGroup, sets: Int = 3, reps: Int = 10, unilateral: Bool = false) -> PresetExercise {
    PresetExercise(name: name, type: .weightReps, muscleGroup: m, equipment: .kettlebell,
                   isUnilateral: unilateral, goalSets: sets, goalReps: reps)
}

private func timed(_ name: String, _ m: MuscleGroup, _ equip: Equipment = .bodyweight, sets: Int = 3, seconds: Int = 45) -> PresetExercise {
    PresetExercise(name: name, type: .weightTime, muscleGroup: m, equipment: equip,
                   goalSets: sets, goalDurationSeconds: seconds)
}

private func card(_ name: String, _ equip: Equipment = .other, minutes: Int = 30, intensity: Int = 5) -> PresetExercise {
    PresetExercise(name: name, type: .cardio, muscleGroup: .cardio, equipment: equip,
                   goalSets: 1, goalDurationSeconds: minutes * 60, goalIntensity: intensity)
}

// MARK: - Seed catalog

enum ExerciseSeed {
    static var all: [PresetExercise] {
        chest + back + shoulders + biceps + triceps + forearms +
        quads + hamstrings + glutes + calves +
        core + neck + fullBody + cardio
    }

    // MARK: Chest
    static let chest: [PresetExercise] = [
        bb("BB Flat Bench Press", .chest, sets: 3, reps: 5),
        bb("BB Incline Bench Press", .chest, sets: 3, reps: 5),
        bb("BB Decline Bench Press", .chest, sets: 3, reps: 6),
        bb("BB Close Grip Bench Press", .chest, sets: 3, reps: 5),
        bb("BB Pause Bench Press", .chest, sets: 3, reps: 4),
        bb("BB Floor Press", .chest, sets: 3, reps: 5),
        bb("BB Spoto Press", .chest, sets: 3, reps: 5),

        db("DB Flat Bench Press", .chest, sets: 3, reps: 8),
        db("DB Incline Bench Press", .chest, sets: 3, reps: 8),
        db("DB Decline Bench Press", .chest, sets: 3, reps: 8),
        db("DB Chest Press", .chest, sets: 3, reps: 8),
        db("DB Flat Fly", .chest, sets: 3, reps: 12),
        db("DB Incline Fly", .chest, sets: 3, reps: 12),
        db("DB Squeeze Press", .chest, sets: 3, reps: 10),
        db("DB Pullover", .chest, sets: 3, reps: 12),

        cb("Cable Chest Press", .chest, sets: 3, reps: 10),
        cb("Cable Incline Press", .chest, sets: 3, reps: 10),
        cb("Cable Crossover (High to Low)", .chest, sets: 3, reps: 12),
        cb("Cable Crossover (Low to High)", .chest, sets: 3, reps: 12),
        cb("Cable Crossover (Mid)", .chest, sets: 3, reps: 12),
        cb("Cable Pec Fly", .chest, sets: 3, reps: 12),

        mc("Pec Deck", .chest, sets: 3, reps: 12),
        mc("Machine Chest Press", .chest, sets: 3, reps: 8),
        mc("Machine Incline Press", .chest, sets: 3, reps: 8),
        mc("Smith Machine Bench Press", .chest, sets: 3, reps: 8),
        mc("Smith Machine Incline Press", .chest, sets: 3, reps: 8),

        bw("Push-Up", .chest, sets: 3, reps: 15),
        bw("Incline Push-Up", .chest, sets: 3, reps: 20),
        bw("Decline Push-Up", .chest, sets: 3, reps: 12),
        bw("Diamond Push-Up", .chest, sets: 3, reps: 10),
        bw("Archer Push-Up", .chest, sets: 3, reps: 6, unilateral: true),
        bw("Ring Push-Up", .chest, sets: 3, reps: 10),
        bw("Chest Dip", .chest, sets: 3, reps: 8),
    ]

    // MARK: Back
    static let back: [PresetExercise] = [
        bb("BB Bent Over Row", .back, sets: 3, reps: 5),
        bb("BB Pendlay Row", .back, sets: 3, reps: 5),
        bb("BB Yates Row", .back, sets: 3, reps: 6),
        bb("BB Deadlift", .back, sets: 3, reps: 5),
        bb("BB Snatch Grip Deadlift", .back, sets: 3, reps: 5),
        bb("BB Rack Pull", .back, sets: 3, reps: 5),
        bb("BB Shrug", .back, sets: 3, reps: 10),
        bb("BB T-Bar Row", .back, sets: 3, reps: 8),
        bb("BB Meadows Row", .back, sets: 3, reps: 8, unilateral: true),

        db("DB Row", .back, sets: 3, reps: 10, unilateral: true),
        db("DB Chest-Supported Row", .back, sets: 3, reps: 10),
        db("DB Pullover", .back, sets: 3, reps: 12),
        db("DB Shrug", .back, sets: 3, reps: 12),
        db("DB Kroc Row", .back, sets: 3, reps: 20, unilateral: true),

        cb("Wide Grip Lat Pulldown", .back, sets: 3, reps: 8),
        cb("Close Neutral Grip Lat Pulldown", .back, sets: 3, reps: 8),
        cb("Reverse Grip Lat Pulldown", .back, sets: 3, reps: 8),
        cb("V-Grip Lat Pulldown", .back, sets: 3, reps: 8),
        cb("Single Arm Lat Pulldown", .back, sets: 3, reps: 10, unilateral: true),
        cb("Cable Pullover", .back, sets: 3, reps: 12),
        cb("Cable Straight-Arm Pulldown", .back, sets: 3, reps: 12),
        cb("Seated Cable Row", .back, sets: 3, reps: 10),
        cb("Cable Single Arm Row", .back, sets: 3, reps: 10, unilateral: true),
        cb("Face Pull", .back, sets: 3, reps: 15),
        cb("Cable Rear Delt Fly", .back, sets: 3, reps: 15, unilateral: true),
        cb("Cable Shrug", .back, sets: 3, reps: 12),

        mc("Machine Row", .back, sets: 3, reps: 8),
        mc("Machine High Row", .back, sets: 3, reps: 8),
        mc("Machine Pulldown", .back, sets: 3, reps: 8),
        mc("Hammer Strength Row", .back, sets: 3, reps: 8),
        mc("Hammer Strength High Row", .back, sets: 3, reps: 8),
        mc("Hammer Strength Pulldown", .back, sets: 3, reps: 8),
        mc("Machine Back Extension", .back, sets: 3, reps: 12),
        mc("Smith Machine Row", .back, sets: 3, reps: 8),

        bw("Pull-Up", .back, sets: 3, reps: 8),
        bw("Chin-Up", .back, sets: 3, reps: 8),
        bw("Neutral Grip Pull-Up", .back, sets: 3, reps: 8),
        bw("Wide Grip Pull-Up", .back, sets: 3, reps: 6),
        bw("Inverted Row", .back, sets: 3, reps: 10),
        bw("Ring Row", .back, sets: 3, reps: 10),
        bw("Hyperextension", .back, sets: 3, reps: 12),
        bw("Reverse Hyperextension", .back, sets: 3, reps: 12),
    ]

    // MARK: Shoulders
    static let shoulders: [PresetExercise] = [
        bb("BB Overhead Press", .shoulders, sets: 3, reps: 5),
        bb("BB Push Press", .shoulders, sets: 3, reps: 5),
        bb("BB Behind-the-Neck Press", .shoulders, sets: 3, reps: 6),
        bb("BB Z-Press", .shoulders, sets: 3, reps: 6),
        bb("BB Landmine Press", .shoulders, sets: 3, reps: 8, unilateral: true),
        bb("BB Front Raise", .shoulders, sets: 3, reps: 12),
        bb("BB Upright Row", .shoulders, sets: 3, reps: 10),

        db("DB Overhead Press", .shoulders, sets: 3, reps: 8),
        db("DB Seated Overhead Press", .shoulders, sets: 3, reps: 8),
        db("DB Arnold Press", .shoulders, sets: 3, reps: 10),
        db("DB Lateral Raise", .shoulders, sets: 3, reps: 12),
        db("DB Front Raise", .shoulders, sets: 3, reps: 12),
        db("DB Rear Delt Fly", .shoulders, sets: 3, reps: 15),
        db("DB Bent Over Reverse Fly", .shoulders, sets: 3, reps: 15),
        db("DB Shrug", .shoulders, sets: 3, reps: 12),
        db("DB Lying Rear Delt Raise", .shoulders, sets: 3, reps: 15),

        cb("Cable Lateral Raise", .shoulders, sets: 4, reps: 15, unilateral: true),
        cb("Cable Front Raise", .shoulders, sets: 3, reps: 12),
        cb("Cable Rear Delt Fly", .shoulders, sets: 3, reps: 15, unilateral: true),
        cb("Cable Upright Row", .shoulders, sets: 3, reps: 12),
        cb("Cable Y-Raise", .shoulders, sets: 3, reps: 12),
        cb("Cable Reverse Fly", .shoulders, sets: 3, reps: 15),
        cb("Cable External Rotation", .shoulders, sets: 3, reps: 15, unilateral: true),
        cb("Cable Internal Rotation", .shoulders, sets: 3, reps: 15, unilateral: true),

        mc("Machine Shoulder Press", .shoulders, sets: 3, reps: 8),
        mc("Machine Lateral Raise", .shoulders, sets: 3, reps: 12),
        mc("Smith Machine Overhead Press", .shoulders, sets: 3, reps: 8),
        mc("Reverse Pec Deck", .shoulders, sets: 3, reps: 15),

        bw("Pike Push-Up", .shoulders, sets: 3, reps: 10),
        bw("Handstand Push-Up", .shoulders, sets: 3, reps: 5),
        bw("Wall Walk", .shoulders, sets: 3, reps: 3),
    ]

    // MARK: Biceps
    static let biceps: [PresetExercise] = [
        bb("BB Curl", .biceps, sets: 3, reps: 8),
        bb("BB EZ-Bar Curl", .biceps, sets: 3, reps: 10),
        bb("BB Reverse Curl", .biceps, sets: 3, reps: 10),
        bb("BB Drag Curl", .biceps, sets: 3, reps: 10),
        bb("BB Preacher Curl", .biceps, sets: 3, reps: 10),
        bb("BB Spider Curl", .biceps, sets: 3, reps: 12),

        db("DB Bicep Curl", .biceps, sets: 3, reps: 8, unilateral: true),
        db("DB Hammer Curl", .biceps, sets: 3, reps: 8),
        db("DB Incline Curl", .biceps, sets: 3, reps: 12, unilateral: true),
        db("DB Concentration Curl", .biceps, sets: 3, reps: 12, unilateral: true),
        db("DB Preacher Curl", .biceps, sets: 3, reps: 10, unilateral: true),
        db("DB Spider Curl", .biceps, sets: 3, reps: 12),
        db("DB Cross Body Hammer Curl", .biceps, sets: 3, reps: 10),
        db("DB Zottman Curl", .biceps, sets: 3, reps: 10),
        db("DB Seated Curl", .biceps, sets: 3, reps: 10),

        cb("Cable Curl (Straight Bar)", .biceps, sets: 3, reps: 12),
        cb("Cable Curl (EZ Bar)", .biceps, sets: 3, reps: 12),
        cb("Cable Rope Hammer Curl", .biceps, sets: 3, reps: 12),
        cb("High Cable Curl", .biceps, sets: 3, reps: 12),
        cb("Cable Single Arm Curl", .biceps, sets: 3, reps: 12, unilateral: true),
        cb("Cable Bayesian Curl", .biceps, sets: 3, reps: 12, unilateral: true),
        cb("Cable Preacher Curl", .biceps, sets: 3, reps: 12),

        mc("Preacher Curl Machine", .biceps, sets: 3, reps: 12, unilateral: true),
        mc("Machine Bicep Curl", .biceps, sets: 3, reps: 12),
    ]

    // MARK: Triceps
    static let triceps: [PresetExercise] = [
        bb("BB Close Grip Bench Press", .triceps, sets: 3, reps: 6),
        bb("BB Skullcrusher", .triceps, sets: 3, reps: 10),
        bb("BB JM Press", .triceps, sets: 3, reps: 8),
        bb("BB Reverse Grip Bench Press", .triceps, sets: 3, reps: 8),

        db("DB Skullcrusher", .triceps, sets: 3, reps: 10),
        db("DB Overhead Tricep Extension", .triceps, sets: 3, reps: 12),
        db("DB Single Arm Overhead Extension", .triceps, sets: 3, reps: 12, unilateral: true),
        db("DB Tricep Kickback", .triceps, sets: 3, reps: 12, unilateral: true),
        db("DB Close Grip Press", .triceps, sets: 3, reps: 10),
        db("DB Tate Press", .triceps, sets: 3, reps: 10),

        cb("Cable Tricep Pushdown (Rope)", .triceps, sets: 3, reps: 12),
        cb("Cable Tricep Pushdown (Bar)", .triceps, sets: 3, reps: 12),
        cb("Cable Tricep Pushdown (V-Bar)", .triceps, sets: 3, reps: 12),
        cb("Cable Tricep Extension (D Handle)", .triceps, sets: 3, reps: 8, unilateral: true),
        cb("Cable Overhead Tricep Extension", .triceps, sets: 3, reps: 12, unilateral: true),
        cb("Cable Overhead Tricep Extension (Rope)", .triceps, sets: 3, reps: 12),
        cb("Cable Reverse Grip Pushdown", .triceps, sets: 3, reps: 12),
        cb("Cable Cross Body Tricep Extension", .triceps, sets: 3, reps: 12, unilateral: true),
        cb("Cable Kickback", .triceps, sets: 3, reps: 12, unilateral: true),

        mc("Machine Tricep Extension", .triceps, sets: 3, reps: 12),
        mc("Machine Dip", .triceps, sets: 3, reps: 8),

        bw("Bench Dip", .triceps, sets: 3, reps: 12),
        bw("Tricep Dip", .triceps, sets: 3, reps: 8),
        bw("Diamond Push-Up", .triceps, sets: 3, reps: 10),
    ]

    // MARK: Forearms
    static let forearms: [PresetExercise] = [
        db("DB Wrist Curl", .forearms, sets: 3, reps: 15),
        db("DB Reverse Wrist Curl", .forearms, sets: 3, reps: 15),
        db("DB Wrist Curl + Reverse Wrist Curl", .forearms, sets: 2, reps: 15),
        db("DB Farmer Carry", .forearms, sets: 3, reps: 1),
        bb("BB Wrist Curl", .forearms, sets: 3, reps: 15),
        bb("BB Reverse Wrist Curl", .forearms, sets: 3, reps: 15),
        bb("BB Reverse Curl", .forearms, sets: 3, reps: 10),
        cb("Cable Wrist Curl", .forearms, sets: 3, reps: 15),
        cb("Cable Reverse Wrist Curl", .forearms, sets: 3, reps: 15),
        bw("Dead Hang", .forearms, sets: 3, reps: 1),
        timed("Plate Pinch Hold", .forearms, .other, sets: 3, seconds: 30),
        timed("Towel Hang", .forearms, .bodyweight, sets: 3, seconds: 30),
    ]

    // MARK: Quads
    static let quads: [PresetExercise] = [
        bb("BB Back Squat", .quads, sets: 3, reps: 5),
        bb("BB High Bar Squat", .quads, sets: 3, reps: 5),
        bb("BB Front Squat", .quads, sets: 3, reps: 5),
        bb("BB Pause Squat", .quads, sets: 3, reps: 4),
        bb("BB Box Squat", .quads, sets: 3, reps: 5),
        bb("BB Tempo Squat", .quads, sets: 3, reps: 5),
        bb("BB Zercher Squat", .quads, sets: 3, reps: 8),
        bb("BB Bulgarian Split Squat", .quads, sets: 3, reps: 8, unilateral: true),
        bb("BB Lunge", .quads, sets: 3, reps: 10, unilateral: true),
        bb("BB Hack Squat", .quads, sets: 3, reps: 8),

        db("DB Goblet Squat", .quads, sets: 3, reps: 10),
        db("DB Bulgarian Split Squat", .quads, sets: 3, reps: 8, unilateral: true),
        db("DB Lunge", .quads, sets: 3, reps: 10, unilateral: true),
        db("DB Reverse Lunge", .quads, sets: 3, reps: 10, unilateral: true),
        db("DB Walking Lunge", .quads, sets: 3, reps: 12, unilateral: true),
        db("DB Step Up", .quads, sets: 3, reps: 8, unilateral: true),
        db("DB Sissy Squat", .quads, sets: 3, reps: 10),

        mc("Machine Leg Press", .quads, sets: 3, reps: 8, unilateral: true),
        mc("Machine Hack Squat", .quads, sets: 3, reps: 5),
        mc("Smith Machine Squat", .quads, sets: 3, reps: 8),
        mc("Smith Machine Bulgarian Split Squat", .quads, sets: 3, reps: 8, unilateral: true),
        mc("Pendulum Squat", .quads, sets: 3, reps: 8),
        mc("Belt Squat", .quads, sets: 3, reps: 8),
        mc("Seated Leg Extension", .quads, sets: 3, reps: 15, unilateral: true),
        mc("Sissy Squat Machine", .quads, sets: 3, reps: 12),

        bw("Bodyweight Squat", .quads, sets: 3, reps: 20),
        bw("Pistol Squat", .quads, sets: 3, reps: 5, unilateral: true),
        bw("Wall Sit", .quads, sets: 3, reps: 1),
        bw("Step Up", .quads, sets: 3, reps: 12, unilateral: true),
        bw("Sissy Squat", .quads, sets: 3, reps: 12),
    ]

    // MARK: Hamstrings
    static let hamstrings: [PresetExercise] = [
        bb("BB Romanian Deadlift", .hamstrings, sets: 3, reps: 5),
        bb("BB Stiff Leg Deadlift", .hamstrings, sets: 3, reps: 8),
        bb("BB Conventional Deadlift", .hamstrings, sets: 3, reps: 5),
        bb("BB Sumo Deadlift", .hamstrings, sets: 3, reps: 5),
        bb("BB Deficit Deadlift", .hamstrings, sets: 3, reps: 5),
        bb("BB Good Morning", .hamstrings, sets: 3, reps: 8),

        db("DB Romanian Deadlift", .hamstrings, sets: 3, reps: 10),
        db("DB Single Leg RDL", .hamstrings, sets: 3, reps: 10, unilateral: true),
        db("DB Stiff Leg Deadlift", .hamstrings, sets: 3, reps: 10),

        mc("Seated Hamstring Curl", .hamstrings, sets: 3, reps: 15, unilateral: true),
        mc("Lying Hamstring Curl", .hamstrings, sets: 3, reps: 12, unilateral: true),
        mc("Standing Hamstring Curl", .hamstrings, sets: 3, reps: 12, unilateral: true),
        mc("Glute Ham Raise", .hamstrings, sets: 3, reps: 8),
        mc("Nordic Hamstring Curl", .hamstrings, sets: 3, reps: 5),

        cb("Cable Pull Through", .hamstrings, sets: 3, reps: 12),
        cb("Cable Single Leg RDL", .hamstrings, sets: 3, reps: 10, unilateral: true),

        bw("Nordic Curl (Assisted)", .hamstrings, sets: 3, reps: 5),
        bw("Single Leg Hip Hinge", .hamstrings, sets: 3, reps: 10, unilateral: true),
    ]

    // MARK: Glutes
    static let glutes: [PresetExercise] = [
        bb("BB Hip Thrust", .glutes, sets: 3, reps: 8),
        bb("BB Glute Bridge", .glutes, sets: 3, reps: 10),
        bb("BB Sumo Squat", .glutes, sets: 3, reps: 8),
        bb("BB Reverse Lunge", .glutes, sets: 3, reps: 8, unilateral: true),

        db("DB Hip Thrust", .glutes, sets: 3, reps: 12),
        db("DB Single Leg Hip Thrust", .glutes, sets: 3, reps: 10, unilateral: true),
        db("DB Curtsy Lunge", .glutes, sets: 3, reps: 10, unilateral: true),
        db("DB Glute Bridge", .glutes, sets: 3, reps: 12),

        mc("Hip Thrust Machine", .glutes, sets: 3, reps: 10),
        mc("Machine Glute Kickback", .glutes, sets: 3, reps: 12, unilateral: true),
        mc("Hip Abduction Machine", .glutes, sets: 3, reps: 15),
        mc("Hip Adduction Machine", .glutes, sets: 3, reps: 15),
        mc("Smith Machine Hip Thrust", .glutes, sets: 3, reps: 8),

        cb("Cable Glute Kickback", .glutes, sets: 3, reps: 12, unilateral: true),
        cb("Cable Pull Through", .glutes, sets: 3, reps: 12),
        cb("Cable Hip Abduction", .glutes, sets: 3, reps: 15, unilateral: true),

        bw("Glute Bridge", .glutes, sets: 3, reps: 15),
        bw("Single Leg Glute Bridge", .glutes, sets: 3, reps: 12, unilateral: true),
        bw("Frog Pump", .glutes, sets: 3, reps: 20),
        bw("Banded Lateral Walk", .glutes, sets: 3, reps: 15),
        bw("Banded Glute Bridge", .glutes, sets: 3, reps: 20),
    ]

    // MARK: Calves
    static let calves: [PresetExercise] = [
        mc("Standing Calf Raise", .calves, sets: 4, reps: 12),
        mc("Seated Calf Raise", .calves, sets: 4, reps: 15),
        mc("Leg Press Calf Raise", .calves, sets: 4, reps: 15, unilateral: true),
        mc("Smith Machine Calf Raise", .calves, sets: 4, reps: 12),
        mc("Donkey Calf Raise", .calves, sets: 3, reps: 15),
        mc("Tibialis Raise (Machine)", .calves, sets: 3, reps: 20),

        bb("BB Standing Calf Raise", .calves, sets: 3, reps: 12),
        db("DB Single Leg Calf Raise", .calves, sets: 3, reps: 15, unilateral: true),

        bw("Tibialis Raise", .calves, sets: 3, reps: 20),
        bw("Single Leg Calf Raise", .calves, sets: 3, reps: 20, unilateral: true),
        bw("Stair Calf Raise", .calves, sets: 3, reps: 20),
    ]

    // MARK: Core
    static let core: [PresetExercise] = [
        cb("Cable Crunch", .core, sets: 4, reps: 12),
        cb("Cable Wood Chop", .core, sets: 3, reps: 12, unilateral: true),
        cb("Cable Reverse Wood Chop", .core, sets: 3, reps: 12, unilateral: true),
        cb("Pallof Press", .core, sets: 3, reps: 10, unilateral: true),
        cb("Cable Side Bend", .core, sets: 3, reps: 15, unilateral: true),
        cb("Cable Russian Twist", .core, sets: 3, reps: 15),

        bw("Hanging Leg Raise", .core, sets: 3, reps: 10),
        bw("Hanging Knee Raise", .core, sets: 3, reps: 12),
        bw("Toes to Bar", .core, sets: 3, reps: 8),
        bw("Decline Reverse Crunch", .core, sets: 3, reps: 10),
        bw("Reverse Crunch", .core, sets: 3, reps: 15),
        bw("Crunch", .core, sets: 3, reps: 20),
        bw("Sit-Up", .core, sets: 3, reps: 15),
        bw("V-Up", .core, sets: 3, reps: 12),
        bw("Bicycle Crunch", .core, sets: 3, reps: 20),
        bw("Russian Twist", .core, sets: 3, reps: 20),
        bw("Mountain Climber", .core, sets: 3, reps: 30),
        bw("Dead Bug", .core, sets: 3, reps: 10),
        bw("Bird Dog", .core, sets: 3, reps: 10, unilateral: true),
        bw("Hollow Hold Rocks", .core, sets: 3, reps: 15),
        bw("Ab Wheel Rollout", .core, sets: 3, reps: 8),
        bw("Dragon Flag", .core, sets: 3, reps: 5),

        timed("Plank", .core, .bodyweight, sets: 3, seconds: 45),
        timed("Weighted Plank", .core, .bodyweight, sets: 3, seconds: 45),
        timed("Side Plank", .core, .bodyweight, sets: 3, seconds: 30),
        timed("RKC Plank", .core, .bodyweight, sets: 3, seconds: 20),
        timed("Hollow Hold", .core, .bodyweight, sets: 3, seconds: 30),
        timed("L-Sit Hold", .core, .bodyweight, sets: 3, seconds: 20),
        timed("Dead Hang", .core, .bodyweight, sets: 3, seconds: 30),
        timed("Wall Sit", .core, .bodyweight, sets: 3, seconds: 45),
        timed("Copenhagen Plank", .core, .bodyweight, sets: 3, seconds: 20),

        mc("Machine Crunch", .core, sets: 3, reps: 12),
        mc("Machine Oblique Twist", .core, sets: 3, reps: 15),
    ]

    // MARK: Neck
    static let neck: [PresetExercise] = [
        bw("Neck Flexion (Plate)", .neck, sets: 3, reps: 15),
        bw("Neck Extension (Plate)", .neck, sets: 3, reps: 15),
        bw("Neck Side Flexion (Plate)", .neck, sets: 3, reps: 15, unilateral: true),
        mc("Neck Machine (4-Way)", .neck, sets: 3, reps: 15),
        bw("Neck Bridge", .neck, sets: 3, reps: 10),
    ]

    // MARK: Full Body / Athletic / Olympic
    static let fullBody: [PresetExercise] = [
        bb("BB Power Clean", .fullBody, sets: 5, reps: 3),
        bb("BB Hang Clean", .fullBody, sets: 5, reps: 3),
        bb("BB Clean & Jerk", .fullBody, sets: 5, reps: 2),
        bb("BB Snatch", .fullBody, sets: 5, reps: 2),
        bb("BB Hang Snatch", .fullBody, sets: 5, reps: 3),
        bb("BB Power Snatch", .fullBody, sets: 5, reps: 3),
        bb("BB Push Jerk", .fullBody, sets: 5, reps: 3),
        bb("BB Split Jerk", .fullBody, sets: 5, reps: 2),
        bb("BB Thruster", .fullBody, sets: 3, reps: 8),
        bb("BB High Pull", .fullBody, sets: 4, reps: 5),
        bb("BB Clean Pull", .fullBody, sets: 4, reps: 5),
        bb("BB Snatch Pull", .fullBody, sets: 4, reps: 5),

        db("DB Thruster", .fullBody, sets: 3, reps: 10),
        db("DB Snatch", .fullBody, sets: 3, reps: 8, unilateral: true),
        db("DB Clean", .fullBody, sets: 3, reps: 8, unilateral: true),
        db("DB Clean & Press", .fullBody, sets: 3, reps: 8, unilateral: true),
        db("DB Turkish Get-Up", .fullBody, sets: 3, reps: 3, unilateral: true),
        db("DB Renegade Row", .fullBody, sets: 3, reps: 8),
        db("DB Man Maker", .fullBody, sets: 3, reps: 8),
        db("DB Devil Press", .fullBody, sets: 3, reps: 8),

        kb("KB Swing (Russian)", .fullBody, sets: 4, reps: 15),
        kb("KB Swing (American)", .fullBody, sets: 4, reps: 12),
        kb("KB Single Arm Swing", .fullBody, sets: 4, reps: 12, unilateral: true),
        kb("KB Clean", .fullBody, sets: 3, reps: 8, unilateral: true),
        kb("KB Snatch", .fullBody, sets: 3, reps: 8, unilateral: true),
        kb("KB Clean & Press", .fullBody, sets: 3, reps: 8, unilateral: true),
        kb("KB Goblet Squat", .fullBody, sets: 3, reps: 12),
        kb("KB Turkish Get-Up", .fullBody, sets: 3, reps: 3, unilateral: true),
        kb("KB Farmer Carry", .fullBody, sets: 3, reps: 1),
        kb("KB Suitcase Carry", .fullBody, sets: 3, reps: 1, unilateral: true),
        kb("KB Front Rack Carry", .fullBody, sets: 3, reps: 1),

        bw("Burpee", .fullBody, sets: 3, reps: 15),
        bw("Bear Crawl", .fullBody, sets: 3, reps: 1),
        bw("Box Jump", .fullBody, sets: 4, reps: 5),
        bw("Broad Jump", .fullBody, sets: 4, reps: 3),
        bw("Tuck Jump", .fullBody, sets: 3, reps: 8),
        bw("Depth Jump", .fullBody, sets: 4, reps: 3),
        bw("Vertical Jump", .fullBody, sets: 4, reps: 3),
        bw("Lateral Bound", .fullBody, sets: 3, reps: 8, unilateral: true),
        bw("Sprawl", .fullBody, sets: 3, reps: 10),
        bw("Burpee Pull-Up", .fullBody, sets: 3, reps: 8),
        bw("Muscle-Up", .fullBody, sets: 3, reps: 3),

        // Athletic carries / sled
        PresetExercise(name: "Sled Push", type: .weightReps, muscleGroup: .fullBody, equipment: .other, goalSets: 4, goalReps: 1),
        PresetExercise(name: "Sled Pull", type: .weightReps, muscleGroup: .fullBody, equipment: .other, goalSets: 4, goalReps: 1),
        PresetExercise(name: "Yoke Carry", type: .weightReps, muscleGroup: .fullBody, equipment: .other, goalSets: 3, goalReps: 1),
        PresetExercise(name: "Farmer's Walk", type: .weightReps, muscleGroup: .fullBody, equipment: .other, goalSets: 3, goalReps: 1),
        PresetExercise(name: "Atlas Stone Lift", type: .weightReps, muscleGroup: .fullBody, equipment: .other, goalSets: 3, goalReps: 3),

        // Plyo + speed
        bw("Skater Hops", .fullBody, sets: 3, reps: 12, unilateral: true),
        bw("Single Leg Bound", .fullBody, sets: 3, reps: 6, unilateral: true),
        timed("Jump Rope", .fullBody, .other, sets: 5, seconds: 60),
        timed("High Knees", .fullBody, .bodyweight, sets: 3, seconds: 30),
        timed("Sprint Interval", .fullBody, .other, sets: 8, seconds: 30),
    ]

    // MARK: Cardio
    static let cardio: [PresetExercise] = [
        card("Z2 Indoor Cycling", .bike, minutes: 40, intensity: 4),
        card("Z2 Outdoor Cycling", .bike, minutes: 60, intensity: 4),
        card("Z2 Long Outdoor Ride", .bike, minutes: 90, intensity: 4),
        card("Easy Outdoor Cycle", .bike, minutes: 45, intensity: 3),
        card("Threshold Bike Intervals", .bike, minutes: 30, intensity: 8),
        card("VO2 Max Bike Intervals", .bike, minutes: 25, intensity: 9),
        card("Sprint Bike Intervals", .bike, minutes: 20, intensity: 10),
        card("Recovery Spin", .bike, minutes: 30, intensity: 2),

        card("Easy Run", .treadmill, minutes: 30, intensity: 4),
        card("Long Run", .treadmill, minutes: 60, intensity: 4),
        card("Tempo Run", .treadmill, minutes: 25, intensity: 7),
        card("Interval Run", .treadmill, minutes: 25, intensity: 9),
        card("Hill Sprints", .treadmill, minutes: 20, intensity: 9),
        card("Incline Walk", .treadmill, minutes: 30, intensity: 4),

        card("Rowing (Steady)", .rower, minutes: 20, intensity: 5),
        card("Rowing Intervals", .rower, minutes: 20, intensity: 8),
        card("Rowing 2k Test", .rower, minutes: 8, intensity: 10),

        card("Stair Climber", .machine, minutes: 20, intensity: 6),
        card("Elliptical", .machine, minutes: 30, intensity: 5),
        card("Ski Erg", .machine, minutes: 15, intensity: 7),
        card("Assault Bike Intervals", .machine, minutes: 15, intensity: 9),
        card("Echo Bike (Steady)", .machine, minutes: 25, intensity: 5),

        card("Outdoor Walk", .other, minutes: 45, intensity: 2),
        card("Hike", .other, minutes: 90, intensity: 4),
        card("Swimming Laps", .other, minutes: 30, intensity: 6),
    ]
}
