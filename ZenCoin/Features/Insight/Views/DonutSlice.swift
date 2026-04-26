import SwiftUI

/// 一个 donut 切片的 Shape。两段同心弧 + 闭合 = 一个 ring slice。
struct DonutSlice: Shape {
    let startAngle: Angle
    let endAngle: Angle
    let innerR: CGFloat
    let outerR: CGFloat

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        var p = Path()
        // 外弧（顺时针）
        p.addArc(
            center: center,
            radius: outerR,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        // 连到内弧末端
        let innerEnd = CGPoint(
            x: center.x + cos(endAngle.radians) * innerR,
            y: center.y + sin(endAngle.radians) * innerR
        )
        p.addLine(to: innerEnd)
        // 内弧（反向，逆时针）
        p.addArc(
            center: center,
            radius: innerR,
            startAngle: endAngle,
            endAngle: startAngle,
            clockwise: true
        )
        p.closeSubpath()
        return p
    }
}
