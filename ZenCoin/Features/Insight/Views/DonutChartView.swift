import SwiftUI

/// 自绘 donut。每个切片都标注在环外，引线带 90° 折弯避免标签重叠。
/// - 切片：theme.accent opacity 阶梯（1.0 → 0.28），最大切片最饱满
/// - 标签：左侧切片右对齐到左侧栏，右侧切片左对齐到右侧栏
/// - 引线：1pt accent，从外圈 attach 点 → 同一 Y 的折弯点 → 标签前 stub
/// - 中心：当前区间总额 + 笔数
struct DonutChartView: View {
    @Environment(\.theme) private var theme

    let slices: [InsightViewModel.Slice]
    let centerTitle: String
    let centerSubtitle: String

    /// 内圈半径占外圈的比例。
    private let innerRatio: CGFloat = 0.62
    /// 切片之间的角度间隔（度）。
    private let gapDegrees: Double = 1.2
    /// 每条标签预留的最小垂直间隔（pt）。
    private let labelSlotHeight: CGFloat = 30
    /// 切片透明度阶梯。
    private static let opacityRamp: [Double] = [1.0, 0.85, 0.7, 0.55, 0.4, 0.28]
    /// 引线 stub（标签之前最后一段水平线）的长度。
    private let stubLength: CGFloat = 6
    /// 左右两侧标签栏宽度。"餐饮 38%" 4-7 中英字节，64pt 足够。
    private let labelColumnWidth: CGFloat = 64

