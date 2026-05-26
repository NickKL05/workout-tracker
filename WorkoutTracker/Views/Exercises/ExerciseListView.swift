import SwiftUI
import SwiftData

struct ExerciseListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Exercise.name) private var exercises: [Exercise]

    @State private var showCreate = false
    @State private var search: String = ""
    @State private var collapsedGroups: Set<MuscleGroup> = []

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            content
        }
        .navigationTitle("Exercises")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showCreate = true } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
        }
        .sheet(isPresented: $showCreate) {
            NavigationStack {
                ExerciseEditorView()
            }
            .preferredColorScheme(.dark)
        }
    }

    private var filteredExercises: [Exercise] {
        let q = search.trimmingCharacters(in: .whitespaces).lowercased()
        if q.isEmpty { return exercises }
        return exercises.filter { $0.name.lowercased().contains(q) }
    }

    private var groupedExercises: [(MuscleGroup, [Exercise])] {
        let grouped = Dictionary(grouping: filteredExercises) { $0.muscleGroup }
        return MuscleGroup.displayOrder.compactMap { g in
            guard let items = grouped[g], !items.isEmpty else { return nil }
            return (g, items)
        }
    }

    @ViewBuilder
    private var content: some View {
        if exercises.isEmpty {
            EmptyStateView(
                systemImage: "dumbbell",
                title: "No exercises",
                subtitle: "Create exercises to add to your workouts.",
                actionTitle: "Create exercise",
                action: { showCreate = true }
            )
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    searchBar
                    if filteredExercises.isEmpty {
                        Card {
                            Text("No exercises match “\(search)”.")
                                .font(.bodyMd)
                                .foregroundStyle(Theme.textSecondary)
                        }
                    } else {
                        ForEach(groupedExercises, id: \.0) { group, items in
                            groupSection(group: group, items: items)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundStyle(Theme.textMuted)
            TextField("Search exercises", text: $search)
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

    private func groupSection(group: MuscleGroup, items: [Exercise]) -> some View {
        let isCollapsed = collapsedGroups.contains(group)
        return VStack(alignment: .leading, spacing: 10) {
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
                LazyVStack(spacing: 10) {
                    ForEach(items) { ex in
                        NavigationLink {
                            ExerciseEditorView(exercise: ex)
                        } label: {
                            row(ex)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func row(_ ex: Exercise) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(ex.name)
                        .font(.title)
                        .foregroundStyle(Theme.textPrimary)
                    if ex.isUnilateral {
                        Text("L/R")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Theme.strokeStrong)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(Theme.textMuted)
                }
                Text(subtitle(for: ex))
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    private func subtitle(for ex: Exercise) -> String {
        let equip = ex.equipment.displayName
        switch ex.type {
        case .weightReps:
            return "\(equip) • \(ex.goalSets)×\(ex.goalReps) • +\(Format.weight(ex.weightIncrement)) lbs"
        case .weightTime:
            return "\(equip) • \(ex.goalSets)×\(Format.duration(ex.goalDurationSeconds))"
        case .cardio:
            return "\(equip) • \(Format.duration(ex.goalDurationSeconds)) @ int \(ex.goalIntensity)"
        }
    }
}
