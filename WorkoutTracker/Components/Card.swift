import SwiftUI

struct Card<Content: View>: View {
    var padding: CGFloat = 16
    var elevated: Bool = false
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(elevated ? Theme.surfaceElevated : Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous)
                    .stroke(Theme.stroke, lineWidth: 0.5)
            )
    }
}

struct SectionHeader: View {
    let title: String
    var trailing: AnyView? = nil

    var body: some View {
        HStack {
            Text(title.uppercased())
                .font(.caption)
                .tracking(1.2)
                .foregroundStyle(Theme.textMuted)
            Spacer()
            trailing
        }
        .padding(.horizontal, 4)
    }
}
