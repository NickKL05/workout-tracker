import SwiftUI
import SwiftData

struct ExerciseLoggerView: View {
    @Bindable var log: ExerciseLog
    let previousLog: ExerciseLog?
    @Binding var isExpanded: Bool

    @Environment(\.modelContext) private var context
    @State private var showOverloadInfo = false

    var body: some View {
        Card(padding: 14) {
            VStack(alignment: .leading, spacing: 12) {
                header
                if isExpanded {
                    Divider().background(Theme.stroke)
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
        case .cardio:     return "Goal: \(Format.duration(log.goalDurationSeconds)) @ int \(log.goalIntensity)"
        }
    }

    private var completedCount: Int {
        log.sets.filter { $0.completed }.count
    }

    private var suggestion: OverloadSuggestion? {
        guard let ex = log.exercise else { return nil }
        return ProgressiveOverload.suggest(for: ex, previous: previousLog)
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
            return "\(Format.duration(s.durationSeconds)) @ int \(s.intensity)"
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
