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

    @Query(sort: \Exercise.name) private var allExercises: [Exercise]

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
            ExercisePickerView(allExercises: allExercises, selectedUUIDs: Set(selected.map(\.uuid))) { picked in
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
            SectionHeader(
                title: "Exercises",
                trailing: AnyView(
                    Button { showPicker = true } label: {
                        Label("Add", systemImage: "plus")
                            .font(.caption)
                    }
                    .foregroundStyle(Theme.textPrimary)
                )
            )
            if selected.isEmpty {
                Card {
                    Text("Tap “Add” to include exercises.")
                        .font(.bodyMd)
                        .foregroundStyle(Theme.textSecondary)
                }
            } else {
                VStack(spacing: 10) {
                    ForEach(Array(selected.enumerated()), id: \.element.uuid) { idx, ex in
                        exerciseRow(ex: ex, idx: idx)
                    }
                }
            }
        }
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

struct ExercisePickerView: View {
    let allExercises: [Exercise]
    let selectedUUIDs: Set<UUID>
    let onPicked: ([Exercise]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var picking: Set<UUID> = []

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                if allExercises.isEmpty {
                    EmptyStateView(
                        systemImage: "dumbbell",
                        title: "No exercises yet",
                        subtitle: "Create exercises first to add them to a workout."
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(allExercises) { ex in
                                rowButton(ex)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 80)
                    }
                }

                VStack {
                    Spacer()
                    Button("Add \(picking.count) exercise\(picking.count == 1 ? "" : "s")") {
                        onPicked(allExercises.filter { picking.contains($0.uuid) })
                        dismiss()
                    }
                    .primaryButton()
                    .disabled(picking.isEmpty)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Add exercises")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func rowButton(_ ex: Exercise) -> some View {
        let isAlreadyAdded = selectedUUIDs.contains(ex.uuid)
        let isPicking = picking.contains(ex.uuid)
        return Button {
            if isAlreadyAdded { return }
            if isPicking { picking.remove(ex.uuid) } else { picking.insert(ex.uuid) }
        } label: {
            Card(padding: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(ex.name)
                            .font(.bodyBold)
                            .foregroundStyle(isAlreadyAdded ? Theme.textMuted : Theme.textPrimary)
                        Text(ex.type.displayName)
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                    if isAlreadyAdded {
                        Text("Added")
                            .font(.caption)
                            .foregroundStyle(Theme.textMuted)
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
}
