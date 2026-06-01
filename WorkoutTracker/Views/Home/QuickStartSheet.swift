import SwiftUI
import SwiftData

/// Presented when the user taps a workout in Quick Start. Shows the
/// exercise list at a glance and offers Start or Edit. The sheet hosts
/// its own NavigationStack so Edit pushes the workout editor in-place;
/// dismissing the sheet returns to Home.
struct QuickStartSheet: View {
    @Bindable var workout: Workout
    let onStart: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var pushEditor = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        exercisesSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }

                VStack {
                    Spacer()
                    bottomBar
                }
            }
            .navigationTitle(workout.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
            .navigationDestination(isPresented: $pushEditor) {
                WorkoutEditorView(workout: workout)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var exercisesSection: some View {
        let list = workout.orderedWorkoutExercises
        let visible = Array(list.prefix(8))
        let remaining = list.count - visible.count
        return VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Exercises")
            if list.isEmpty {
                Card {
                    Text("This workout has no exercises yet. Tap Edit to add some.")
                        .font(.bodyMd)
                        .foregroundStyle(Theme.textSecondary)
                }
            } else {
                VStack(spacing: 8) {
                    ForEach(visible, id: \.uuid) { we in
                        exerciseRow(we)
                    }
                    if remaining > 0 {
                        Text("+ \(remaining) more")
                            .font(.caption)
                            .foregroundStyle(Theme.textMuted)
                            .padding(.horizontal, 4)
                            .padding(.top, 2)
                    }
                }
            }
        }
    }

    private func exerciseRow(_ we: WorkoutExercise) -> some View {
        Card(padding: 12) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(we.exercise?.name ?? "(deleted exercise)")
                        .font(.bodyBold)
                        .foregroundStyle(Theme.textPrimary)
                    Text(rowSubtitle(we))
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
            }
        }
    }

    private func rowSubtitle(_ we: WorkoutExercise) -> String {
        guard let ex = we.exercise else { return "" }
        switch ex.type {
        case .weightReps:
            return "\(we.goalSets)×\(we.goalReps)\(ex.isUnilateral ? " L/R" : "")"
        case .weightTime:
            return "\(we.goalSets)×\(Format.duration(we.goalDurationSeconds))"
        case .cardio:
            return "\(Format.cardioDuration(we.goalDurationSeconds)) @ int \(we.goalIntensity)"
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 10) {
            Button {
                dismiss()
                // Run the start action on the next runloop so the sheet
                // has finished dismissing before the new screen pushes.
                DispatchQueue.main.async { onStart() }
            } label: {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Start workout").font(.bodyBold)
                }
            }
            .primaryButton()
            .disabled(workout.workoutExercises.isEmpty)

            Button {
                pushEditor = true
            } label: {
                HStack {
                    Image(systemName: "pencil")
                    Text("Edit workout").font(.bodyBold)
                }
            }
            .secondaryButton()
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 18)
        .padding(.top, 18)
        .background(
            LinearGradient(
                colors: [Theme.background.opacity(0), Theme.background, Theme.background],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}
