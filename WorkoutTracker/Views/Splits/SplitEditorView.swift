import SwiftUI
import SwiftData

struct SplitEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var split: Split?

    @State private var name: String = ""
    @State private var selected: [Workout] = []
    @State private var currentIndex: Int = 0
    @State private var isActive: Bool = false
    @State private var scheduleMode: SplitScheduleMode = .asynchronous
    /// weekday.rawValue → workout UUID string ("" = rest)
    @State private var weeklyAssignments: [String] = Array(repeating: "", count: 7)
    @State private var showPicker = false
    @State private var showDeleteConfirm = false

    @Query(sort: \Workout.createdAt, order: .reverse) private var allWorkouts: [Workout]
    @Query(filter: #Predicate<Split> { $0.isActive == true }) private var activeSplits: [Split]

    private var isNew: Bool { split == nil }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    LabeledField(label: "Name") {
                        TextField("PPL", text: $name)
                            .foregroundStyle(Theme.textPrimary)
                    }

                    activeToggle
                    modeSection
                    workoutsSection

                    if scheduleMode == .asynchronous {
                        positionSection
                    } else {
                        weeklyScheduleSection
                    }

                    Button { save() } label: {
                        Text(isNew ? "Create split" : "Save changes")
                    }
                    .primaryButton()
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)

                    if !isNew {
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Text("Delete split")
                        }
                        .secondaryButton()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle(isNew ? "New split" : "Edit split")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isNew {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .sheet(isPresented: $showPicker) {
            WorkoutPickerView(allWorkouts: allWorkouts, selectedUUIDs: Set(selected.map(\.uuid))) { picked in
                let existing = selected.map(\.uuid)
                let toAdd = picked.filter { !existing.contains($0.uuid) }
                selected.append(contentsOf: toAdd)
            }
            .preferredColorScheme(.dark)
        }
        .confirmationDialog("Delete \(split?.name ?? "split")?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { delete() }
            Button("Cancel", role: .cancel) {}
        }
        .onAppear(perform: loadIfEditing)
    }

    private var activeToggle: some View {
        Toggle(isOn: $isActive) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Active split")
                    .font(.bodyMd)
                    .foregroundStyle(Theme.textPrimary)
                Text("Shows on the home screen as your next workout.")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .tint(Theme.accent)
        .padding(.horizontal, 14)
        .frame(minHeight: 64)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSm, style: .continuous))
    }

    private var modeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Mode")
            Picker("", selection: $scheduleMode) {
                ForEach(SplitScheduleMode.allCases) { m in
                    Text(m.shortLabel).tag(m)
                }
            }
            .pickerStyle(.segmented)

            Text(scheduleMode.explainer)
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
                .padding(.horizontal, 4)
        }
    }

    private var workoutsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: scheduleMode == .asynchronous ? "Workout order" : "Workouts in this split",
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
                    Text(scheduleMode == .asynchronous
                         ? "Add workouts to define the rotation."
                         : "Add workouts you can assign to days below.")
                        .font(.bodyMd)
                        .foregroundStyle(Theme.textSecondary)
                }
            } else {
                VStack(spacing: 10) {
                    ForEach(Array(selected.enumerated()), id: \.element.uuid) { idx, w in
                        rowItem(w: w, idx: idx)
                    }
                }
            }
        }
    }

    private func rowItem(w: Workout, idx: Int) -> some View {
        Card(padding: 12) {
            HStack(spacing: 12) {
                Text("\(idx + 1)")
                    .font(.mono)
                    .foregroundStyle(scheduleMode == .asynchronous && idx == currentIndex ? Theme.accent : Theme.textMuted)
                    .frame(width: 22)
                VStack(alignment: .leading, spacing: 2) {
                    Text(w.name)
                        .font(.bodyBold)
                        .foregroundStyle(Theme.textPrimary)
                    Text("\(w.orderedExercises.count) exercises")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                HStack(spacing: 4) {
                    if scheduleMode == .asynchronous {
                        Button { move(idx, by: -1) } label: { Image(systemName: "chevron.up") }
                            .frame(width: 32, height: 32)
                            .disabled(idx == 0)
                        Button { move(idx, by: 1) } label: { Image(systemName: "chevron.down") }
                            .frame(width: 32, height: 32)
                            .disabled(idx == selected.count - 1)
                    }
                    Button(role: .destructive) {
                        let removed = selected[idx]
                        selected.remove(at: idx)
                        if currentIndex >= selected.count { currentIndex = max(0, selected.count - 1) }
                        // Also clear any weekday assignments pointing at the removed workout.
                        let removedID = removed.uuid.uuidString
                        weeklyAssignments = weeklyAssignments.map { $0 == removedID ? "" : $0 }
                    } label: { Image(systemName: "xmark") }
                        .frame(width: 32, height: 32)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
    }

    @ViewBuilder
    private var positionSection: some View {
        if !selected.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Current position")
                Card {
                    VStack(spacing: 14) {
                        StepperRow(label: "Day index", value: $currentIndex, range: 0...(max(0, selected.count - 1)))
                        HStack {
                            Text("Up next").font(.bodyMd).foregroundStyle(Theme.textSecondary)
                            Spacer()
                            Text(selected[safe: currentIndex]?.name ?? "—")
                                .font(.bodyBold)
                                .foregroundStyle(Theme.textPrimary)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var weeklyScheduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Weekly schedule")
            if selected.isEmpty {
                Card {
                    Text("Add workouts above to assign them to days.")
                        .font(.bodyMd)
                        .foregroundStyle(Theme.textSecondary)
                }
            } else {
                Card {
                    VStack(spacing: 12) {
                        ForEach(Weekday.displayOrder) { day in
                            weekdayRow(day)
                            if day != Weekday.displayOrder.last {
                                Divider().background(Theme.stroke)
                            }
                        }
                    }
                }
            }
        }
    }

    private func weekdayRow(_ day: Weekday) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(day.shortName)
                    .font(.bodyBold)
                    .foregroundStyle(Theme.textPrimary)
                if day == Weekday.today {
                    Text("TODAY")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1.2)
                        .foregroundStyle(Theme.accent)
                }
            }
            .frame(width: 48, alignment: .leading)
            Spacer()
            Picker("", selection: bindingFor(day)) {
                Text("Rest").tag("")
                ForEach(selected) { w in
                    Text(w.name).tag(w.uuid.uuidString)
                }
            }
            .tint(Theme.textPrimary)
        }
    }

    private func bindingFor(_ day: Weekday) -> Binding<String> {
        Binding(
            get: {
                guard day.rawValue < weeklyAssignments.count else { return "" }
                let val = weeklyAssignments[day.rawValue]
                // If the assignment references a workout no longer in `selected`, treat as Rest.
                if val.isEmpty { return "" }
                let valid = selected.contains { $0.uuid.uuidString == val }
                return valid ? val : ""
            },
            set: { newValue in
                ensureWeeklyArrayLength()
                weeklyAssignments[day.rawValue] = newValue
            }
        )
    }

    private func ensureWeeklyArrayLength() {
        while weeklyAssignments.count < 7 { weeklyAssignments.append("") }
    }

    private func move(_ idx: Int, by delta: Int) {
        let new = idx + delta
        guard new >= 0, new < selected.count else { return }
        selected.swapAt(idx, new)
        if currentIndex == idx { currentIndex = new }
        else if currentIndex == new { currentIndex = idx }
    }

    private func loadIfEditing() {
        guard let s = split else {
            ensureWeeklyArrayLength()
            return
        }
        name = s.name
        selected = s.orderedWorkouts
        currentIndex = s.currentIndex
        isActive = s.isActive
        scheduleMode = s.scheduleMode
        weeklyAssignments = s.weeklyWorkoutUUIDStrings
        ensureWeeklyArrayLength()
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        // Enforce single active split.
        if isActive {
            for s in activeSplits where s !== split {
                s.isActive = false
            }
        }

        ensureWeeklyArrayLength()

        // Drop assignments referencing workouts no longer in this split.
        let validIDs = Set(selected.map(\.uuid.uuidString))
        let cleanedAssignments = weeklyAssignments.map { validIDs.contains($0) ? $0 : "" }

        if let s = split {
            s.name = trimmed
            s.setWorkouts(selected)
            s.currentIndex = min(currentIndex, max(0, selected.count - 1))
            s.isActive = isActive
            s.scheduleMode = scheduleMode
            s.weeklyWorkoutUUIDStrings = cleanedAssignments
        } else {
            let new = Split(name: trimmed, workouts: selected)
            new.currentIndex = min(currentIndex, max(0, selected.count - 1))
            new.isActive = isActive
            new.scheduleMode = scheduleMode
            new.weeklyWorkoutUUIDStrings = cleanedAssignments
            context.insert(new)
        }
        try? context.save()
        dismiss()
    }

    private func delete() {
        guard let s = split else { return }
        context.delete(s)
        try? context.save()
        dismiss()
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

struct WorkoutPickerView: View {
    let allWorkouts: [Workout]
    let selectedUUIDs: Set<UUID>
    let onPicked: ([Workout]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var picking: Set<UUID> = []

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                if allWorkouts.isEmpty {
                    EmptyStateView(
                        systemImage: "list.bullet.rectangle",
                        title: "No workouts yet",
                        subtitle: "Create workouts first to add them to a split."
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(allWorkouts) { w in
                                rowButton(w)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 80)
                    }
                }

                VStack {
                    Spacer()
                    Button("Add \(picking.count) workout\(picking.count == 1 ? "" : "s")") {
                        onPicked(allWorkouts.filter { picking.contains($0.uuid) })
                        dismiss()
                    }
                    .primaryButton()
                    .disabled(picking.isEmpty)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Add workouts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func rowButton(_ w: Workout) -> some View {
        let isAlready = selectedUUIDs.contains(w.uuid)
        let isPicking = picking.contains(w.uuid)
        return Button {
            if isAlready { return }
            if isPicking { picking.remove(w.uuid) } else { picking.insert(w.uuid) }
        } label: {
            Card(padding: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(w.name)
                            .font(.bodyBold)
                            .foregroundStyle(isAlready ? Theme.textMuted : Theme.textPrimary)
                        Text("\(w.orderedExercises.count) exercises")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                    if isAlready {
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
        .disabled(isAlready)
    }
}
