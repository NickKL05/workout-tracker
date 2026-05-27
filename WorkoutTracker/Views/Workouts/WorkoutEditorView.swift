import SwiftUI
import SwiftData

struct WorkoutEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var workout: Workout?

    @State private var name: String = ""
    /// Transient editing rows. Each row owns its goal values for THIS workout
    /// only. On save we either update the matching `WorkoutExercise` (when
    /// `existingUUID` is set) or insert a new one.
    @State private var rows: [EditableRow] = []
    @State private var showPicker = false
    @State private var showDeleteConfirm = false

    private var isNew: Bool { workout == nil }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    LabeledField(label: "Name") {
                        TextField("Push Day", text: $name)
                            .foregroundStyle(Theme.textPrimary)
                            .submitLabel(.done)
                    }

                    exercisesSection

                    Button { save() } label: {
                        Text(isNew ? "Create workout" : "Save changes")
                    }
                    .primaryButton()
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)

                    if !isNew {
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Text("Delete workout")
                        }
                        .secondaryButton()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle(isNew ? "New workout" : "Edit workout")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isNew {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .sheet(isPresented: $showPicker) {
            ExercisePickerView(
                workoutName: name,
                selectedUUIDs: Set(rows.map(\.exercise.uuid))
            ) { picked in
                let existing = Set(rows.map(\.exercise.uuid))
                let toAdd = picked.filter { !existing.contains($0.uuid) }
                rows.append(contentsOf: toAdd.map { EditableRow(exercise: $0) })
            }
            .preferredColorScheme(.dark)
        }
        .confirmationDialog("Delete \(workout?.name ?? "workout")?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { delete() }
            Button("Cancel", role: .cancel) {}
        }
        .onAppear(perform: loadIfEditing)
    }

    private var exercisesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Exercises")
            if rows.isEmpty {
                emptyExercisesCard
            } else {
                VStack(spacing: 10) {
                    ForEach(rows.indices, id: \.self) { idx in
                        exerciseRow(idx: idx)
                    }
                }
                addExerciseButton
            }
        }
    }

    private var emptyExercisesCard: some View {
        Button { showPicker = true } label: {
            Card {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Theme.accent)
                            .frame(width: 44, height: 44)
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(Theme.accentOnAccent)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Add exercises")
                            .font(.title)
                            .foregroundStyle(Theme.textPrimary)
                        Text("Pick from your library or create a new one")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(Theme.textMuted)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var addExerciseButton: some View {
        Button { showPicker = true } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                Text("Add more exercises").font(.bodyBold)
            }
        }
        .secondaryButton()
    }

    private func exerciseRow(idx: Int) -> some View {
        let row = rows[idx]
        return Card(padding: 12) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(row.exercise.name)
                            .font(.bodyBold)
                            .foregroundStyle(Theme.textPrimary)
                        Text(metaSubtitle(for: row.exercise))
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                    HStack(spacing: 4) {
                        Button { move(idx, by: -1) } label: { Image(systemName: "chevron.up") }
                            .frame(width: 32, height: 32)
                            .disabled(idx == 0)
                        Button { move(idx, by: 1) } label: { Image(systemName: "chevron.down") }
                            .frame(width: 32, height: 32)
                            .disabled(idx == rows.count - 1)
                        Button(role: .destructive) {
                            rows.remove(at: idx)
                        } label: { Image(systemName: "xmark") }
                            .frame(width: 32, height: 32)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                Divider().background(Theme.stroke)
                goalEditors(for: idx)
            }
        }
    }

    @ViewBuilder
    private func goalEditors(for idx: Int) -> some View {
        let type = rows[idx].exercise.type
        VStack(spacing: 10) {
            if type == .weightReps || type == .weightTime {
                StepperRow(label: "Sets", value: $rows[idx].goalSets, range: 1...20)
            }
            if type == .weightReps {
                StepperRow(label: "Reps", value: $rows[idx].goalReps, range: 1...100)
            }
            if type == .weightTime || type == .cardio {
                StepperRow(label: "Duration (sec)", value: $rows[idx].goalDurationSeconds, range: 5...7200, step: 5)
            }
            if type == .cardio {
                StepperRow(label: "Intensity (1-10)", value: $rows[idx].goalIntensity, range: 1...10)
            }
        }
    }

    private func metaSubtitle(for ex: Exercise) -> String {
        var parts = [ex.equipment.displayName, ex.muscleGroup.displayName]
        if ex.isUnilateral { parts.append("L/R") }
        return parts.joined(separator: " • ")
    }

    private func move(_ idx: Int, by delta: Int) {
        let new = idx + delta
        guard new >= 0, new < rows.count else { return }
        rows.swapAt(idx, new)
    }

    private func loadIfEditing() {
        guard let w = workout else { return }
        name = w.name
        rows = w.orderedWorkoutExercises.map { EditableRow(workoutExercise: $0) }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        let target: Workout
        if let existing = workout {
            existing.name = trimmed
            target = existing
        } else {
            target = Workout(name: trimmed)
            context.insert(target)
        }

        let oldByUUID = Dictionary(uniqueKeysWithValues: target.workoutExercises.map { ($0.uuid, $0) })
        var keptUUIDs = Set<UUID>()
        var rebuilt: [WorkoutExercise] = []

        for (idx, row) in rows.enumerated() {
            if let existingID = row.existingUUID, let existingRow = oldByUUID[existingID] {
                existingRow.orderIndex = idx
                existingRow.goalSets = row.goalSets
                existingRow.goalReps = row.goalReps
                existingRow.goalDurationSeconds = row.goalDurationSeconds
                existingRow.goalIntensity = row.goalIntensity
                keptUUIDs.insert(existingID)
                rebuilt.append(existingRow)
            } else {
                // Don't set the inverse here — the final
                // `target.workoutExercises = rebuilt` assignment will do
                // it, and SwiftData would otherwise add the row twice.
                let we = WorkoutExercise(exercise: row.exercise, workout: nil, orderIndex: idx)
                we.goalSets = row.goalSets
                we.goalReps = row.goalReps
                we.goalDurationSeconds = row.goalDurationSeconds
                we.goalIntensity = row.goalIntensity
                context.insert(we)
                rebuilt.append(we)
            }
        }

        // Tombstone any rows that the user removed in this edit.
        for (uuid, row) in oldByUUID where !keptUUIDs.contains(uuid) {
            context.delete(row)
        }

        target.workoutExercises = rebuilt
        try? context.save()
        dismiss()
    }

    private func delete() {
        guard let w = workout else { return }
        context.delete(w)
        try? context.save()
        dismiss()
    }
}