    var body: some View {
        GeometryReader { geo in
            // 留给两侧 label 栏 + 引线弯折 + 边距的横向空间，以及上下 label 溢出空间。
            let horizontalReserve: CGFloat = (labelColumnWidth + 18 + 6) * 2
            let verticalReserve: CGFloat = 24
            let outerR = max(40, min(
                (geo.size.width - horizontalReserve) / 2,
                (geo.size.height - verticalReserve) / 2
            ))
            let innerR = outerR * innerRatio
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let leftLabelX = center.x - outerR - 18
            let rightLabelX = center.x + outerR + 18
            let leftBendX = center.x - outerR - 12
            let rightBendX = center.x + outerR + 12

            // 1. 计算每个切片的 attach 点 + mid 角度
            let attachments: [Attachment] = slices.indices.map { idx in
                let arc = arcAngles(for: idx)
                let mid = midAngle(start: arc.start, end: arc.end)
                return Attachment(
                    idx: idx,
                    mid: mid,
                    attach: CGPoint(
                        x: center.x + cos(mid.radians) * outerR,
                        y: center.y + sin(mid.radians) * outerR
                    )
                )
            }

            // 2. 按左右半圆分组（cos<0 在左半，cos≥0 在右半），各自按 attach.y 排序
            let leftSide = attachments
                .filter { cos($0.mid.radians) < 0 }
                .sorted { $0.attach.y < $1.attach.y }
            let rightSide = attachments
                .filter { cos($0.mid.radians) >= 0 }
                .sorted { $0.attach.y < $1.attach.y }

            // 3. 在每一侧做 Y 方向的非重叠分布
            let leftYs = distributeYs(
                originalYs: leftSide.map { $0.attach.y },
                minSpacing: labelSlotHeight,
                frameHeight: geo.size.height
            )
            let rightYs = distributeYs(
                originalYs: rightSide.map { $0.attach.y },
                minSpacing: labelSlotHeight,
                frameHeight: geo.size.height
            )

            ZStack {
                // 切片
                ForEach(Array(slices.enumerated()), id: \.element.id) { idx, _ in
                    let arc = arcAngles(for: idx)
                    DonutSlice(
                        startAngle: arc.start,
                        endAngle: arc.end,
                        innerR: innerR,
                        outerR: outerR
                    )
                    .fill(sliceColor(for: idx))
                }

                // 左侧引线 + 标签
                ForEach(Array(leftSide.enumerated()), id: \.element.idx) { i, att in
                    let labelY = leftYs[i]
                    leaderPath(
                        from: att.attach,
                        bendX: leftBendX,
                        labelEndX: leftLabelX + stubLength,
                        labelY: labelY
                    )
                    .stroke(theme.accent.opacity(0.6), lineWidth: 1)

                    label(slice: slices[att.idx])
                        .frame(width: labelColumnWidth, alignment: .trailing)
                        .position(x: leftLabelX - labelColumnWidth / 2, y: labelY)
                }

                // 右侧引线 + 标签
                ForEach(Array(rightSide.enumerated()), id: \.element.idx) { i, att in
                    let labelY = rightYs[i]
                    leaderPath(
                        from: att.attach,
                        bendX: rightBendX,
                        labelEndX: rightLabelX - stubLength,
                        labelY: labelY
                    )
                    .stroke(theme.accent.opacity(0.6), lineWidth: 1)

                    label(slice: slices[att.idx])
                        .frame(width: labelColumnWidth, alignment: .leading)
                        .position(x: rightLabelX + labelColumnWidth / 2, y: labelY)
                }

                // 中心信息
                VStack(spacing: 4) {
                    Text(centerTitle)
                        .font(.system(size: 24, weight: .medium, design: theme.fontDesign))
                        .tracking(theme.displayTracking)
                        .foregroundStyle(theme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    Text(centerSubtitle)
                        .font(theme.type.caption)
                        .foregroundStyle(theme.textSecondary)
                }
                .frame(width: innerR * 1.55)
                .position(center)
            }
        }
    }

    // MARK: - Pieces

    private func label(slice: InsightViewModel.Slice) -> some View {
        HStack(spacing: 4) {
            Text(slice.label)
                .font(.system(size: 11, weight: .medium, design: theme.fontDesign))
                .foregroundStyle(theme.textPrimary)
                .lineLimit(1)
            Text("\(Int((slice.share * 100).rounded()))%")
                .font(.system(size: 10, weight: .semibold, design: theme.fontDesign))
                .foregroundStyle(theme.textSecondary)
                .monospacedDigit()
        }
    }

    private func leaderPath(from attach: CGPoint, bendX: CGFloat, labelEndX: CGFloat, labelY: CGFloat) -> Path {
        Path { p in
            p.move(to: attach)
            p.addLine(to: CGPoint(x: bendX, y: labelY))
            p.addLine(to: CGPoint(x: labelEndX, y: labelY))
        }
    }

    // MARK: - Geometry

    private func arcAngles(for idx: Int) -> (start: Angle, end: Angle) {
        var startFrac = 0.0
        for i in 0..<idx { startFrac += slices[i].share }
        let endFrac = startFrac + slices[idx].share
        var startDeg = -90.0 + startFrac * 360.0
        var endDeg = -90.0 + endFrac * 360.0
        if slices.count > 1 {
            startDeg += gapDegrees / 2
            endDeg -= gapDegrees / 2
        }
        return (.degrees(startDeg), .degrees(endDeg))
    }

    private func midAngle(start: Angle, end: Angle) -> Angle {
        .degrees((start.degrees + end.degrees) / 2)
    }

    private func sliceColor(for idx: Int) -> Color {
        let i = min(idx, Self.opacityRamp.count - 1)
        return theme.accent.opacity(Self.opacityRamp[i])
    }

    /// 简单的非重叠分布：从上到下保证相邻间隔，必要时整体上移避免溢出底部，
    /// 然后再从下到上调整避免溢出顶部。≤6 个标签时收敛得很好。
    private func distributeYs(originalYs: [CGFloat], minSpacing: CGFloat, frameHeight: CGFloat) -> [CGFloat] {
        guard !originalYs.isEmpty else { return [] }
        var ys = originalYs

        // 上 → 下 sweep：保证相邻间隔
        for i in 1..<ys.count {
            let needed = ys[i - 1] + minSpacing
            if ys[i] < needed { ys[i] = needed }
        }

        // 底部溢出 → 整体上移
        let maxAllowed = frameHeight - minSpacing / 2
        if let last = ys.last, last > maxAllowed {
            let overflow = last - maxAllowed
            ys = ys.map { $0 - overflow }
        }

        // 下 → 上 sweep：保证不顶顶部
        for i in (0..<ys.count - 1).reversed() {
            let maxY = ys[i + 1] - minSpacing
            if ys[i] > maxY { ys[i] = maxY }
        }

        // 顶部溢出 → 整体下移（极端窄高比下兜底）
        let minAllowed = minSpacing / 2
        if let first = ys.first, first < minAllowed {
            let underflow = minAllowed - first
            ys = ys.map { $0 + underflow }
        }

        return ys
    }

    private struct Attachment {
        let idx: Int
        let mid: Angle
        let attach: CGPoint
    }
}
