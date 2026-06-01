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
    @State private var showAddExercise = false
    @State private var page: Int = 0

    @AppStorage("Settings.syncToAppleHealth") private var syncToAppleHealth = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var logs: [ExerciseLog] { session.exerciseLogs }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 14) {
                headerCard
                if logs.isEmpty {
                    emptyState
                } else {
                    pageIndicator
                    pager
                }
                bottomBar
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 12)
        }
        .navigationTitle(session.workoutName)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showAddExercise = true } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                }
                .accessibilityLabel("Add exercise to this workout")
            }
        }
        .onReceive(timer) { _ in if !session.isFinished { now = Date() } }
        .sheet(isPresented: $showAddExercise) {
            ExercisePickerView(
                workoutName: session.workoutName,
                selectedUUIDs: Set(logs.compactMap { $0.exercise?.uuid })
            ) { picked in
                addExercises(picked)
            }
            .preferredColorScheme(.dark)
        }
        .appConfirm(
            isPresented: $showFinishConfirm,
            title: "Finish workout?",
            message: "Logs will be saved and the timer will stop.",
            confirmTitle: "Finish"
        ) {
            finish()
        }
        .appConfirm(
            isPresented: $showAbortConfirm,
            title: "Abandon workout?",
            message: "This session will be deleted and nothing will be saved.",
            confirmTitle: "Discard",
            destructive: true
        ) {
            abort()
        }
    }

    // MARK: - Header

    private var headerCard: some View {
        Card(padding: 14, elevated: true) {
            VStack(spacing: 8) {
                HStack {
                    Text("ELAPSED")
                        .font(.caption)
                        .tracking(1.2)
                        .foregroundStyle(Theme.textMuted)
                    Spacer()
                    Text(Format.elapsed(elapsed))
                        .font(.mono)
                        .foregroundStyle(Theme.textPrimary)
                }
                if let rest = restElapsed {
                    Divider().background(Theme.stroke)
                    HStack(spacing: 8) {
                        Image(systemName: "timer")
                            .font(.caption)
                            .foregroundStyle(Theme.accent)
                        Text("SINCE LAST SET")
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
        }
    }

    // MARK: - Pager

    private var pageIndicator: some View {
        VStack(spacing: 8) {
            Text("EXERCISE \(min(page + 1, logs.count)) OF \(logs.count)")
                .font(.caption)
                .tracking(1.2)
                .foregroundStyle(Theme.textMuted)
            HStack(spacing: 6) {
                ForEach(logs.indices, id: \.self) { i in
                    Capsule()
                        .fill(i == page ? Theme.accent : Theme.strokeStrong)
                        .frame(width: i == page ? 18 : 6, height: 6)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: page)
        }
    }

    private var pager: some View {
        TabView(selection: $page) {
            ForEach(Array(logs.enumerated()), id: \.element.persistentModelID) { idx, log in
                ScrollView {
                    ExerciseLoggerView(log: log, previousLog: previousLog(for: log))
                        .padding(.horizontal, 4)
                        .padding(.top, 4)
                        .padding(.bottom, 24)
                }
                .tag(idx)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(maxHeight: .infinity)
    }

    private var emptyState: some View {
        VStack {
            Spacer()
            Image(systemName: "dumbbell")
                .font(.system(size: 32))
                .foregroundStyle(Theme.textMuted)
            Text("No exercises in this session")
                .font(.title)
                .foregroundStyle(Theme.textPrimary)
                .padding(.top, 10)
            Text("Tap + to add one.")
                .font(.bodyMd)
                .foregroundStyle(Theme.textSecondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        VStack(spacing: 10) {
            Button { showFinishConfirm = true } label: {
                Text("Finish workout").font(.bodyBold)
            }
            .primaryButton()

            Button(role: .destructive) { showAbortConfirm = true } label: {
                Text("Abandon workout").font(.bodyBold)
            }
            .secondaryButton()
        }
    }

    // MARK: - Derived state

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

    // MARK: - Actions

    /// Adds exercises to THIS session only. New `ExerciseLog`s are appended to
    /// the live session record; the saved Workout/WorkoutExercise template is
    /// intentionally left untouched.
    private func addExercises(_ exercises: [Exercise]) {
        guard !exercises.isEmpty else { return }
        for ex in exercises {
            let log = ExerciseLog(exercise: ex)
            context.insert(log)
            session.exerciseLogs.append(log)
        }
        try? context.save()
        // Jump to the first newly-added exercise.
        page = max(0, session.exerciseLogs.count - exercises.count)
    }

    private func finish() {
        session.finish()
        // Advance active split if this session belongs to one.
        if let split = session.split, split.isActive {
            split.advance()
        }
        try? context.save()
        if syncToAppleHealth, let summary = HealthKitManager.summary(for: session) {
            Task {
                try? await HealthKitManager.shared.save(summary)
            }
        }
        dismiss()
    }

    private func abort() {
        context.delete(session)
        try? context.save()
        dismiss()
    }
}
