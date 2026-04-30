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
    /// 外部数据源唯一 id（如微信/支付宝交易单号），用于导入幂等；手动录入留空。
    var externalId: String?
    /// 参与该笔的颜色 idx 列表（升序、去重）。
    /// idx 0 = 你自己；1-7 = 7 个匿名"另外的人"，跨账单同色 = 同一个人（用户自行心智映射）。
    /// 旧数据 / 导入 / 仅自己 → `[0]`。仅 1 个元素时行不显示 dot strip。
    var participantColors: [Int] = [0]

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
        bookId: UUID = Book.defaultID,
        externalId: String? = nil,
        participantColors: [Int] = [0]
    ) {
        self.id = UUID()
        self.amount = amount
        self.isIncome = isIncome
        self.categoryRaw = category.rawValue
        self.note = note
        self.paymentTime = paymentTime
        self.createdAt = Date()
        self.bookId = bookId
        self.externalId = externalId
        self.participantColors = participantColors
    }
}
