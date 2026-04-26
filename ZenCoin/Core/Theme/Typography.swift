import SwiftUI

/// Theme-aware type ramp。完全对齐 `colors_and_type.css` 里的 token 定义：
/// 所有档位的 `font-family` 跟随 `var(--font-design)`，size + weight 走 spec。
///
/// **关于汉字字体**（仅 Claude / serif 主题）：iOS 的 `Font.system(design: .serif)` 对汉字
/// 会 fallback 到 PingFang SC（无衬线），这跟「衬线主题」的视觉诉求不符。所以 row 标题
/// （`heading`）显式用 `STSongti-SC-Regular`（系统宋体）。其它档位沿用 `Font.system`，
/// Latin 字符走 New York 衬线，汉字走 PingFang，混排可读且不重。
struct Type {
    let theme: ThemeTokens

    /// Hero numbers, page titles. (44 / 500)
    var display: Font {
        Font.system(size: 44, weight: .medium, design: theme.fontDesign)
    }

    /// Section title — month label, sheet caps. (22 / 500)
    var title: Font {
        Font.system(size: 22, weight: .medium, design: theme.fontDesign)
    }

    /// Card / row titles, list headers — **汉字主导文本**用。(17 / 500)
    /// Claude 主题下用宋体让汉字也呈衬线（iOS system serif 汉字 fallback 是 PingFang sans）。
    var heading: Font {
        if theme.fontDesign == .serif {
            return Font.custom("STSongti-SC-Regular", size: 17)
        }
        return Font.system(size: 17, weight: .medium, design: theme.fontDesign)
    }

    /// **数字 / 金额**专用 heading。(17 / 500)
    /// 关键差异：在 Claude 主题下走 system serif（New York 风格），跟 `display` hero
    /// 保持同一种衬线字风 —— 上下两处出现的金额视觉上是同一字体。
    /// 用宋体的 Latin 字形（中式衬线）跟 New York（西式衬线）混排会感觉「俩字体」，
    /// 这个 token 专为避开那个问题。
    var headingNumeric: Font {
        Font.system(size: 17, weight: .medium, design: theme.fontDesign)
    }

    /// Body, button labels. (15 / 400)
    var body: Font {
        Font.system(size: 15, weight: .regular, design: theme.fontDesign)
    }

    /// Secondary text, captions — row subtitle, helper text. (13 / 400)
    var caption: Font {
        Font.system(size: 13, weight: .regular, design: theme.fontDesign)
    }

    /// Smallest labels, day headers — `IN` / `OUT` / `LEDGER` 等结构 caps。(11 / 500)
    /// 只用在 Latin 全大写场景，Latin 部分会拿到 design font 的 caps glyph。
    var micro: Font {
        Font.system(size: 11, weight: .medium, design: theme.fontDesign)
    }
}

extension ThemeTokens {
    var type: Type { Type(theme: self) }
}