// MARK: - Editable row (transient pre-save state)

struct EditableRow: Identifiable {
    let id = UUID()
    let exercise: Exercise
    var goalSets: Int
    var goalReps: Int
    var goalDurationSeconds: Int
    var goalIntensity: Int
    /// UUID of the existing WorkoutExercise this row maps to. Nil for
    /// freshly-picked rows.
    var existingUUID: UUID?

    init(exercise: Exercise) {
        self.exercise = exercise
        self.goalSets = exercise.goalSets
        self.goalReps = exercise.goalReps
        self.goalDurationSeconds = exercise.goalDurationSeconds
        self.goalIntensity = exercise.goalIntensity
        self.existingUUID = nil
    }

    init(workoutExercise: WorkoutExercise) {
        // If the underlying exercise has been deleted we drop this row;
        // callers filter out nils.
        guard let ex = workoutExercise.exercise else {
            // Defensive default - effectively unreachable in practice.
            self.exercise = Exercise(name: "")
            self.goalSets = workoutExercise.goalSets
            self.goalReps = workoutExercise.goalReps
            self.goalDurationSeconds = workoutExercise.goalDurationSeconds
            self.goalIntensity = workoutExercise.goalIntensity
            self.existingUUID = workoutExercise.uuid
            return
        }
        self.exercise = ex
        self.goalSets = workoutExercise.goalSets
        self.goalReps = workoutExercise.goalReps
        self.goalDurationSeconds = workoutExercise.goalDurationSeconds
        self.goalIntensity = workoutExercise.goalIntensity
        self.existingUUID = workoutExercise.uuid
    }
}

// MARK: - Exercise Picker

