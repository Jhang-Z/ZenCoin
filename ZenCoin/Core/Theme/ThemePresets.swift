import SwiftUI

extension ThemeTokens {
    static func preset(for id: ThemeID) -> ThemeTokens {
        switch id {
        case .claude:     return .claude
        case .cursor:     return .cursor
        case .zapier:     return .zapier
        case .elevenlabs: return .elevenlabs
        }
    }

    // MARK: - Claude — Parchment · Terracotta · Serif
    static let claude = ThemeTokens(
        bgPrimary:     Color(hex: "F5F4ED"),
        bgSurface:     Color(hex: "FAF9F5"),
        bgInput:       Color(hex: "E8E6DC"),
        textPrimary:   Color(hex: "141413"),
        textSecondary: Color(hex: "5E5D59"),
        accent:        Color(hex: "C96442"),
        accentMuted:   Color(hex: "C96442", opacity: 0.15),
        separator:     Color(hex: "F0EEE6"),
        error:         Color(hex: "B53333"),
        radiusSmall: 8, radiusMedium: 12, radiusLarge: 24,
        fontDesign: .serif,
        displayTracking: 0,
        isDark: false
    )

    // MARK: - Cursor — Warm cream · Orange · Compressed gothic
    static let cursor = ThemeTokens(
        bgPrimary:     Color(hex: "F2F1ED"),
        bgSurface:     Color(hex: "E6E5E0"),
        bgInput:       Color(hex: "EBEAE5"),
        textPrimary:   Color(hex: "26251E"),
        textSecondary: Color(hex: "26251E", opacity: 0.55),
        accent:        Color(hex: "F54E00"),
        accentMuted:   Color(hex: "F54E00", opacity: 0.12),
        separator:     Color(hex: "26251E", opacity: 0.10),
        error:         Color(hex: "CF2D56"),
        radiusSmall: 8, radiusMedium: 8, radiusLarge: 999,
        fontDesign: .default,
        displayTracking: -1.5,
        isDark: false
    )

    // MARK: - ElevenLabs — Cinematic dark · Mint accent · Inter-like sans
    static let elevenlabs = ThemeTokens(
        bgPrimary:     Color(hex: "0A0A0A"),
        bgSurface:     Color(hex: "161616"),
        bgInput:       Color(hex: "1F1F1F"),
        textPrimary:   Color(hex: "F5F5F5"),
        textSecondary: Color(hex: "A0A0A0"),
        accent:        Color(hex: "10D9A0"),
        accentMuted:   Color(hex: "10D9A0", opacity: 0.18),
        separator:     Color(hex: "2A2A2A"),
        error:         Color(hex: "F87171"),
        radiusSmall: 8, radiusMedium: 12, radiusLarge: 20,
        fontDesign: .default,
        displayTracking: -0.5,
        isDark: true
    )

    // MARK: - Zapier — Cream · Vivid orange · Border-forward
    static let zapier = ThemeTokens(
        bgPrimary:     Color(hex: "FFFEFB"),
        bgSurface:     Color(hex: "FFFDF9"),
        bgInput:       Color(hex: "ECEAE3"),
        textPrimary:   Color(hex: "201515"),
        textSecondary: Color(hex: "36342E"),
        accent:        Color(hex: "FF4F00"),
        accentMuted:   Color(hex: "FF4F00", opacity: 0.10),
        separator:     Color(hex: "C5C0B1"),
        error:         Color(hex: "CF2D56"),
        radiusSmall: 4, radiusMedium: 8, radiusLarge: 20,
        fontDesign: .default,
        displayTracking: 0,
        isDark: false
    )
}
