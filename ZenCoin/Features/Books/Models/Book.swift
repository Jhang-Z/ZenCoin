import Foundation
import SwiftData

/// 一个账本 = 一个独立场景的记账空间。例如「主账本」「旅行 · 京都」「装修 2026」。
/// 主账本 (`defaultID`) 永远存在、不可删除、不可重命名。
@Model
final class Book {
    /// 写死的主账本 UUID。所有从 v1 升级上来的旧 Expense 都会被自动归到这个 id 下。
    static let defaultID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    static let defaultName = "主账本"

    var id: UUID = Book.defaultID
    var name: String = Book.defaultName
    var sortOrder: Int = 0
    var createdAt: Date = Date()

    init(id: UUID = UUID(), name: String, sortOrder: Int = 0) {
        self.id = id
        self.name = name
        self.sortOrder = sortOrder
        self.createdAt = Date()
    }

    var isDefault: Bool { id == Book.defaultID }
}
