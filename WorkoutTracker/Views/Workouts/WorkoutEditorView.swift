import SwiftUI
import SwiftData

struct WorkoutEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var workout: Workout?

    @State private var name: String = ""
    @State private var selected: [Exercise] = []
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
                selectedUUIDs: Set(selected.map(\.uuid))
            ) { picked in
                let existing = selected.map(\.uuid)
                let toAdd = picked.filter { !existing.contains($0.uuid) }
                selected.append(contentsOf: toAdd)
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
            if selected.isEmpty {
                emptyExercisesCard
            } else {
                VStack(spacing: 10) {
                    ForEach(Array(selected.enumerated()), id: \.element.uuid) { idx, ex in
                        exerciseRow(ex: ex, idx: idx)
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

    private func exerciseRow(ex: Exercise, idx: Int) -> some View {
        Card(padding: 12) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(ex.name)
                        .font(.bodyBold)
                        .foregroundStyle(Theme.textPrimary)
                    Text(subtitle(for: ex))
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
                        .disabled(idx == selected.count - 1)
                    Button(role: .destructive) {
                        selected.remove(at: idx)
                    } label: { Image(systemName: "xmark") }
                        .frame(width: 32, height: 32)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
    }

    private func subtitle(for ex: Exercise) -> String {
        switch ex.type {
        case .weightReps:
            return "\(ex.goalSets)×\(ex.goalReps)\(ex.isUnilateral ? " L/R" : "")"
        case .weightTime:
            return "\(ex.goalSets)×\(Format.duration(ex.goalDurationSeconds))"
        case .cardio:
            return "\(Format.duration(ex.goalDurationSeconds)) @ int \(ex.goalIntensity)"
        }
    }

    private func move(_ idx: Int, by delta: Int) {
        let new = idx + delta
        guard new >= 0, new < selected.count else { return }
        selected.swapAt(idx, new)
    }

    private func loadIfEditing() {
        guard let w = workout else { return }
        name = w.name
        selected = w.orderedExercises
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        if let w = workout {
            w.name = trimmed
            w.setExercises(selected)
        } else {
            let new = Workout(name: trimmed, exercises: selected)
            context.insert(new)
        }
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

// MARK: - Exercise Picker

struct ExercisePickerView: View {
    let workoutName: String
    let selectedUUIDs: Set<UUID>
    let onPicked: ([Exercise]) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \Exercise.name) private var allExercises: [Exercise]

    @State private var search: String = ""
    @State private var picking: Set<UUID> = []
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
        let isPicking = picking.contains(ex.uuid)
        return Button {
            if isAlreadyAdded { return }
            if isPicking { picking.remove(ex.uuid) } else { picking.insert(ex.uuid) }
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
                    } else {
                        Image(systemName: isPicking ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 22))
                            .foregroundStyle(isPicking ? Theme.accent : Theme.textMuted)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(isAlreadyAdded)
    }

    private func subtitle(for ex: Exercise) -> String {
        let equip = ex.equipment.displayName
        switch ex.type {
        case .weightReps: return "\(equip) • \(ex.goalSets)×\(ex.goalReps)\(ex.isUnilateral ? " L/R" : "")"
        case .weightTime: return "\(equip) • \(ex.goalSets)×\(Format.duration(ex.goalDurationSeconds))"
        case .cardio:     return "\(equip) • \(Format.duration(ex.goalDurationSeconds))"
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 10) {
            if !picking.isEmpty {
                Button("Add \(picking.count) exercise\(picking.count == 1 ? "" : "s")") {
                    onPicked(allExercises.filter { picking.contains($0.uuid) })
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
