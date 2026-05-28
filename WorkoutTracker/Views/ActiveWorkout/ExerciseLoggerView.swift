import SwiftUI
import SwiftData

struct ExerciseLoggerView: View {
    @Bindable var log: ExerciseLog
    let previousLog: ExerciseLog?
    @Binding var isExpanded: Bool

    @Environment(\.modelContext) private var context
    @State private var showOverloadInfo = false
    @State private var showGoalEditor = false

    var body: some View {
        Card(padding: 14) {
            VStack(alignment: .leading, spacing: 12) {
                header
                if isExpanded {
                    Divider().background(Theme.stroke)
                    goalPill
                    if let suggestion = suggestion {
                        suggestionCard(suggestion)
                    }
                    setsList
                    addSetButton
                    if let previousLog {
                        Divider().background(Theme.stroke)
                        previousSection(previousLog)
                    }
                    if let ex = log.exercise {
                        Divider().background(Theme.stroke)
                        ExerciseProgressionView(exercise: ex)
                    }
                }
            }
        }
        .sheet(isPresented: $showGoalEditor) {
            SessionGoalEditorSheet(log: log)
                .preferredColorScheme(.dark)
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
                Text("Edit for this session")
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

    private var header: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) { isExpanded.toggle() }
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
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
                    }
                    Text(headerSubtitle)
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Text("\(completedCount) / \(log.goalSets)")
                    .font(.mono)
                    .foregroundStyle(Theme.textPrimary)
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption)
                    .foregroundStyle(Theme.textMuted)
            }
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

    private var suggestion: OverloadSuggestion? {
        guard let ex = log.exercise else { return nil }
        return ProgressiveOverload.suggest(current: log, previous: previousLog, exercise: ex)
    }

    private func suggestionCard(_ s: OverloadSuggestion) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: s.metGoalPreviously ? "arrow.up.right.circle.fill" : "target")
                    .foregroundStyle(s.metGoalPreviously ? Theme.accent : Theme.textSecondary)
                    .font(.system(size: 16, weight: .semibold))
                    .padding(.top, 1)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(s.metGoalPreviously ? "TIME TO LEVEL UP" : "TODAY'S TARGET")
                            .font(.caption)
                            .tracking(1.1)
                            .foregroundStyle(Theme.textMuted)
                        Button { showOverloadInfo = true } label: {
                            Image(systemName: "questionmark.circle")
                                .font(.system(size: 12))
                                .foregroundStyle(Theme.textMuted)
                        }
                        .buttonStyle(.plain)
                    }
                    Text(s.summary)
                        .font(.bodyMd)
                        .foregroundStyle(Theme.textPrimary)
                }
                Spacer()
            }
            if let w = s.suggestedWeight {
                Button {
                    applyToAll(weight: w)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.down.to.line")
                            .font(.caption)
                        Text("Pre-fill \(Format.weight(w)) lbs on remaining sets")
                            .font(.caption)
                            .foregroundStyle(Theme.textPrimary)
                    }
                }
                .ghostButton()
            }
        }
        .padding(12)
        .background(Theme.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSm, style: .continuous))
        .alert("Progressive overload", isPresented: $showOverloadInfo) {
            Button("Got it", role: .cancel) {}
        } message: {
            Text("Each session this app looks at your last performance. If you hit every set at goal reps, it suggests bumping the weight by your configured step. Tap the pre-fill button to copy that weight onto every unfinished set so you don't have to type it.")
        }
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
        // Pre-fill from prior set in this session for fast logging
        if let last = log.orderedSets.last {
            s.weight = last.weight
            s.reps = last.reps
            s.leftReps = last.leftReps
            s.rightReps = last.rightReps
            s.durationSeconds = last.durationSeconds
            s.intensity = last.intensity
        } else if let s2 = suggestion {
            if let w = s2.suggestedWeight { s.weight = w }
            if let d = s2.suggestedDurationSeconds { s.durationSeconds = d }
            if let i = s2.suggestedIntensity { s.intensity = i }
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

    private func applyToAll(weight: Double) {
        for s in log.sets where !s.completed {
            s.weight = weight
        }
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
