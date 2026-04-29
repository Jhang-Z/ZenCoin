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

    /// 清空当前账本下的所有记录。
    /// - 主账本 (defaultID)：清空**全部账本**的所有记录（因为主账本是全账本视图）。
    /// - 其他账本：仅清空该账本，不影响其他账本。
    func deleteAll(bookId: UUID) throws {
        let isMain = (bookId == Book.defaultID)
        let descriptor: FetchDescriptor<Expense>
        if isMain {
            descriptor = FetchDescriptor<Expense>()
        } else {
            descriptor = FetchDescriptor<Expense>(
                predicate: #Predicate { $0.bookId == bookId }
            )
        }
        let toDelete = try modelContext.fetch(descriptor)
        for e in toDelete { modelContext.delete(e) }
        try modelContext.save()
        NotificationCenter.default.post(name: .expenseStoreDidChange, object: nil)
    }

    /// 把一批 expense 转移到目标账本。
    func move(_ expenses: [Expense], toBookId target: UUID) throws {
        for e in expenses { e.bookId = target }
        try modelContext.save()
        NotificationCenter.default.post(name: .expenseStoreDidChange, object: nil)
    }

    /// 取已存在的 externalId 集合，导入查重用。
    func existingExternalIds() throws -> Set<String> {
        let descriptor = FetchDescriptor<Expense>(
            predicate: #Predicate { $0.externalId != nil }
        )
        let all = try modelContext.fetch(descriptor)
        return Set(all.compactMap { $0.externalId })
    }

    /// 批量插入（一次 save，触发一次 notification）。
    func insertMany(_ expenses: [Expense]) throws {
        for e in expenses { modelContext.insert(e) }
        try modelContext.save()
        NotificationCenter.default.post(name: .expenseStoreDidChange, object: nil)
    }

    /// 取所有 expense（导出用）。bookId 为 defaultID 时全账本，否则按账本过滤。
    func fetchAll(bookId: UUID) throws -> [Expense] {
        let isMain = (bookId == Book.defaultID)
        let descriptor: FetchDescriptor<Expense>
        if isMain {
            descriptor = FetchDescriptor<Expense>(
                sortBy: [SortDescriptor(\.paymentTime, order: .reverse)]
            )
        } else {
            descriptor = FetchDescriptor<Expense>(
                predicate: #Predicate { $0.bookId == bookId },
                sortBy: [SortDescriptor(\.paymentTime, order: .reverse)]
            )
        }
        return try modelContext.fetch(descriptor)
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
        let isMain = (bookId == Book.defaultID)
        let descriptor: FetchDescriptor<Expense>
        if isMain {
            // 主账本 = 全账本视图（看到所有账本的记录，不再单独筛 bookId）
            descriptor = FetchDescriptor<Expense>(
                predicate: #Predicate {
                    $0.paymentTime >= start && $0.paymentTime < end
                },
                sortBy: [SortDescriptor(\.paymentTime, order: .reverse)]
            )
        } else {
            descriptor = FetchDescriptor<Expense>(
                predicate: #Predicate {
                    $0.paymentTime >= start && $0.paymentTime < end && $0.bookId == bookId
                },
                sortBy: [SortDescriptor(\.paymentTime, order: .reverse)]
            )
        }
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
        let isMain = (bookId == Book.defaultID)
        let descriptor: FetchDescriptor<Expense>
        if isMain {
            // 主账本 = 全账本视图
            descriptor = FetchDescriptor<Expense>(
                predicate: #Predicate {
                    $0.paymentTime >= start && $0.paymentTime < end
                },
                sortBy: [SortDescriptor(\.paymentTime, order: .reverse)]
            )
        } else {
            descriptor = FetchDescriptor<Expense>(
                predicate: #Predicate {
                    $0.paymentTime >= start && $0.paymentTime < end && $0.bookId == bookId
                },
                sortBy: [SortDescriptor(\.paymentTime, order: .reverse)]
            )
        }
        return try modelContext.fetch(descriptor)
    }
}
