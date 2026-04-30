import SwiftUI

/// 8 色固定调色板，用作 `Expense.participantColors` 的 idx → 颜色映射。
///
/// 设计原则：
/// - **位置即身份**：idx 0 永远是「你自己」（terracotta，与 Claude 主题 accent 系列同源）；
///   idx 1-7 是匿名"另外的人"。颜色不跟主题走，确保跨主题视觉一致。
/// - **低饱和度**：所有色都偏哑，避免在 row 上喧宾夺主，符合 DESIGN.md "声音很小"。
/// - **不引入 person 身份模型**：用户在大脑里映射"slate blue ≡ B、mustard ≡ C"。
enum ParticipantPalette {
    static let count = 8

    /// 自己永远是 idx 0。
    static let selfIndex = 0

    /// 行尾 dot strip 的圆点直径。
    static let dotSize: CGFloat = 6
    static let dotSpacing: CGFloat = 3

    /// 录入页 chip 的实心圆直径。
    static let chipSize: CGFloat = 22
    static let chipSpacing: CGFloat = 8

    static func color(for idx: Int) -> Color {
        let safe = max(0, min(idx, hexes.count - 1))
        return Color(hex: hexes[safe])
    }

    /// idx 是否合法（0..<count）。
    static func isValid(_ idx: Int) -> Bool {
        idx >= 0 && idx < count
    }

    /// 8 色 hex（与 spec 一致，跨主题不变）。
    static let hexes: [String] = [
        "#C96442", // 0 self  · terracotta
        "#5A8DAA", // 1       · slate blue
        "#E8B14F", // 2       · mustard
        "#79A06E", // 3       · sage
        "#B86F94", // 4       · mauve
        "#6F7BA8", // 5       · indigo
        "#C58D5A", // 6       · camel
        "#8C7B68", // 7       · taupe
    ]
}

/// 把 `#RRGGBB` 字符串解成 SwiftUI Color。颜色相关的小工具，避免在多处重复写。
private extension Color {
    init(hex: String) {
        var s = hex
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let v = UInt64(s, radix: 16) else {
            self = .gray
            return
        }
        let r = Double((v >> 16) & 0xFF) / 255
        let g = Double((v >> 8) & 0xFF) / 255
        let b = Double(v & 0xFF) / 255
        self = Color(red: r, green: g, blue: b)
    }
}
