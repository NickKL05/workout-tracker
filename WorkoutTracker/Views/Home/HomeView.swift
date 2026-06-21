import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var context

    @Query(sort: \Workout.createdAt, order: .reverse) private var workouts: [Workout]
    @Query(filter: #Predicate<Split> { $0.isActive == true }) private var activeSplits: [Split]
    @Query(sort: \WorkoutSession.startedAt, order: .reverse) private var sessions: [WorkoutSession]

    @State private var pendingSession: WorkoutSession?
    @State private var quickStartTarget: Workout?
    @State private var showHelp = false
    @State private var showSettings = false
    @State private var showAddToSplit = false

    @EnvironmentObject private var appleSignIn: AppleSignInController

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        header
                        quickStartSection
                        weeklyMuscleSection
                        manageSection
                        if let lastSession = sessions.first {
                            recentSection(session: lastSession)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 60)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(item: $pendingSession) { session in
                ActiveWorkoutView(session: session)
            }
            .sheet(item: $quickStartTarget) { workout in
                QuickStartSheet(workout: workout) {
                    start(workout: workout, split: activeSplits.first)
                }
                .preferredColorScheme(.dark)
            }
            .sheet(isPresented: $showHelp) {
                HelpView()
                    .preferredColorScheme(.dark)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(appleSignIn)
                    .preferredColorScheme(.dark)
            }
            .sheet(isPresented: $showAddToSplit) {
                if let split = activeSplits.first {
                    WorkoutPickerView(
                        allWorkouts: workouts,
                        alreadyInSplitUUIDs: Set(split.orderedWorkouts.map(\.uuid))
                    ) { picked in
                        addWorkouts(picked, to: split)
                    }
                    .preferredColorScheme(.dark)
                }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(greetingDate())
                    .font(.caption)
                    .tracking(1.2)
                    .foregroundStyle(Theme.textMuted)
                Text("Workout")
                    .font(.displayLg)
                    .foregroundStyle(Theme.textPrimary)
            }
            Spacer()
            HStack(spacing: 8) {
                headerIconButton(systemName: "questionmark.circle", label: "Help and getting started") {
                    showHelp = true
                }
                headerIconButton(systemName: "gearshape", label: "Settings") {
                    showSettings = true
                }
            }
        }
        .padding(.top, 12)
    }

    private func headerIconButton(systemName: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(Theme.textSecondary)
                .frame(width: 44, height: 44)
                .background(Theme.surface)
                .clipShape(Circle())
                .overlay(Circle().stroke(Theme.stroke, lineWidth: 0.5))
        }
        .accessibilityLabel(label)
    }

    // MARK: - Weekly muscle map

    private var weeklyMuscleSection: some View {
        let since = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? .distantPast
        let activation = MuscleActivation.forSessions(sessions, since: since)
        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Trained this week")
            Card {
                MuscleMapView(activation: activation, figureHeight: 200)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Quick start

    private var quickStartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Quick start", trailing: AnyView(
                NavigationLink {
                    WorkoutListView()
                } label: {
                    Text("All")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
            ))

            if workouts.isEmpty {
                emptyQuickStartCard
            } else {
                if let split = activeSplits.first {
                    splitHeroCard(split: split)
                    addToSplitButton(split: split)
                }
                otherWorkoutsList(exclude: activeSplits.first?.nextWorkout)
            }
        }
    }

    private var emptyQuickStartCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                Text("No workouts yet")
                    .font(.title)
                    .foregroundStyle(Theme.textPrimary)
                Text("Create your first workout to get started.")
                    .font(.bodyMd)
                    .foregroundStyle(Theme.textSecondary)
                NavigationLink {
                    WorkoutEditorView()
                } label: { Text("Create workout") }
                    .primaryButton()
                    .padding(.top, 6)
            }
        }
    }

    @ViewBuilder
    private func splitHeroCard(split: Split) -> some View {
        if let next = split.nextWorkout {
            Button { quickStartTarget = next } label: {
                Card(elevated: true) {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text(heroLabel(for: split).uppercased())
                                .font(.caption)
                                .tracking(1.2)
                                .foregroundStyle(Theme.textMuted)
                            Spacer()
                            Text(heroSubLabel(for: split))
                                .font(.caption)
                                .foregroundStyle(Theme.textMuted)
                        }
                        Text(next.name)
                            .font(.titleLg)
                            .foregroundStyle(Theme.textPrimary)
                        HStack(spacing: 10) {
                            Text("\(next.orderedExercises.count) exercise\(next.orderedExercises.count == 1 ? "" : "s") • from \(split.name)")
                                .font(.bodyMd)
                                .foregroundStyle(Theme.textSecondary)
                            Spacer()
                            Image(systemName: "play.fill")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(Theme.accentOnAccent)
                                .frame(width: 40, height: 40)
                                .background(Theme.accent)
                                .clipShape(Circle())
                        }
                    }
                }
            }
            .buttonStyle(.plain)
        } else if split.scheduleMode == .scheduled {
            // Scheduled mode with no workout for today = rest day.
            Card(elevated: true) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("REST DAY")
                        .font(.caption)
                        .tracking(1.2)
                        .foregroundStyle(Theme.textMuted)
                    Text("No workout scheduled today")
                        .font(.titleLg)
                        .foregroundStyle(Theme.textPrimary)
                    Text("from \(split.name)")
                        .font(.bodyMd)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
    }

    private func addToSplitButton(split: Split) -> some View {
        Button { showAddToSplit = true } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 15, weight: .semibold))
                Text("Add workout to \(split.name)")
                    .font(.caption)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Theme.textMuted)
            }
            .foregroundStyle(Theme.textSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSm, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusSm, style: .continuous)
                    .stroke(Theme.stroke, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }

    private func heroLabel(for split: Split) -> String {
        switch split.scheduleMode {
        case .asynchronous: return "Up next"
        case .scheduled:    return "Today"
        }
    }

    private func heroSubLabel(for split: Split) -> String {
        switch split.scheduleMode {
        case .asynchronous:
            return "Day \(split.currentIndex + 1) / \(split.orderedWorkouts.count)"
        case .scheduled:
            return Weekday.today.shortName
        }
    }

    private func otherWorkoutsList(exclude: Workout?) -> some View {
        let excludeID = exclude?.uuid
        let counts = completionCounts
        let others = workouts
            .filter { excludeID == nil || $0.uuid != excludeID }
            .sorted { a, b in
                let ca = counts[a.uuid] ?? 0
                let cb = counts[b.uuid] ?? 0
                if ca != cb { return ca > cb }          // most-completed first
                return a.createdAt > b.createdAt         // newest as tie-break
            }
            .prefix(4)
        return VStack(alignment: .leading, spacing: 10) {
            if exclude != nil && !others.isEmpty {
                Text("OTHER WORKOUTS")
                    .font(.caption)
                    .tracking(1.2)
                    .foregroundStyle(Theme.textMuted)
                    .padding(.top, 6)
            }
            ForEach(Array(others)) { workout in
                workoutRow(workout, completions: counts[workout.uuid] ?? 0)
            }
        }
    }

    /// Number of finished sessions logged per workout, used to rank the
    /// "other workouts" list by how often the user actually trains them.
    private var completionCounts: [UUID: Int] {
        var counts: [UUID: Int] = [:]
        for session in sessions where session.isFinished {
            guard let id = session.workout?.uuid else { continue }
            counts[id, default: 0] += 1
        }
        return counts
    }

    private func workoutRow(_ workout: Workout, completions: Int) -> some View {
        Button { quickStartTarget = workout } label: {
            Card {
                HStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(workout.name)
                            .font(.title)
                            .foregroundStyle(Theme.textPrimary)
                        HStack(spacing: 6) {
                            Text("\(workout.orderedExercises.count) exercise\(workout.orderedExercises.count == 1 ? "" : "s")")
                                .font(.bodyMd)
                                .foregroundStyle(Theme.textSecondary)
                            if completions > 0 {
                                Text("• done \(completions)×")
                                    .font(.bodyMd)
                                    .foregroundStyle(Theme.textMuted)
                            }
                        }
                    }
                    Spacer()
                    Image(systemName: "play.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Theme.accentOnAccent)
                        .frame(width: 36, height: 36)
                        .background(Theme.accent)
                        .clipShape(Circle())
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Manage / recent

    private var manageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Manage")
            HStack(spacing: 12) {
                NavigationLink { ExerciseListView() } label: {
                    manageTile(icon: "dumbbell.fill", title: "Exercises")
                }
                NavigationLink { WorkoutListView() } label: {
                    manageTile(icon: "list.bullet.rectangle.fill", title: "Workouts")
                }
            }
            HStack(spacing: 12) {
                NavigationLink { SplitListView() } label: {
                    manageTile(icon: "calendar", title: "Splits")
                }
                NavigationLink { HistoryView() } label: {
                    manageTile(icon: "clock.arrow.circlepath", title: "History")
                }
            }
        }
    }

    private func manageTile(icon: String, title: String) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text(title)
                    .font(.bodyBold)
                    .foregroundStyle(Theme.textPrimary)
            }
            .frame(height: 70, alignment: .topLeading)
        }
    }

    private func recentSection(session: WorkoutSession) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Most recent", trailing: AnyView(
                NavigationLink {
                    HistoryView()
                } label: {
                    Text("All")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
            ))
            NavigationLink {
                SessionDetailView(session: session)
            } label: {
                Card {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(session.workoutName)
                            .font(.title)
                            .foregroundStyle(Theme.textPrimary)
                        HStack(spacing: 12) {
                            Text(Format.shortDate(session.startedAt))
                            Text("•")
                            Text(Format.elapsed(session.elapsed))
                        }
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    private func greetingDate() -> String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        return f.string(from: Date()).uppercased()
    }

    private func start(workout: Workout, split: Split?) {
        let session = WorkoutSession(workout: workout, split: split)
        context.insert(session)
        try? context.save()
        pendingSession = session
    }

    /// Appends newly-picked workouts to the active split, preserving its
    /// existing order and any weekday assignments.
    private func addWorkouts(_ picked: [Workout], to split: Split) {
        guard !picked.isEmpty else { return }
        let existing = split.orderedWorkouts
        let existingIDs = Set(existing.map(\.uuid))
        let toAdd = picked.filter { !existingIDs.contains($0.uuid) }
        guard !toAdd.isEmpty else { return }
        split.setWorkouts(existing + toAdd)
        try? context.save()
    }
}

#Preview {
    HomeView()
        .environmentObject(AppleSignInController())
        .modelContainer(for: [Exercise.self, Workout.self, Split.self, WorkoutSession.self, ExerciseLog.self, SetLog.self], inMemory: true)
}
