import SwiftUI
import SwiftData

/// One exercise on its own page inside the active workout. Streamlined:
/// the title, the per-session goal, the set rows, and a compact "last time"
/// reference. No accordions or charts — those live in the exercise editor.
struct ExerciseLoggerView: View {
    @Bindable var log: ExerciseLog
    let previousLog: ExerciseLog?

    @Environment(\.modelContext) private var context
    @State private var showGoalEditor = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            titleRow
            goalPill
            setsList
            addSetButton
            if let previousLog {
                previousSection(previousLog)
            }
        }
        .sheet(isPresented: $showGoalEditor) {
            SessionGoalEditorSheet(log: log)
                .preferredColorScheme(.dark)
        }
    }

    private var titleRow: some View {
        HStack(spacing: 8) {
            Text(log.exerciseName)
                .font(.titleLg)
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
            Text("\(completedCount) / \(log.goalSets)")
                .font(.mono)
                .foregroundStyle(Theme.textPrimary)
        }
    }

    private var goalPill: some View {
        Button {
            showGoalEditor = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "target")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                Text(headerSubtitle)
                    .font(.bodyBold)
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Image(systemName: "pencil")
                    .font(.caption)
                    .foregroundStyle(Theme.textMuted)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Theme.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSm, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var headerSubtitle: String {
        switch log.exerciseType {
        case .weightReps: return "Goal: \(log.goalSets)×\(log.goalReps)"
        case .weightTime: return "Goal: \(log.goalSets)×\(Format.duration(log.goalDurationSeconds))"
        case .cardio:     return "Goal: \(Format.cardioDuration(log.goalDurationSeconds)) @ int \(log.goalIntensity)"
        }
    }

    private var completedCount: Int {
        log.sets.filter { $0.completed }.count
    }

    private var setsList: some View {
        VStack(spacing: 8) {
            ForEach(Array(log.orderedSets.enumerated()), id: \.element.persistentModelID) { _, set in
                SetEntryView(
                    set: set,
                    type: log.exerciseType,
                    isUnilateral: log.isUnilateral,
                    onDelete: { delete(set) }
                )
            }
        }
    }

    private var addSetButton: some View {
        Button { addSet() } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Add set").font(.bodyBold)
            }
        }
        .secondaryButton()
    }

    private func previousSection(_ prev: ExerciseLog) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider().background(Theme.stroke)
            Text("LAST TIME")
                .font(.caption)
                .tracking(1.2)
                .foregroundStyle(Theme.textMuted)
            ForEach(prev.orderedSets) { s in
                HStack(spacing: 10) {
                    Text("Set \(s.setNumber)").font(.caption).foregroundStyle(Theme.textMuted).frame(width: 50, alignment: .leading)
                    Text(previousSummary(s, prev: prev)).font(.caption).foregroundStyle(Theme.textSecondary)
                    Spacer()
                }
            }
        }
    }

    private func previousSummary(_ s: SetLog, prev: ExerciseLog) -> String {
        switch prev.exerciseType {
        case .weightReps:
            if prev.isUnilateral {
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

    private func addSet() {
        let next = (log.sets.map(\.setNumber).max() ?? 0) + 1
        let s = SetLog(setNumber: next)
        // Pre-fill from prior set in this session for fast logging.
        if let last = log.orderedSets.last {
            s.weight = last.weight
            s.reps = last.reps
            s.leftReps = last.leftReps
            s.rightReps = last.rightReps
            s.durationSeconds = last.durationSeconds
            s.intensity = last.intensity
        }
        log.sets.append(s)
        try? context.save()
    }

    private func delete(_ s: SetLog) {
        if let idx = log.sets.firstIndex(where: { $0.persistentModelID == s.persistentModelID }) {
            log.sets.remove(at: idx)
        }
        context.delete(s)
        try? context.save()
    }
}

// MARK: - Session-only goal editor

/// Edits goal values on a live `ExerciseLog`. Changes apply to THIS
/// session only; the underlying WorkoutExercise template is untouched.
struct SessionGoalEditorSheet: View {
    @Bindable var log: ExerciseLog
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Editing only changes the targets for this session. The saved workout template keeps its original numbers.")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                        Card {
                            VStack(spacing: 14) {
                                if log.exerciseType != .cardio {
                                    StepperRow(label: "Sets", value: $log.goalSets, range: 1...20)
                                }
                                if log.exerciseType == .weightReps {
                                    StepperRow(label: "Reps", value: $log.goalReps, range: 1...100)
                                }
                                if log.exerciseType == .weightTime {
                                    StepperRow(label: "Duration (sec)", value: $log.goalDurationSeconds, range: 5...7200, step: 5)
                                }
                                if log.exerciseType == .cardio {
                                    StepperRow(
                                        label: "Duration (min)",
                                        value: Binding(
                                            get: { log.goalDurationSeconds / 60 },
                                            set: { log.goalDurationSeconds = $0 * 60 }
                                        ),
                                        range: 1...180
                                    )
                                    StepperRow(label: "Intensity (1-10)", value: $log.goalIntensity, range: 1...10)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Adjust goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        try? context.save()
                        dismiss()
                    }
                }
            }
        }
    }
}
