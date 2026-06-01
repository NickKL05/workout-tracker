import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold, design: .default))
            .foregroundStyle(Theme.accentOnAccent)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Theme.accent.opacity(configuration.isPressed ? 0.82 : 1.0))
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous))
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold, design: .default))
            .foregroundStyle(Theme.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Theme.surface.opacity(configuration.isPressed ? 0.6 : 1.0))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous)
                    .stroke(Theme.strokeStrong, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous))
    }
}

struct GhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.bodyBold)
            .foregroundStyle(Theme.textSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Theme.surface.opacity(configuration.isPressed ? 0.6 : 1.0))
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSm, style: .continuous))
    }
}

extension View {
    func primaryButton() -> some View { buttonStyle(PrimaryButtonStyle()) }
    func secondaryButton() -> some View { buttonStyle(SecondaryButtonStyle()) }
    func ghostButton() -> some View { buttonStyle(GhostButtonStyle()) }
}
