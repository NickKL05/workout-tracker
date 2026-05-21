import SwiftUI
import SwiftData
import UIKit

struct SetEntryView: View {
    @Bindable var set: SetLog
    let type: ExerciseType
    let isUnilateral: Bool
    let onDelete: () -> Void

    @Environment(\.modelContext) private var context

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Text("\(set.setNumber)")
                .font(.mono)
                .foregroundStyle(set.completed ? Theme.accent : Theme.textMuted)
                .frame(width: 24)

            fields

            Button {
                set.completed.toggle()
                if set.completed { set.loggedAt = Date() }
                try? context.save()
            } label: {
                Image(systemName: set.completed ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundStyle(set.completed ? Theme.accent : Theme.textMuted)
            }
            .buttonStyle(.plain)

            Menu {
                Button(role: .destructive) { onDelete() } label: { Label("Delete set", systemImage: "trash") }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.textMuted)
                    .frame(width: 28, height: 28)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(set.completed ? Theme.surfaceElevated.opacity(0.6) : Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSm, style: .continuous))
    }

    @ViewBuilder
    private var fields: some View {
        HStack(spacing: 6) {
            if type.tracksWeight {
                numericField(label: "lbs", value: Binding(
                    get: { Format.weight(set.weight) },
                    set: { set.weight = parseDouble($0) }
                ), keyboard: .decimalPad, width: 64)
            }
            if type.tracksReps {
                if isUnilateral {
                    numericField(label: "L", value: Binding(
                        get: { String(set.leftReps) },
                        set: { set.leftReps = parseInt($0) }
                    ), keyboard: .numberPad, width: 44)
                    numericField(label: "R", value: Binding(
                        get: { String(set.rightReps) },
                        set: { set.rightReps = parseInt($0) }
                    ), keyboard: .numberPad, width: 44)
                } else {
                    numericField(label: "reps", value: Binding(
                        get: { String(set.reps) },
                        set: { set.reps = parseInt($0) }
                    ), keyboard: .numberPad, width: 56)
                }
            }
            if type.tracksTime {
                numericField(label: "sec", value: Binding(
                    get: { String(set.durationSeconds) },
                    set: { set.durationSeconds = parseInt($0) }
                ), keyboard: .numberPad, width: 60)
            }
            if type.tracksIntensity {
                numericField(label: "int", value: Binding(
                    get: { String(set.intensity) },
                    set: { set.intensity = min(10, max(0, parseInt($0))) }
                ), keyboard: .numberPad, width: 44)
            }
        }
    }

    private func numericField(label: String, value: Binding<String>, keyboard: UIKeyboardType, width: CGFloat) -> some View {
        VStack(spacing: 2) {
            TextField("", text: value)
                .keyboardType(keyboard)
                .multilineTextAlignment(.center)
                .font(.mono)
                .foregroundStyle(Theme.textPrimary)
                .frame(width: width, height: 32)
                .background(Theme.background)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(Theme.stroke, lineWidth: 0.5)
                )
                .onChange(of: value.wrappedValue) { _, _ in try? context.save() }
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(Theme.textMuted)
        }
    }

    private func parseInt(_ s: String) -> Int {
        Int(s.trimmingCharacters(in: .whitespaces)) ?? 0
    }

    private func parseDouble(_ s: String) -> Double {
        Double(s.trimmingCharacters(in: .whitespaces)) ?? 0
    }
}
