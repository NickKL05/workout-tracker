import SwiftUI
import SwiftData

struct ExerciseEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var exercise: Exercise?

    @State private var name: String = ""
    @State private var type: ExerciseType = .weightReps
    @State private var isUnilateral: Bool = false
    @State private var muscleGroup: MuscleGroup = .other
    @State private var equipment: Equipment = .other
    @State private var goalSets: Int = 3
    @State private var goalReps: Int = 8
    @State private var goalDurationSeconds: Int = 30
    @State private var goalIntensity: Int = 5
    @State private var weightIncrement: Double = 5.0
    @State private var intensityIncrement: Int = 1
    @State private var durationIncrementSeconds: Int = 30
    @State private var notes: String = ""

    @State private var showDeleteConfirm = false

    private var isNew: Bool { exercise == nil }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    LabeledField(label: "Name") {
                        TextField("Bench Press", text: $name)
                            .foregroundStyle(Theme.textPrimary)
                            .submitLabel(.done)
                    }

                    typeSection
                    categorySection
                    goalsSection
                    overloadSection

                    if let ex = exercise {
                        ExerciseProgressionView(exercise: ex)
                    }

                    LabeledField(label: "Notes") {
                        TextField("Optional", text: $notes)
                            .foregroundStyle(Theme.textPrimary)
                    }

                    Button { save() } label: {
                        Text(isNew ? "Create exercise" : "Save changes")
                    }
                    .primaryButton()
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)

                    if !isNew {
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Text("Delete exercise")
                        }
                        .secondaryButton()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle(isNew ? "New exercise" : "Edit exercise")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isNew {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .appConfirm(
            isPresented: $showDeleteConfirm,
            title: "Delete \(exercise?.name ?? "exercise")?",
            message: "This will remove it from any workouts that reference it.",
            confirmTitle: "Delete",
            destructive: true
        ) {
            delete()
        }
        .onAppear(perform: loadIfEditing)
    }

    private var typeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Type")
            Picker("", selection: $type) {
                ForEach(ExerciseType.allCases) { t in
                    Text(t.shortLabel).tag(t)
                }
            }
            .pickerStyle(.segmented)

            if type == .weightReps {
                Toggle(isOn: $isUnilateral) {
                    Text("Unilateral (L/R)")
                        .font(.bodyMd)
                        .foregroundStyle(Theme.textPrimary)
                }
                .tint(Theme.accent)
                .padding(.horizontal, 14)
                .frame(height: 56)
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSm, style: .continuous))
            }
        }
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Category")
            Card {
                VStack(spacing: 12) {
                    HStack {
                        Text("Muscle group")
                            .font(.bodyMd)
                            .foregroundStyle(Theme.textPrimary)
                        Spacer()
                        Picker("", selection: $muscleGroup) {
                            ForEach(MuscleGroup.displayOrder) { g in
                                Text(g.displayName).tag(g)
                            }
                        }
                        .tint(Theme.textPrimary)
                    }
                    Divider().background(Theme.stroke)
                    HStack {
                        Text("Equipment")
                            .font(.bodyMd)
                            .foregroundStyle(Theme.textPrimary)
                        Spacer()
                        Picker("", selection: $equipment) {
                            ForEach(Equipment.allCases) { e in
                                Text(e.displayName).tag(e)
                            }
                        }
                        .tint(Theme.textPrimary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Default sets & reps")
            Card {
                VStack(spacing: 14) {
                    StepperRow(label: "Sets", value: $goalSets, range: 1...20)
                    if type.tracksReps {
                        StepperRow(label: "Reps", value: $goalReps, range: 1...100)
                    }
                    if type == .weightTime {
                        StepperRow(label: "Duration (sec)", value: $goalDurationSeconds, range: 5...7200, step: 5)
                    }
                    if type == .cardio {
                        StepperRow(
                            label: "Duration (min)",
                            value: Binding(
                                get: { goalDurationSeconds / 60 },
                                set: { goalDurationSeconds = $0 * 60 }
                            ),
                            range: 1...180
                        )
                    }
                    if type.tracksIntensity {
                        StepperRow(label: "Intensity (1-10)", value: $goalIntensity, range: 1...10)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var overloadSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Progressive overload step")
            Card {
                VStack(spacing: 14) {
                    if type.tracksWeight {
                        DoubleStepperRow(label: "Weight step (lbs)", value: $weightIncrement, step: 0.5, range: 0.5...50)
                    }
                    if type == .cardio {
                        StepperRow(label: "Intensity step", value: $intensityIncrement, range: 1...3)
                        StepperRow(label: "Duration step (sec)", value: $durationIncrementSeconds, range: 5...600, step: 5)
                    }
                    if !type.tracksWeight && type != .cardio {
                        Text("No overload step applies").font(.caption).foregroundStyle(Theme.textMuted)
                    }
                }
            }
        }
    }

    private func loadIfEditing() {
        guard let ex = exercise else { return }
        name = ex.name
        type = ex.type
        isUnilateral = ex.isUnilateral
        muscleGroup = ex.muscleGroup
        equipment = ex.equipment
        goalSets = ex.goalSets
        goalReps = ex.goalReps
        goalDurationSeconds = ex.goalDurationSeconds
        goalIntensity = ex.goalIntensity
        weightIncrement = ex.weightIncrement
        intensityIncrement = ex.intensityIncrement
        durationIncrementSeconds = ex.durationIncrementSeconds
        notes = ex.notes
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        if let ex = exercise {
            ex.name = trimmed
            ex.type = type
            ex.isUnilateral = (type == .weightReps) ? isUnilateral : false
            ex.muscleGroup = muscleGroup
            ex.equipment = equipment
            ex.goalSets = goalSets
            ex.goalReps = goalReps
            ex.goalDurationSeconds = goalDurationSeconds
            ex.goalIntensity = goalIntensity
            ex.weightIncrement = weightIncrement
            ex.intensityIncrement = intensityIncrement
            ex.durationIncrementSeconds = durationIncrementSeconds
            ex.notes = notes
        } else {
            let new = Exercise(
                name: trimmed,
                type: type,
                isUnilateral: (type == .weightReps) ? isUnilateral : false,
                muscleGroup: muscleGroup,
                equipment: equipment,
                goalSets: goalSets,
                goalReps: goalReps,
                goalDurationSeconds: goalDurationSeconds,
                goalIntensity: goalIntensity,
                weightIncrement: weightIncrement,
                intensityIncrement: intensityIncrement,
                durationIncrementSeconds: durationIncrementSeconds,
                notes: notes
            )
            context.insert(new)
        }
        try? context.save()
        dismiss()
    }

    private func delete() {
        guard let ex = exercise else { return }
        context.delete(ex)
        try? context.save()
        dismiss()
    }
}
