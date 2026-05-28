import SwiftUI
import SwiftData

struct SessionDetailView: View {
    let session: WorkoutSession
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirm = false

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    summaryCard
                    exercisesSection
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Text("Delete session")
                    }
                    .secondaryButton()
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle(session.workoutName)
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Delete session?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                context.delete(session)
                try? context.save()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var summaryCard: some View {
        Card(elevated: true) {
            VStack(alignment: .leading, spacing: 8) {
                Text(Format.date(session.startedAt).uppercased())
                    .font(.caption)
                    .tracking(1.2)
                    .foregroundStyle(Theme.textMuted)
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Duration").font(.caption).foregroundStyle(Theme.textMuted)
                        Text(Format.elapsed(session.elapsed))
                            .font(.title)
                            .foregroundStyle(Theme.textPrimary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Exercises").font(.caption).foregroundStyle(Theme.textMuted)
                        Text("\(session.exerciseLogs.count)")
                            .font(.title)
                            .foregroundStyle(Theme.textPrimary)
                    }
                }
                if !session.isFinished {
                    Text("Session was not finished")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
    }

    private var exercisesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Exercises")
            ForEach(session.exerciseLogs) { log in
                exerciseCard(log)
            }
        }
    }

    private func exerciseCard(_ log: ExerciseLog) -> some View {
        Card(padding: 14) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(log.exerciseName)
                        .font(.title)
                        .foregroundStyle(Theme.textPrimary)
                    if log.isUnilateral {
                        Text("L/R")
                            .font(.caption)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Theme.strokeStrong)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    Spacer()
                    if log.hitGoalAcrossAllSets {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(Theme.accent)
                    }
                }
                if log.sets.isEmpty {
                    Text("No sets logged")
                        .font(.caption)
                        .foregroundStyle(Theme.textMuted)
                } else {
                    ForEach(log.orderedSets) { s in
                        HStack {
                            Text("Set \(s.setNumber)")
                                .font(.caption)
                                .foregroundStyle(Theme.textMuted)
                                .frame(width: 50, alignment: .leading)
                            Text(summary(for: s, log: log))
                                .font(.caption)
                                .foregroundStyle(Theme.textSecondary)
                            Spacer()
                            if !s.completed {
                                Text("skipped").font(.caption).foregroundStyle(Theme.textMuted)
                            }
                        }
                    }
                }
            }
        }
    }

    private func summary(for s: SetLog, log: ExerciseLog) -> String {
        switch log.exerciseType {
        case .weightReps:
            if log.isUnilateral {
                return "\(Format.weight(s.weight)) lbs • L\(s.leftReps) / R\(s.rightReps)"
            } else {
                return "\(Format.weight(s.weight)) lbs × \(s.reps)"
            }
        case .weightTime:
            return "\(Format.weight(s.weight)) lbs × \(Format.duration(s.durationSeconds))"
        case .cardio:
            return "\(Format.cardioDuration(s.durationSeconds)) @ int \(s.intensity)"
        }
    }
}
