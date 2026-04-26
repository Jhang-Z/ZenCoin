import Foundation
import SwiftData

@Model
final class Expense {
    var id: UUID = UUID()
    var amount: Double = 0
    var isIncome: Bool = false
    var categoryRaw: String = ExpenseCategory.other.rawValue
    var note: String = ""
    var paymentTime: Date = Date()
    var createdAt: Date = Date()
    /// 所属账本。从 v1 升级上来的旧数据会自动落到 `Book.defaultID`（主账本）。
    var bookId: UUID = Book.defaultID

    var category: ExpenseCategory {
        get { ExpenseCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    init(
        amount: Double,
        isIncome: Bool,
        category: ExpenseCategory,
        note: String = "",
        paymentTime: Date = Date(),
        bookId: UUID = Book.defaultID
    ) {
        self.id = UUID()
        self.amount = amount
        self.isIncome = isIncome
        self.categoryRaw = category.rawValue
        self.note = note
        self.paymentTime = paymentTime
        self.createdAt = Date()
        self.bookId = bookId
    }
}
