import Foundation

/// 把 ZenCoin 的 Expense 列表导出为自家 CSV。
///
/// Schema（行序按 paymentTime 倒序）：
/// `paymentTime,isIncome,amount,category,note,bookId,externalId`
/// - paymentTime: ISO 8601 (`yyyy-MM-dd HH:mm:ss`)
/// - isIncome:    `1 / 0`
/// - amount:      `12.50`
/// - category:    raw value（`dining` / `salary` …）
/// - note:        原文
/// - bookId:      UUID
/// - externalId:  可空
enum ExpenseExporter {

    static let header: [String] = [
        "paymentTime", "isIncome", "amount", "category", "note", "bookId", "externalId"
    ]

    static func export(_ expenses: [Expense]) -> Data {
        var rows: [[String]] = [header]
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        f.timeZone = .current
        for e in expenses {
            rows.append([
                f.string(from: e.paymentTime),
                e.isIncome ? "1" : "0",
                String(format: "%.2f", e.amount),
                e.category.rawValue,
                e.note,
                e.bookId.uuidString,
                e.externalId ?? "",
            ])
        }
        return CSVUtilities.encode(rows: rows)
    }

    /// 给导出文件起一个含日期 + 账本名的合理文件名。
    static func suggestedFilename(bookName: String) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyyMMdd"
        let safeBook = bookName.replacingOccurrences(of: "/", with: "-")
        return "ZenCoin-\(safeBook)-\(f.string(from: .now)).csv"
    }
}
