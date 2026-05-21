import SwiftUI
import SwiftData

struct ExerciseListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Exercise.name) private var exercises: [Exercise]

    @State private var showCreate = false

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
                LazyVStack(spacing: 12) {
                    ForEach(exercises) { ex in
                        NavigationLink {
                            ExerciseEditorView(exercise: ex)
                        } label: {
                            row(ex)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
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
        switch ex.type {
        case .weightReps:
            return "Strength • Goal: \(ex.goalSets)×\(ex.goalReps) • +\(Format.weight(ex.weightIncrement)) lbs"
        case .weightTime:
            return "Timed • Goal: \(ex.goalSets)×\(Format.duration(ex.goalDurationSeconds)) • +\(Format.weight(ex.weightIncrement)) lbs"
        case .cardio:
            return "Cardio • \(Format.duration(ex.goalDurationSeconds)) @ int \(ex.goalIntensity)"
        }
    }
}
