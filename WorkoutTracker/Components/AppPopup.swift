import SwiftUI

/// A single tappable action inside a custom popup.
struct AppPopupAction: Identifiable {
    enum Style { case primary, destructive, cancel }

    let id = UUID()
    let title: String
    let style: Style
    let action: () -> Void

    init(_ title: String, style: Style = .primary, action: @escaping () -> Void = {}) {
        self.title = title
        self.style = style
        self.action = action
    }
}

/// Themed, in-app replacement for UIKit alerts and confirmation dialogs.
/// Rendered as a centered card over a dimmed backdrop so every interaction
/// in the app shares one custom look instead of the system sheets.
private struct AppPopupModifier: ViewModifier {
    @Binding var isPresented: Bool
    let title: String
    let message: String?
    let actions: [AppPopupAction]

    func body(content: Content) -> some View {
        content.overlay {
            ZStack {
                if isPresented {
                    Color.black.opacity(0.62)
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .onTapGesture { dismiss() }

                    card
                        .transition(.scale(scale: 0.92).combined(with: .opacity))
                }
            }
            .animation(.easeOut(duration: 0.2), value: isPresented)
        }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.titleLg)
                    .foregroundStyle(Theme.textPrimary)
                if let message, !message.isEmpty {
                    Text(message)
                        .font(.bodyMd)
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 10) {
                ForEach(actions) { action in
                    button(for: action)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: 360)
        .background(Theme.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusLg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusLg, style: .continuous)
                .stroke(Theme.stroke, lineWidth: 0.5)
        )
        .padding(.horizontal, 36)
        .shadow(color: .black.opacity(0.4), radius: 24, y: 10)
    }

    private func button(for action: AppPopupAction) -> some View {
        Button {
            // Close first so any follow-on navigation animates cleanly.
            isPresented = false
            action.action()
        } label: {
            Text(action.title)
                .font(.bodyBold)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .foregroundStyle(foreground(for: action.style))
                .background(background(for: action.style))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous)
                        .stroke(border(for: action.style), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func foreground(for style: AppPopupAction.Style) -> Color {
        switch style {
        case .primary:     return Theme.accentOnAccent
        case .destructive: return .white
        case .cancel:      return Theme.textPrimary
        }
    }

    private func background(for style: AppPopupAction.Style) -> Color {
        switch style {
        case .primary:     return Theme.accent
        case .destructive: return Theme.destructive
        case .cancel:      return Theme.surface
        }
    }

    private func border(for style: AppPopupAction.Style) -> Color {
        switch style {
        case .cancel:               return Theme.strokeStrong
        case .primary, .destructive: return .clear
        }
    }

    private func dismiss() {
        isPresented = false
    }
}

extension View {
    /// Generic custom popup with an arbitrary set of actions.
    func appPopup(
        isPresented: Binding<Bool>,
        title: String,
        message: String? = nil,
        actions: [AppPopupAction]
    ) -> some View {
        modifier(AppPopupModifier(isPresented: isPresented, title: title, message: message, actions: actions))
    }

    /// Confirmation popup: a confirm button plus Cancel. Replaces
    /// `.confirmationDialog` for destructive / commit-style choices.
    func appConfirm(
        isPresented: Binding<Bool>,
        title: String,
        message: String? = nil,
        confirmTitle: String,
        destructive: Bool = false,
        cancelTitle: String = "Cancel",
        onConfirm: @escaping () -> Void
    ) -> some View {
        appPopup(
            isPresented: isPresented,
            title: title,
            message: message,
            actions: [
                AppPopupAction(confirmTitle, style: destructive ? .destructive : .primary, action: onConfirm),
                AppPopupAction(cancelTitle, style: .cancel)
            ]
        )
    }

    /// Informational popup with a single dismiss button. Replaces `.alert`.
    func appInfo(
        isPresented: Binding<Bool>,
        title: String,
        message: String,
        buttonTitle: String = "Got it"
    ) -> some View {
        appPopup(
            isPresented: isPresented,
            title: title,
            message: message,
            actions: [AppPopupAction(buttonTitle, style: .primary)]
        )
    }
}
