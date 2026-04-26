import Foundation
import SwiftData

@MainActor
struct ExpenseDataService {
    let modelContext: ModelContext

    func save(_ expense: Expense) throws {
        modelContext.insert(expense)
        try modelContext.save()
        NotificationCenter.default.post(name: .expenseStoreDidChange, object: nil)
    }

    func update(_ expense: Expense) throws {
        try modelContext.save()
        NotificationCenter.default.post(name: .expenseStoreDidChange, object: nil)
    }

    func delete(_ expense: Expense) throws {
        modelContext.delete(expense)
        try modelContext.save()
        NotificationCenter.default.post(name: .expenseStoreDidChange, object: nil)
    }

    func deleteMany(_ expenses: [Expense]) throws {
        for e in expenses { modelContext.delete(e) }
        try modelContext.save()
        NotificationCenter.default.post(name: .expenseStoreDidChange, object: nil)
    }

    /// 清空当前账本下的所有记录（不影响其他账本）。
    func deleteAll(bookId: UUID) throws {
        let descriptor = FetchDescriptor<Expense>(
            predicate: #Predicate { $0.bookId == bookId }
        )
        let inBook = try modelContext.fetch(descriptor)
        for e in inBook { modelContext.delete(e) }
        try modelContext.save()
        NotificationCenter.default.post(name: .expenseStoreDidChange, object: nil)
    }

    func fetchYear(year: Int, bookId: UUID) throws -> [Expense] {
        let cal = Calendar.current
        var startComps = DateComponents()
        startComps.year = year
        startComps.month = 1
        startComps.day = 1
        guard let start = cal.date(from: startComps),
              let end = cal.date(byAdding: .year, value: 1, to: start) else {
            return []
        }
        let descriptor = FetchDescriptor<Expense>(
            predicate: #Predicate {
                $0.paymentTime >= start && $0.paymentTime < end && $0.bookId == bookId
            },
            sortBy: [SortDescriptor(\.paymentTime, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchMonth(year: Int, month: Int, bookId: UUID) throws -> [Expense] {
        let cal = Calendar.current
        var startComps = DateComponents()
        startComps.year = year
        startComps.month = month
        startComps.day = 1
        guard let start = cal.date(from: startComps),
              let end = cal.date(byAdding: .month, value: 1, to: start) else {
            return []
        }
        let descriptor = FetchDescriptor<Expense>(
            predicate: #Predicate {
                $0.paymentTime >= start && $0.paymentTime < end && $0.bookId == bookId
            },
            sortBy: [SortDescriptor(\.paymentTime, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
}
