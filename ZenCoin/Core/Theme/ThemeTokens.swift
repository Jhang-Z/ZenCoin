import SwiftUI

struct ThemeTokens {
    // Surfaces
    let bgPrimary: Color
    let bgSurface: Color
    let bgInput: Color

    // Text
    let textPrimary: Color
    let textSecondary: Color

    // Brand / state
    let accent: Color
    let accentMuted: Color
    let separator: Color
    let error: Color

    // Shape
    let radiusSmall: CGFloat
    let radiusMedium: CGFloat
    let radiusLarge: CGFloat

    // Type
    let fontDesign: Font.Design
    let displayTracking: CGFloat

    // Mode
    let isDark: Bool

    var colorScheme: ColorScheme { isDark ? .dark : .light }
}
