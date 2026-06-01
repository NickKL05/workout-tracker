import SwiftUI
import SwiftData

struct SplitListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Split.createdAt, order: .reverse) private var splits: [Split]
    @State private var showCreate = false

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            content
        }
        .navigationTitle("Splits")
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
            NavigationStack { SplitEditorView() }
                .preferredColorScheme(.dark)
        }
    }

    @ViewBuilder
    private var content: some View {
        if splits.isEmpty {
            EmptyStateView(
                systemImage: "calendar",
                title: "No splits",
                subtitle: "Group workouts into a weekly plan.",
                actionTitle: "Create split",
                action: { showCreate = true }
            )
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(splits) { s in
                        NavigationLink {
                            SplitEditorView(split: s)
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

    private func row(_ s: Split) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(s.name)
                        .font(.title)
                        .foregroundStyle(Theme.textPrimary)
                    if s.isActive {
                        Text("ACTIVE")
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
                if s.orderedWorkouts.isEmpty {
                    Text("Empty").font(.caption).foregroundStyle(Theme.textMuted)
                } else {
                    Text("Day \(s.currentIndex + 1) / \(s.orderedWorkouts.count) • \(s.orderedWorkouts.map(\.name).joined(separator: " → "))")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(2)
                }
            }
        }
    }
}
