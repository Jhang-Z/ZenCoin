import SwiftUI

/// Theme-aware type ramp. Brand fonts (Anthropic Serif, CursorGothic, Degular Display)
/// are not redistributable, so we approximate per theme via system designs and tracking.
struct Type {
    let theme: ThemeTokens

    /// Hero numbers, page titles. Tight line height.
    var display: Font {
        Font.system(size: 44, weight: .medium, design: theme.fontDesign)
    }

    /// Section title (e.g. month label).
    var title: Font {
        Font.system(size: 22, weight: .medium, design: theme.fontDesign)
    }

    /// Card / row titles, list headers, amount numerals.
    /// 用 `.medium` (500) 而不是 `.semibold` (600) — 对齐 Anthropic / Cursor / Zapier / ElevenLabs 各家
    /// 实际 marketing 页的 weight，更"editorial 不强势"，跟 serif 也更搭。
    var heading: Font {
        Font.system(size: 17, weight: .medium, design: theme.fontDesign)
    }

    /// Body, button labels.
    var body: Font {
        Font.system(size: 15, weight: .regular, design: .default)
    }

    /// Secondary text, captions.
    var caption: Font {
        Font.system(size: 13, weight: .regular, design: .default)
    }

    /// Smallest labels, day headers.
    var micro: Font {
        Font.system(size: 11, weight: .medium, design: .default)
    }
}

extension ThemeTokens {
    var type: Type { Type(theme: self) }
}