struct ExercisePickerView: View {
    let workoutName: String
    let selectedUUIDs: Set<UUID>
    let onPicked: ([Exercise]) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \Exercise.name) private var allExercises: [Exercise]

    @State private var search: String = ""
    /// Ordered by user tap sequence, so adding D, A, C, B yields D, A, C, B
    /// in the workout (not alphabetical).
    @State private var picking: [UUID] = []
    @State private var showCreate = false
    @State private var collapsedGroups: Set<MuscleGroup> = []

    /// Muscle groups inferred from keywords in the workout name.
    private var recommendedGroups: Set<MuscleGroup> {
        let lower = workoutName.lowercased()
        guard !lower.isEmpty else { return [] }
        var groups: Set<MuscleGroup> = []
        for g in MuscleGroup.allCases {
            for kw in g.workoutNameKeywords where lower.contains(kw) {
                groups.insert(g)
                break
            }
        }
        return groups
    }

    private var filteredExercises: [Exercise] {
        let q = search.trimmingCharacters(in: .whitespaces)
        if q.isEmpty { return allExercises }
        return allExercises.filter { ExerciseSearch.matches($0, query: q) }
    }

    private var groupedExercises: [(MuscleGroup, [Exercise])] {
        let grouped = Dictionary(grouping: filteredExercises) { $0.muscleGroup }
        return MuscleGroup.displayOrder.compactMap { g in
            guard let items = grouped[g], !items.isEmpty else { return nil }
            return (g, items)
        }
    }

    private var recommendedExercises: [Exercise] {
        guard !recommendedGroups.isEmpty else { return [] }
        return filteredExercises.filter { recommendedGroups.contains($0.muscleGroup) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        searchBar

                        if search.isEmpty && !recommendedExercises.isEmpty {
                            recommendedSection
                        }

                        allExercisesSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 200)
                }

                VStack {
                    Spacer()
                    bottomBar
                }
            }
            .navigationTitle("Add exercises")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showCreate) {
                NavigationStack {
                    ExerciseEditorView()
                }
                .preferredColorScheme(.dark)
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundStyle(Theme.textMuted)
            TextField("Try “DB curl”, “bench”, or “lats”", text: $search)
                .foregroundStyle(Theme.textPrimary)
                .submitLabel(.search)
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.never)
            if !search.isEmpty {
                Button { search = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(Theme.textMuted)
                }
            }
        }
        .padding(12)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSm, style: .continuous))
    }

    private var recommendedSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles").foregroundStyle(Theme.accent).font(.caption)
                Text("RECOMMENDED FOR \(workoutName.uppercased())")
                    .font(.caption)
                    .tracking(1.2)
                    .foregroundStyle(Theme.textMuted)
                    .lineLimit(1)
            }
            VStack(spacing: 8) {
                ForEach(recommendedExercises) { ex in
                    row(ex)
                }
            }
        }
    }

    private var allExercisesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !recommendedExercises.isEmpty && search.isEmpty {
                Text("ALL EXERCISES")
                    .font(.caption)
                    .tracking(1.2)
                    .foregroundStyle(Theme.textMuted)
                    .padding(.top, 8)
            }

            ForEach(groupedExercises, id: \.0) { group, items in
                groupSection(group: group, items: items)
            }

            if filteredExercises.isEmpty {
                Card {
                    Text("No exercises match. Use “Add new exercise” below to create one.")
                        .font(.bodyMd)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
    }

    private func groupSection(group: MuscleGroup, items: [Exercise]) -> some View {
        let isCollapsed = collapsedGroups.contains(group)
        return VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.15)) {
                    if isCollapsed {
                        collapsedGroups.remove(group)
                    } else {
                        collapsedGroups.insert(group)
                    }
                }
            } label: {
                HStack {
                    Text(group.displayName.uppercased())
                        .font(.caption)
                        .tracking(1.2)
                        .foregroundStyle(Theme.textMuted)
                    Text("(\(items.count))")
                        .font(.caption)
                        .foregroundStyle(Theme.textMuted.opacity(0.6))
                    Spacer()
                    Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(Theme.textMuted)
                }
                .padding(.top, 6)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if !isCollapsed {
                VStack(spacing: 8) {
                    ForEach(items) { ex in
                        row(ex)
                    }
                }
            }
        }
    }

    private func row(_ ex: Exercise) -> some View {
        let isAlreadyAdded = selectedUUIDs.contains(ex.uuid)
        return Button {
            if isAlreadyAdded { return }
            if let idx = picking.firstIndex(of: ex.uuid) {
                picking.remove(at: idx)
            } else {
                picking.append(ex.uuid)
            }
        } label: {
            Card(padding: 12) {
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(ex.name)
                            .font(.bodyBold)
                            .foregroundStyle(isAlreadyAdded ? Theme.textMuted : Theme.textPrimary)
                        Text(subtitle(for: ex))
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                    if isAlreadyAdded {
                        Text("Added").font(.caption).foregroundStyle(Theme.textMuted)
                    } else if let order = picking.firstIndex(of: ex.uuid) {
                        ZStack {
                            Circle()
                                .fill(Theme.accent)
                                .frame(width: 24, height: 24)
                            Text("\(order + 1)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(Theme.accentOnAccent)
                        }
                    } else {
                        Image(systemName: "circle")
                            .font(.system(size: 22))
                            .foregroundStyle(Theme.textMuted)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(isAlreadyAdded)
    }

    private func subtitle(for ex: Exercise) -> String {
        let equip = ex.equipment.displayName
        let muscle = ex.muscleGroup.displayName
        var parts = [equip, muscle]
        if ex.isUnilateral { parts.append("L/R") }
        return parts.joined(separator: " • ")
    }

    private var bottomBar: some View {
        VStack(spacing: 10) {
            if !picking.isEmpty {
                Button("Add \(picking.count) exercise\(picking.count == 1 ? "" : "s")") {
                    let byID = Dictionary(uniqueKeysWithValues: allExercises.map { ($0.uuid, $0) })
                    let ordered = picking.compactMap { byID[$0] }
                    onPicked(ordered)
                    dismiss()
                }
                .primaryButton()
            }
            Button {
                showCreate = true
            } label: {
                Label("Add new exercise", systemImage: "plus")
            }
            .secondaryButton()
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
        .padding(.top, 16)
        .background(
            LinearGradient(
                colors: [Theme.background.opacity(0), Theme.background, Theme.background],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}
