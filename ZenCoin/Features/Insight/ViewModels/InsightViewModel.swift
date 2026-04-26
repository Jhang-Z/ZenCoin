import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class InsightViewModel {
    enum Scope: String, CaseIterable, Identifiable {
        case month, year
        var id: String { rawValue }
        var caps: String {
            switch self {
            case .month: return "MONTH"
            case .year:  return "YEAR"
            }
        }
    }

    var scope: Scope = .month {
        didSet { reload() }
    }
    var year: Int
    var month: Int
    var bookId: UUID

    /// 当前 scope 下的全部支出明细（不含收入）。
    private(set) var expenses: [Expense] = []

    private let service: ExpenseDataService

    init(modelContext: ModelContext, bookId: UUID = Book.defaultID, date: Date = .now) {
        self.service = ExpenseDataService(modelContext: modelContext)
        let comps = Calendar.current.dateComponents([.year, .month], from: date)
        self.year = comps.year ?? 2026
        self.month = comps.month ?? 1
        self.bookId = bookId
    }

    func setBook(_ id: UUID) {
        guard bookId != id else { return }
        bookId = id
        reload()
    }

    var rangeLabel: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        switch scope {
        case .month:
            var c = DateComponents(); c.year = year; c.month = month; c.day = 1
            f.dateFormat = "yyyy 年 M 月"
            return f.string(from: Calendar.current.date(from: c) ?? .now)
        case .year:
            return "\(year) 年"
        }
    }

    var totalExpense: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }

    /// 按分类聚合后按金额降序。
    var categoryBreakdown: [Slice] {
        guard totalExpense > 0 else { return [] }
        let grouped = Dictionary(grouping: expenses, by: { $0.category })
        return grouped.map { (cat, items) in
            let amt = items.reduce(0) { $0 + $1.amount }
            return Slice(
                category: cat,
                amount: amt,
                share: amt / totalExpense
            )
        }
        .sorted { $0.amount > $1.amount }
    }

    // MARK: - Calendar 数据

    /// 月模式下：日历每天的支出总额（key 是该天的 startOfDay）。
    var dayTotals: [Date: Double] {
        let cal = Calendar.current
        let groups = Dictionary(grouping: expenses) { cal.startOfDay(for: $0.paymentTime) }
        return groups.mapValues { $0.reduce(0) { $0 + $1.amount } }
    }

    /// 年模式下：12 个月每月的支出总额（key 是 1...12）。
    var monthTotals: [Int: Double] {
        let cal = Calendar.current
        let groups = Dictionary(grouping: expenses) { cal.component(.month, from: $0.paymentTime) }
        return groups.mapValues { $0.reduce(0) { $0 + $1.amount } }
    }

    /// 月模式下当月所有日期（含留白对齐）。
    var monthCalendarDays: [Date?] {
        let cal = Calendar.current
        var c = DateComponents(); c.year = year; c.month = month; c.day = 1
        guard let first = cal.date(from: c),
              let range = cal.range(of: .day, in: .month, for: first) else { return [] }
        // 起始留白：让一周的第一格对齐周日（中国习惯：周一开头也行；这里用周一开头）
        let weekday = cal.component(.weekday, from: first)  // 1=Sun … 7=Sat
        // 转成周一为 0 的 leading
        let leading = (weekday + 5) % 7
        var cells: [Date?] = Array(repeating: nil, count: leading)
        for d in range {
            var cc = DateComponents(); cc.year = year; cc.month = month; cc.day = d
            cells.append(cal.date(from: cc))
        }
        // 末尾补到 7 的倍数
        let trailing = (7 - cells.count % 7) % 7
        cells.append(contentsOf: Array(repeating: nil, count: trailing))
        return cells
    }

    /// Donut 用：top 5 + 其他聚合（如果超过 5 类）。
    var donutSlices: [Slice] {
        let all = categoryBreakdown
        if all.count <= 5 { return all }
        let head = Array(all.prefix(5))
        let tailAmount = all.dropFirst(5).reduce(0) { $0 + $1.amount }
        let tailShare = tailAmount / totalExpense
        return head + [Slice(category: .other, amount: tailAmount, share: tailShare, isOtherBucket: true)]
    }

    func reload() {
        do {
            let raw: [Expense]
            switch scope {
            case .month: raw = try service.fetchMonth(year: year, month: month, bookId: bookId)
            case .year:  raw = try service.fetchYear(year: year, bookId: bookId)
            }
            expenses = raw.filter { !$0.isIncome }
        } catch {
            expenses = []
        }
    }

    func step(_ delta: Int) {
        switch scope {
        case .month:
            var c = DateComponents(); c.year = year; c.month = month; c.day = 1
            guard let cur = Calendar.current.date(from: c),
                  let next = Calendar.current.date(byAdding: .month, value: delta, to: cur) else { return }
            let nc = Calendar.current.dateComponents([.year, .month], from: next)
            year = nc.year ?? year
            month = nc.month ?? month
        case .year:
            year += delta
        }
        reload()
    }

    func setMonth(year: Int, month: Int) {
        self.year = year
        self.month = month
        reload()
    }

    func setYear(_ year: Int) {
        self.year = year
        reload()
    }

    struct Slice: Identifiable {
        let category: ExpenseCategory
        let amount: Double
        let share: Double
        var isOtherBucket: Bool = false
        var id: String { isOtherBucket ? "_other_bucket" : category.rawValue }

        var label: String {
            isOtherBucket ? "其他" : category.displayName
        }
    }
}
