import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class LedgerViewModel {
    var year: Int
    var month: Int
    var entries: [Expense] = []
    /// 当前过滤的账本 id。view 层用 BookStore 同步给它。
    var bookId: UUID

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

    var monthLabel: String {
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = 1
        let date = Calendar.current.date(from: comps) ?? .now
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "yyyy 年 M 月"
        return f.string(from: date)
    }

    var monthNet: Double {
        monthIncomeTotal - monthExpenseTotal
    }

    var monthExpenseTotal: Double {
        entries.filter { !$0.isIncome }.reduce(0) { $0 + $1.amount }
    }

    var monthIncomeTotal: Double {
        entries.filter { $0.isIncome }.reduce(0) { $0 + $1.amount }
    }

    var groupedByDay: [(date: Date, items: [Expense])] {
        let cal = Calendar.current
        let groups = Dictionary(grouping: entries) { entry in
            cal.startOfDay(for: entry.paymentTime)
        }
        return groups.keys.sorted(by: >).map { day in
            (date: day, items: groups[day]?.sorted(by: { $0.paymentTime > $1.paymentTime }) ?? [])
        }
    }

    func reload() {
        do {
            entries = try service.fetchMonth(year: year, month: month, bookId: bookId)
        } catch {
            entries = []
        }
    }

    func step(_ delta: Int) {
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = 1
        guard let current = Calendar.current.date(from: comps),
              let next = Calendar.current.date(byAdding: .month, value: delta, to: current) else {
            return
        }
        let nc = Calendar.current.dateComponents([.year, .month], from: next)
        year = nc.year ?? year
        month = nc.month ?? month
        reload()
    }

    func setMonth(year: Int, month: Int) {
        self.year = year
        self.month = month
        reload()
    }

    func delete(_ expense: Expense) {
        try? service.delete(expense)
        reload()
    }

    func deleteMany(ids: Set<UUID>) {
        let toDelete = entries.filter { ids.contains($0.id) }
        try? service.deleteMany(toDelete)
        reload()
    }

    /// 把选中的账单转移到目标账本。
    func moveMany(ids: Set<UUID>, toBookId target: UUID) {
        let toMove = entries.filter { ids.contains($0.id) }
        try? service.move(toMove, toBookId: target)
        reload()
    }

    func selectionTotals(ids: Set<UUID>) -> (expense: Double, income: Double) {
        let selected = entries.filter { ids.contains($0.id) }
        let exp = selected.filter { !$0.isIncome }.reduce(0) { $0 + $1.amount }
        let inc = selected.filter { $0.isIncome }.reduce(0) { $0 + $1.amount }
        return (exp, inc)
    }
}
