import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \WorkoutSession.startedAt, order: .reverse) private var sessions: [WorkoutSession]

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            content
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.large)
    }

    @ViewBuilder
    private var content: some View {
        if sessions.isEmpty {
            EmptyStateView(
                systemImage: "clock.arrow.circlepath",
                title: "No history yet",
                subtitle: "Finished workouts show up here."
            )
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(sessions) { s in
                        NavigationLink {
                            SessionDetailView(session: s)
                        } label: {
                            row(s)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
    }

    private func row(_ s: WorkoutSession) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(s.workoutName)
                        .font(.title)
                        .foregroundStyle(Theme.textPrimary)
                    if !s.isFinished {
                        Text("IN PROGRESS")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Theme.accent)
                            .foregroundStyle(Theme.accentOnAccent)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(Theme.textMuted)
                }
                HStack(spacing: 10) {
                    Text(Format.date(s.startedAt))
                    Text("•")
                    Text(Format.elapsed(s.elapsed))
                    if s.isFinished {
                        Text("•")
                        Text("\(s.exerciseLogs.count) exercises")
                    }
                }
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
            }
        }
    }
}
