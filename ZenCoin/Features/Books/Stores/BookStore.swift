import Foundation
import SwiftData
import SwiftUI

/// 全局账本状态。
/// - 维护当前选中账本（持久化在 UserDefaults）
/// - 维护账本列表（来自 SwiftData）
/// - 应用启动时确保「主账本」必定存在
@MainActor
@Observable
final class BookStore {
    private static let persistKey = "currentBookId"

    private(set) var books: [Book] = []
    var currentBookId: UUID = Book.defaultID {
        didSet {
            guard oldValue != currentBookId else { return }
            UserDefaults.standard.set(currentBookId.uuidString, forKey: Self.persistKey)
            NotificationCenter.default.post(name: .currentBookDidChange, object: nil)
        }
    }

    let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        if let s = UserDefaults.standard.string(forKey: Self.persistKey),
           let uuid = UUID(uuidString: s) {
            // 不走 didSet（避免初始化阶段就 post 通知）
            self.currentBookId = uuid
        }
        ensureDefaultBook()
        reload()
        // 校正：如果持久化的 currentBookId 已不存在，回落到默认。
        if !books.contains(where: { $0.id == currentBookId }) {
            UserDefaults.standard.set(Book.defaultID.uuidString, forKey: Self.persistKey)
            self.currentBookId = Book.defaultID
        }
    }

    var currentBook: Book? {
        books.first { $0.id == currentBookId }
    }

    var isOnDefaultBook: Bool {
        currentBookId == Book.defaultID
    }

    func reload() {
        let descriptor = FetchDescriptor<Book>(
            sortBy: [SortDescriptor(\.sortOrder), SortDescriptor(\.createdAt)]
        )
        books = (try? modelContext.fetch(descriptor)) ?? []
    }

    private func ensureDefaultBook() {
        let defaultID = Book.defaultID  // SwiftData #Predicate 不允许访问静态成员，需先 capture
        let descriptor = FetchDescriptor<Book>(
            predicate: #Predicate { $0.id == defaultID }
        )
        if (try? modelContext.fetch(descriptor).first) != nil { return }
        let b = Book(id: Book.defaultID, name: Book.defaultName, sortOrder: 0)
        modelContext.insert(b)
        try? modelContext.save()
    }

    @discardableResult
    func create(name: String) -> Book? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let nextOrder = (books.map { $0.sortOrder }.max() ?? 0) + 1
        let b = Book(name: trimmed, sortOrder: nextOrder)
        modelContext.insert(b)
        try? modelContext.save()
        reload()
        return b
    }

    func rename(_ book: Book, to name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !book.isDefault else { return }
        book.name = trimmed
        try? modelContext.save()
        reload()
    }

    /// 删除一个账本。`migrateExpensesToDefault = true` 会把这个账本下的所有
    /// 支出转移到主账本；为 false 则一并删除。
    func delete(_ book: Book, migrateExpensesToDefault: Bool) {
        guard !book.isDefault else { return }
        let bid = book.id
        let descriptor = FetchDescriptor<Expense>(
            predicate: #Predicate { $0.bookId == bid }
        )
        let related = (try? modelContext.fetch(descriptor)) ?? []
        if migrateExpensesToDefault {
            for e in related { e.bookId = Book.defaultID }
        } else {
            for e in related { modelContext.delete(e) }
        }
        modelContext.delete(book)
        try? modelContext.save()
        if currentBookId == bid {
            currentBookId = Book.defaultID  // triggers notification → views reload
        } else {
            NotificationCenter.default.post(name: .expenseStoreDidChange, object: nil)
        }
        reload()
    }
}

// MARK: - Environment

private struct BookStoreKey: EnvironmentKey {
    static let defaultValue: BookStore? = nil
}

extension EnvironmentValues {
    var bookStore: BookStore? {
        get { self[BookStoreKey.self] }
        set { self[BookStoreKey.self] = newValue }
    }
}
