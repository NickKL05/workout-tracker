import SwiftUI
import SwiftData

struct ActiveWorkoutView: View {
    @Bindable var session: WorkoutSession
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \WorkoutSession.startedAt, order: .reverse) private var allSessions: [WorkoutSession]

    @State private var now: Date = Date()
    @State private var showFinishConfirm = false
    @State private var showAbortConfirm = false
    @State private var expandedLogID: PersistentIdentifier?

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerCard
                    exercisesList
                    Button { showFinishConfirm = true } label: {
                        Text("Finish workout").font(.bodyBold)
                    }
                    .primaryButton()

                    Button(role: .destructive) { showAbortConfirm = true } label: {
                        Text("Abandon workout").font(.bodyBold)
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
        .navigationBarBackButtonHidden(true)
        .onReceive(timer) { _ in if !session.isFinished { now = Date() } }
        .confirmationDialog("Finish workout?", isPresented: $showFinishConfirm, titleVisibility: .visible) {
            Button("Finish", role: .none) { finish() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Logs will be saved and the timer will stop.")
        }
        .confirmationDialog("Abandon workout?", isPresented: $showAbortConfirm, titleVisibility: .visible) {
            Button("Discard", role: .destructive) { abort() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This session will be deleted.")
        }
    }

    private var headerCard: some View {
        Card(elevated: true) {
            VStack(spacing: 10) {
                Text("ELAPSED")
                    .font(.caption)
                    .tracking(1.2)
                    .foregroundStyle(Theme.textMuted)
                Text(Format.elapsed(elapsed))
                    .font(.monoLg)
                    .foregroundStyle(Theme.textPrimary)
                Text(session.workoutName)
                    .font(.bodyMd)
                    .foregroundStyle(Theme.textSecondary)

                if let rest = restElapsed {
                    Divider().background(Theme.stroke).padding(.vertical, 4)
                    HStack(spacing: 8) {
                        Image(systemName: "timer")
                            .font(.caption)
                            .foregroundStyle(Theme.accent)
                        Text("TIME FROM LAST SET")
                            .font(.caption)
                            .tracking(1.2)
                            .foregroundStyle(Theme.textMuted)
                        Spacer()
                        Text(Format.elapsed(rest))
                            .font(.mono)
                            .foregroundStyle(Theme.textPrimary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var elapsed: TimeInterval {
        if let end = session.endedAt { return end.timeIntervalSince(session.startedAt) }
        return now.timeIntervalSince(session.startedAt)
    }

    /// Date of the most recent completed set in this session (nil if none yet).
    private var lastCompletedAt: Date? {
        session.exerciseLogs
            .flatMap(\.sets)
            .filter(\.completed)
            .map(\.loggedAt)
            .max()
    }

    /// Seconds since the last completed set. Nil until the first set is checked off.
    private var restElapsed: TimeInterval? {
        guard !session.isFinished, let last = lastCompletedAt else { return nil }
        return max(0, now.timeIntervalSince(last))
    }

    private var exercisesList: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Exercises")
            ForEach(session.exerciseLogs) { log in
                ExerciseLoggerView(
                    log: log,
                    previousLog: previousLog(for: log),
                    isExpanded: Binding(
                        get: { expandedLogID == log.persistentModelID },
                        set: { expanded in expandedLogID = expanded ? log.persistentModelID : nil }
                    )
                )
            }
        }
    }

    /// Find the most recent ExerciseLog for this exercise from a previous session.
    private func previousLog(for current: ExerciseLog) -> ExerciseLog? {
        guard let exercise = current.exercise else { return nil }
        for s in allSessions where s.persistentModelID != session.persistentModelID && s.isFinished {
            if let match = s.exerciseLogs.first(where: { $0.exercise?.uuid == exercise.uuid }) {
                return match
            }
        }
        return nil
    }

    private func finish() {
        session.finish()
        // Advance active split if this session belongs to one.
        if let split = session.split, split.isActive {
            split.advance()
        }
        try? context.save()
        dismiss()
    }

    private func abort() {
        context.delete(session)
        try? context.save()
        dismiss()
    }
}
