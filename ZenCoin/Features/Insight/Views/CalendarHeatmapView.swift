import SwiftUI

/// Insight 页面的日历热图。
///
/// - 月模式：6 行 × 7 列日历方格，颜色深浅对应当天支出/最大支出。
/// - 年模式：4 行 × 3 列月份方格，颜色深浅对应当月支出/最大支出。
///
/// 颜色用 `accent` opacity 阶梯（0 → 0.95），保持 zen 单色调。
struct CalendarHeatmapView: View {
    @Environment(\.theme) private var theme

    enum Mode {
        case month(days: [Date?], dayTotals: [Date: Double])
        case year(year: Int, monthTotals: [Int: Double])
    }

    let mode: Mode

    var body: some View {
        switch mode {
        case .month(let days, let totals):
            monthGrid(days: days, totals: totals)
        case .year(let year, let totals):
            yearGrid(year: year, totals: totals)
        }
    }

    // MARK: - Month grid

    private func monthGrid(days: [Date?], totals: [Date: Double]) -> some View {
        let max = totals.values.max() ?? 0
        return VStack(spacing: 6) {
            // 周首字母行 — 中文字符不加 letter-spacing（DESIGN.md §3 规则）
            HStack(spacing: 0) {
                ForEach(["一", "二", "三", "四", "五", "六", "日"], id: \.self) { d in
                    Text(d)
                        .font(theme.type.micro)
                        .foregroundStyle(theme.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }
            // 方格
            let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(Array(days.enumerated()), id: \.offset) { _, date in
                    monthCell(date: date, total: date.flatMap { totals[$0] } ?? 0, maxTotal: max)
                }
            }
        }
    }

    private func monthCell(date: Date?, total: Double, maxTotal: Double) -> some View {
        let day = date.map { Calendar.current.component(.day, from: $0) }
        let intensity: Double = (maxTotal > 0 && total > 0) ? (0.18 + (total / maxTotal) * 0.72) : 0
        return ZStack {
            RoundedRectangle(cornerRadius: theme.radiusSmall)
                .fill(intensity > 0 ? theme.accent.opacity(intensity) : theme.bgInput.opacity(0.4))
            VStack(spacing: 1) {
                if let day {
                    Text("\(day)")
                        .font(.system(size: 11, weight: .medium, design: theme.fontDesign))
                        .foregroundStyle(intensity > 0.55 ? theme.bgPrimary : theme.textPrimary)
                }
                if total > 0 {
                    Text(shortAmount(total))
                        .font(.system(size: 8, weight: .medium, design: .default))
                        .foregroundStyle(intensity > 0.55 ? theme.bgPrimary.opacity(0.85) : theme.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
            }
            .padding(.horizontal, 2)
        }
        .aspectRatio(1, contentMode: .fit)
        .opacity(date == nil ? 0 : 1)
    }

    // MARK: - Year grid

    private func yearGrid(year: Int, totals: [Int: Double]) -> some View {
        let max = totals.values.max() ?? 0
        let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(1...12, id: \.self) { m in
                yearCell(month: m, total: totals[m] ?? 0, maxTotal: max)
            }
        }
    }

    private func yearCell(month: Int, total: Double, maxTotal: Double) -> some View {
        let intensity: Double = (maxTotal > 0 && total > 0) ? (0.18 + (total / maxTotal) * 0.72) : 0
        return ZStack {
            RoundedRectangle(cornerRadius: theme.radiusSmall)
                .fill(intensity > 0 ? theme.accent.opacity(intensity) : theme.bgInput.opacity(0.4))
            VStack(spacing: 4) {
                Text("\(month) 月")
                    .font(.system(size: 13, weight: .medium, design: theme.fontDesign))
                    .foregroundStyle(intensity > 0.55 ? theme.bgPrimary : theme.textPrimary)
                Text(total > 0 ? shortAmount(total) : "—")
                    .font(.system(size: 11, weight: .regular, design: .default))
                    .foregroundStyle(intensity > 0.55 ? theme.bgPrimary.opacity(0.85) : theme.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(8)
        }
        .frame(height: 60)
    }

    // MARK: - Format

    private func shortAmount(_ v: Double) -> String {
        if v >= 10000 { return String(format: "%.1fw", v / 10000) }
        if v >= 1000  { return String(format: "%.1fk", v / 1000) }
        return String(Int(v.rounded()))
    }
}
