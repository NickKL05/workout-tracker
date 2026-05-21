import SwiftUI
import SwiftData

struct WorkoutListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Workout.createdAt, order: .reverse) private var workouts: [Workout]
    @State private var showCreate = false

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            content
        }
        .navigationTitle("Workouts")
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
                WorkoutEditorView()
            }
            .preferredColorScheme(.dark)
        }
    }

    @ViewBuilder
    private var content: some View {
        if workouts.isEmpty {
            EmptyStateView(
                systemImage: "list.bullet.rectangle",
                title: "No workouts",
                subtitle: "Build a workout by combining exercises.",
                actionTitle: "Create workout",
                action: { showCreate = true }
            )
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(workouts) { w in
                        NavigationLink {
                            WorkoutEditorView(workout: w)
                        } label: {
                            row(w)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
    }

    private func row(_ w: Workout) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(w.name)
                        .font(.title)
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(Theme.textMuted)
                }
                Text(w.orderedExercises.map(\.name).joined(separator: " • "))
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(2)
            }
        }
    }
}
