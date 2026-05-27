import SwiftUI

/// Getting-started + reference guide. Linked from the question-mark icon in
/// HomeView's toolbar. Plain content — no SwiftData here.
struct HelpView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        hero
                        section(
                            title: "1. Build your library",
                            body: "Open Exercises and add the lifts you actually do. Each exercise has a type (weight × reps, weight × time, or cardio), a muscle group, and an equipment tag — those tags power search and recommendations later."
                        )
                        section(
                            title: "2. Create workouts",
                            body: "A workout is just an ordered list of exercises. Open Workouts → New, name it (\"Push day\"), then tap the big Add card to pull exercises from your library. The picker recommends matches based on the name you gave the workout."
                        )
                        section(
                            title: "3. (Optional) Define a split",
                            body: "A split groups workouts and decides what's “up next” on the home screen. Two flavors:\n\n• Weekly schedule — pin a workout to each weekday. Best if you train on the same days every week.\n\n• Rotation — cycle through workouts in order. Each finished session advances to the next. Best if your week is unpredictable."
                        )
                        section(
                            title: "4. Start a session",
                            body: "From Home, tap your next workout's play button. The timer starts. Tap any exercise to expand it, then tap each set's check to log it. The “Last time” section reminds you what you did before. Hit Finish when you're done."
                        )
                        searchSection
                        overloadSection
                        progressionSection
                        Spacer(minLength: 8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Getting started")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var hero: some View {
        Card(elevated: true) {
            VStack(alignment: .leading, spacing: 8) {
                Text("WELCOME")
                    .font(.caption)
                    .tracking(1.2)
                    .foregroundStyle(Theme.textMuted)
                Text("How this app works")
                    .font(.titleLg)
                    .foregroundStyle(Theme.textPrimary)
                Text("Four building blocks — exercises, workouts, splits, sessions — chain together to track every lift and progressively get stronger.")
                    .font(.bodyMd)
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func section(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.caption)
                .tracking(1.2)
                .foregroundStyle(Theme.textMuted)
            Card {
                Text(body)
                    .font(.bodyMd)
                    .foregroundStyle(Theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var searchSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SEARCH TIPS")
                .font(.caption)
                .tracking(1.2)
                .foregroundStyle(Theme.textMuted)
            Card {
                VStack(alignment: .leading, spacing: 10) {
                    Text("The exercise search bar understands more than names.")
                        .font(.bodyMd)
                        .foregroundStyle(Theme.textPrimary)
                    bullet("By equipment — \"machine\", \"dumbbell\", or just \"DB\". \"BB\" matches barbell, \"KB\" kettlebell.")
                    bullet("By muscle worked — \"chest\", \"lats\", \"abs\", \"hamstrings\".")
                    bullet("By movement shorthand — \"OHP\", \"RDL\", \"pulldown\".")
                    bullet("By cardio zone — \"Z2\" finds your low-intensity work, \"HIIT\" the hard stuff.")
                    bullet("Combine words — \"DB curl\" or \"BB row\" narrows the list.")
                }
            }
        }
    }

    private var overloadSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PROGRESSIVE OVERLOAD")
                .font(.caption)
                .tracking(1.2)
                .foregroundStyle(Theme.textMuted)
            Card {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Progressive overload = slowly adding load so your muscles keep adapting.")
                        .font(.bodyMd)
                        .foregroundStyle(Theme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("During a session, the app looks at your last performance for each exercise. If you hit every goal set at the target reps, it suggests bumping the weight by your configured “step” (default 5 lbs barbell, 2.5 lbs dumbbell). Tap the pre-fill button on the suggestion card and that new weight copies onto every set you haven't logged yet.")
                        .font(.bodyMd)
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Didn't hit the goal? It'll suggest matching the previous weight and pushing for full reps instead — no jumping ahead before you've earned it.")
                        .font(.bodyMd)
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var progressionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PROGRESSION CHARTS")
                .font(.caption)
                .tracking(1.2)
                .foregroundStyle(Theme.textMuted)
            Card {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tap any exercise in your library — or expand one mid-session — and you'll see charts for how your top weight and best reps have moved over time. They need at least two finished sessions to render.")
                        .font(.bodyMd)
                        .foregroundStyle(Theme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(.bodyMd)
                .foregroundStyle(Theme.textMuted)
            Text(text)
                .font(.bodyMd)
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
