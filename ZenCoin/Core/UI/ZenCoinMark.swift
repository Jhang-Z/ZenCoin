import SwiftUI

/// 「闭环 + 内方」品牌标记的 SwiftUI 矢量重绘 —— 跟 `assets/app-icon.svg` 1:1 几何，
/// 但用 SwiftUI Shape 画，因此自动跟随当前 theme.accent 着色，不用导出多份 PNG。
///
/// SVG 原始几何（1024 grid）：
/// - 外圆 r=256 stroke=56 （outer diameter = 50% 画布；stroke ≈ 5.5%）
/// - 内方 96×96 stroke=20 （在外圆的几何中心）
/// 在 inline 用时去掉外部安全区，让 outer diameter = `size`，所有比例同步缩放。
struct ZenCoinMark: View {
    @Environment(\.theme) private var theme

    let size: CGFloat
    var color: Color? = nil

    init(size: CGFloat = 28, color: Color? = nil) {
        self.size = size
        self.color = color
    }

    var body: some View {
        // 用 outerD = size 作为基准，所有 stroke / 内方都按 SVG 比例缩放。
        let outerD = size
        let outerStroke = outerD * 56 / 512   // SVG: outer diameter 512, stroke 56
        let innerSide   = outerD * 96 / 512   // SVG: inner square side 96
        let innerStroke = outerD * 20 / 512   // SVG: inner stroke 20

        let tint = color ?? theme.accent

        ZStack {
            // strokeBorder 把笔画完全画在 shape 内部，避免裁切
            Circle()
                .strokeBorder(tint, lineWidth: outerStroke)
            Rectangle()
                .strokeBorder(tint, lineWidth: innerStroke)
                .frame(width: innerSide, height: innerSide)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
