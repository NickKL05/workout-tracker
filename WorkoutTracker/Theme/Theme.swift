import SwiftUI

enum Theme {
    // Pure black background for OLED-friendly look.
    static let background       = Color.black
    static let surface          = Color(white: 0.07)        // cards
    static let surfaceElevated  = Color(white: 0.11)        // elevated cards / sheets
    static let stroke           = Color(white: 0.18)
    static let strokeStrong     = Color(white: 0.28)

    static let textPrimary      = Color.white
    static let textSecondary    = Color(white: 0.65)
    static let textMuted        = Color(white: 0.42)

    // Accents kept to white / off-white for the monochrome aesthetic.
    static let accent           = Color.white
    static let accentOnAccent   = Color.black
    static let danger           = Color(white: 0.92)        // styled as outlined danger in components
    static let destructive      = Color(red: 0.91, green: 0.30, blue: 0.27)  // custom-popup delete actions

    // Corner radii
    static let radiusSm: CGFloat = 8
    static let radiusMd: CGFloat = 14
    static let radiusLg: CGFloat = 20
}

extension Font {
    static var displayLg: Font { .system(size: 34, weight: .bold, design: .rounded) }
    static var display:   Font { .system(size: 28, weight: .bold, design: .rounded) }
    static var titleLg:   Font { .system(size: 22, weight: .semibold, design: .rounded) }
    static var title:     Font { .system(size: 18, weight: .semibold, design: .rounded) }
    static var bodyMd:    Font { .system(size: 16, weight: .regular, design: .default) }
    static var bodyBold:  Font { .system(size: 16, weight: .semibold, design: .default) }
    static var caption:   Font { .system(size: 13, weight: .medium, design: .default) }
    static var monoLg:    Font { .system(size: 44, weight: .semibold, design: .monospaced) }
    static var mono:      Font { .system(size: 17, weight: .medium, design: .monospaced) }
}
