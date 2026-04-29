import SwiftUI

/// Insight 日历点击某段周期后弹出的明细 sheet。
///
/// - 头部沿用 DESIGN.md §6.4：左侧 micro caps + 周期标题；右侧不放按钮（系统下拉指示器即返回）。
/// - 行复用 `EntryRowView`（非选择态），以 1pt separator 分隔。
/// - 仅支出（与 InsightViewModel 的语义一致）。
struct BillsSheet: View {
    @Environment(\.theme) private var theme

    enum Period {
        case day(Date)
        case month(year: Int, month: Int)
    }

    let period: Period
    let entries: [Expense]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Rectangle()
                .fill(theme.separator)
                .frame(height: 1)
            if entries.isEmpty {
                emptyState
            } else {
                list
            }
        }
        .background(theme.bgPrimary.ignoresSafeArea())
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(microLabel)
                .font(theme.type.micro)
                .tracking(0.8)
                .foregroundStyle(theme.textSecondary)
            Text(periodLabel)
                .font(theme.type.title)
                .foregroundStyle(theme.textPrimary)
                .tracking(theme.displayTracking * 0.4)
            Text(totalLabel)
                .font(theme.type.micro)
                .tracking(0.6)
                .monospacedDigit()
                .foregroundStyle(theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 16)
    }

    // MARK: - List

    @ViewBuilder
    private var list: some View {
        switch period {
        case .day:
            flatList
        case .month:
            groupedList
        }
    }

    private var flatList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(Array(entries.enumerated()), id: \.element.id) { idx, entry in
                    EntryRowView(entry: entry)
                    if idx < entries.count - 1 {
                        Rectangle()
                            .fill(theme.separator)
                            .frame(height: 1)
                            .padding(.horizontal, 24)
                    }
                }
                Color.clear.frame(height: 24)
            }
        }
    }

    private var groupedList: some View {
        let cal = Calendar.current
        let groups = Dictionary(grouping: entries) { cal.startOfDay(for: $0.paymentTime) }
        let days = groups.keys.sorted(by: >)
        return ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(days, id: \.self) { day in
                    let items = groups[day] ?? []
                    dayHeader(day, items: items)
                    ForEach(Array(items.enumerated()), id: \.element.id) { idx, entry in
                        EntryRowView(entry: entry)
                        if idx < items.count - 1 {
                            Rectangle()
                                .fill(theme.separator)
                                .frame(height: 1)
                                .padding(.horizontal, 24)
                        }
                    }
                }
                Color.clear.frame(height: 24)
            }
        }
    }

    private func dayHeader(_ date: Date, items: [Expense]) -> some View {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "M 月 d 日 · EEEE"
        let total = items.reduce(0.0) { $0 + $1.amount }
        return HStack(spacing: 0) {
            Text(f.string(from: date))
                .font(theme.type.micro)
                .tracking(0.6)
                .foregroundStyle(theme.textSecondary)
            if total > 0 {
                Text(" · ")
                    .font(theme.type.micro)
                    .tracking(0.6)
                    .foregroundStyle(theme.textSecondary)
                Text(CurrencyFormatter.format(total))
                    .font(theme.type.micro)
                    .tracking(0.6)
                    .monospacedDigit()
                    .foregroundStyle(theme.textSecondary)
            }
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 8)
    }

    // MARK: - Empty

    private var emptyState: some View {
        VStack {
            Spacer()
            Text(emptyText)
                .font(theme.type.body)
                .foregroundStyle(theme.textSecondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Format

    private var microLabel: String {
        switch period {
        case .day:   return "DAILY / 当日"
        case .month: return "MONTHLY / 当月"
        }
    }

    private var periodLabel: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        switch period {
        case .day(let date):
            f.dateFormat = "M 月 d 日 · EEEE"
            return f.string(from: date)
        case .month(let y, let m):
            var c = DateComponents(); c.year = y; c.month = m; c.day = 1
            f.dateFormat = "yyyy 年 M 月"
            return f.string(from: Calendar.current.date(from: c) ?? .now)
        }
    }

    private var totalLabel: String {
        let total = entries.reduce(0.0) { $0 + $1.amount }
        return "\(entries.count) 笔 · \(CurrencyFormatter.format(total))"
    }

    private var emptyText: String {
        switch period {
        case .day:   return "当天没有支出"
        case .month: return "当月没有支出"
        }
    }
}
