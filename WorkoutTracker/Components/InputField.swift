import SwiftUI

struct LabeledField<Content: View>: View {
    let label: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(.caption)
                .tracking(1.1)
                .foregroundStyle(Theme.textMuted)
            content()
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSm, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.radiusSm, style: .continuous)
                        .stroke(Theme.stroke, lineWidth: 0.5)
                )
        }
    }
}

struct StepperRow: View {
    let label: String
    @Binding var value: Int
    var range: ClosedRange<Int> = 0...999
    var step: Int = 1

    var body: some View {
        HStack {
            Text(label)
                .font(.bodyMd)
                .foregroundStyle(Theme.textSecondary)
            Spacer()
            HStack(spacing: 0) {
                Button { adjust(-step) } label: { Image(systemName: "minus") }
                    .frame(width: 44, height: 36)
                Text("\(value)")
                    .font(.mono)
                    .foregroundStyle(Theme.textPrimary)
                    .frame(minWidth: 44)
                Button { adjust(step) } label: { Image(systemName: "plus") }
                    .frame(width: 44, height: 36)
            }
            .foregroundStyle(Theme.textPrimary)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSm, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusSm, style: .continuous)
                    .stroke(Theme.stroke, lineWidth: 0.5)
            )
        }
    }

    private func adjust(_ delta: Int) {
        let new = value + delta
        value = min(max(new, range.lowerBound), range.upperBound)
    }
}

struct DoubleStepperRow: View {
    let label: String
    @Binding var value: Double
    var step: Double = 2.5
    var range: ClosedRange<Double> = 0...2000

    var body: some View {
        HStack {
            Text(label)
                .font(.bodyMd)
                .foregroundStyle(Theme.textSecondary)
            Spacer()
            HStack(spacing: 0) {
                Button { adjust(-step) } label: { Image(systemName: "minus") }
                    .frame(width: 44, height: 36)
                Text(Format.weight(value))
                    .font(.mono)
                    .foregroundStyle(Theme.textPrimary)
                    .frame(minWidth: 56)
                Button { adjust(step) } label: { Image(systemName: "plus") }
                    .frame(width: 44, height: 36)
            }
            .foregroundStyle(Theme.textPrimary)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSm, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusSm, style: .continuous)
                    .stroke(Theme.stroke, lineWidth: 0.5)
            )
        }
    }

    private func adjust(_ delta: Double) {
        let new = value + delta
        value = min(max(new, range.lowerBound), range.upperBound)
    }
}
