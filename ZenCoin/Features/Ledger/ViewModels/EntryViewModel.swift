import Foundation
import SwiftData
import SwiftUI

/// 录入表单的 ViewModel。`amountText` 是一个允许包含 + - × ÷ 的表达式字符串，
/// 显示在输入区，保存时通过 NSExpression 求值得到最终金额。
@MainActor
@Observable
final class EntryViewModel {
    var isIncome: Bool = false
    var amountText: String = "0"
    var category: ExpenseCategory = .dining
    var note: String = ""
    var paymentTime: Date = .now
    var bookId: UUID

    /// 参与该笔的颜色 idx 集合。0 永远是「自己」，必含。
    /// 1-7 是任意"另外的人"，靠固定颜色区分而无身份。
    var participantColors: Set<Int> = [0]

    private let service: ExpenseDataService

    init(modelContext: ModelContext, bookId: UUID = Book.defaultID) {
        self.service = ExpenseDataService(modelContext: modelContext)
        self.bookId = bookId
    }

    /// 切换某个 color idx 的勾选；自己（idx 0）不允许移除。
    func toggleParticipantColor(_ idx: Int) {
        guard idx != 0 else { return }
        if participantColors.contains(idx) {
            participantColors.remove(idx)
        } else {
            participantColors.insert(idx)
        }
    }

    // MARK: - Derived

    var amount: Double {
        Self.evaluate(amountText)
    }

    var canSave: Bool {
        amount > 0
    }

    var hasOperator: Bool {
        amountText.contains { Self.opChars.contains($0) }
    }

    var displayExpression: String {
        if amountText.isEmpty || amountText == "0" {
            return CurrencyFormatter.format(0)
        }
        if hasOperator {
            return amountText  // 表达式直接显示，不加货币符号（avoid clutter）
        }
        return "\(CurrencyFormatter.symbol.rawValue)\(amountText)"
    }

    // MARK: - Token input

    func appendToken(_ token: String) {
        if Self.opChars.contains(token.first ?? " ") {
            handleOperator(token)
            return
        }
        if token == "." {
            handleDot()
            return
        }
        handleDigit(token)
    }

    private func handleDigit(_ d: String) {
        if amountText == "0" {
            amountText = d
            return
        }
        // 当前操作数长度限制
        let cur = currentOperand()
        if let dot = cur.firstIndex(of: ".") {
            let decimals = cur.distance(from: dot, to: cur.endIndex) - 1
            if decimals >= 2 { return }
        }
        if cur.count >= 9 { return }
        amountText += d
    }

    private func handleDot() {
        let cur = currentOperand()
        if cur.contains(".") { return }
        if cur.isEmpty {
            amountText += "0."
        } else {
            amountText += "."
        }
    }

    private func handleOperator(_ op: String) {
        // 不允许以运算符开头
        if amountText.isEmpty || amountText == "0" { return }
        if let last = amountText.last, Self.opChars.contains(last) {
            // 替换末尾运算符
            amountText = String(amountText.dropLast()) + op
            return
        }
        // 末尾如果是 "."，删掉再加运算符（避免 12.+ 这种）
        if amountText.hasSuffix(".") {
            amountText.removeLast()
        }
        amountText += op
    }

    func backspace() {
        if amountText.count <= 1 {
            amountText = "0"
        } else {
            amountText.removeLast()
            if amountText.isEmpty { amountText = "0" }
        }
    }

    /// 取最末尾的操作数（最后一个运算符之后的部分）。
    private func currentOperand() -> String {
        var s = ""
        for ch in amountText.reversed() {
            if Self.opChars.contains(ch) { break }
            s = String(ch) + s
        }
        return s
    }

    // MARK: - Mode

    func switchMode(toIncome: Bool) {
        isIncome = toIncome
        category = toIncome ? .salary : .dining
    }

    // MARK: - Save

    @discardableResult
    func save() -> Bool {
        guard canSave else { return false }
        // 收入笔不带参与人（不分摊）；支出笔默认至少含 self (idx 0)
        let colors: [Int] = isIncome ? [0] : participantColors.sorted()
        let expense = Expense(
            amount: amount,
            isIncome: isIncome,
            category: category,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            paymentTime: paymentTime,
            bookId: bookId,
            participantColors: colors
        )
        do {
            try service.save(expense)
            return true
        } catch {
            return false
        }
    }

    // MARK: - Evaluation

    static let opChars: Set<Character> = ["+", "-", "×", "÷"]

    /// 把浮点数格式化回输入框可以使用的字符串（去掉无意义的尾零）。
    static func formatNumber(_ v: Double) -> String {
        if v == v.rounded() { return String(format: "%.0f", v) }
        return String(format: "%.2f", v)
    }

    /// 把表达式（可能含 × / ÷）规范化后用 NSExpression 求值。
    /// 容错：
    /// - 末尾残留运算符 → 丢弃
    /// - 末尾是 "." (e.g. "9+588850.") → 丢弃，避免 NSExpression 把 `.` 当成 keypath
    /// - ".5" 形态 → 补 0
    /// - "+." / "-." → 补 0
    /// 任何 NSExpression 解析失败用 try? 兜底返回 0，不让异常炸出。
    static func evaluate(_ expr: String) -> Double {
        var s = expr
            .replacingOccurrences(of: "×", with: "*")
            .replacingOccurrences(of: "÷", with: "/")
        // 1. 末尾运算符 / 末尾点 / 末尾 + 点 全部修剪
        while let last = s.last, "+-*/.".contains(last) {
            s.removeLast()
        }
        if s.isEmpty { return 0 }
        // 2. 首字符是 "." → 补 0
        if s.first == "." { s = "0" + s }
        // 3. 把 "+." 这种「运算符紧跟点」的不合法形态补成 "+0."
        for op in ["+", "-", "*", "/"] {
            s = s.replacingOccurrences(of: "\(op).", with: "\(op)0.")
        }
        // 4. NSExpression 在某些病态输入下会 NSException。用 try? + 类型转换兜底。
        guard let result = (try? evaluateUnsafe(s))?.doubleValue,
              result.isFinite else {
            return 0
        }
        return result
    }

    private static func evaluateUnsafe(_ s: String) throws -> NSNumber? {
        // NSExpression(format:) 可以抛 NSException — 在 Swift 里不可 try-catch。
        // 经过上面的规范化后，几乎不会触发，但留这一层包装作为接口隔离。
        let nse = NSExpression(format: s)
        return nse.expressionValue(with: nil, context: nil) as? NSNumber
    }
}
