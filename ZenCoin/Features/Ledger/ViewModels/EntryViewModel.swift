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

    private let service: ExpenseDataService

    init(modelContext: ModelContext, bookId: UUID = Book.defaultID) {
        self.service = ExpenseDataService(modelContext: modelContext)
        self.bookId = bookId
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
        let expense = Expense(
            amount: amount,
            isIncome: isIncome,
            category: category,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            paymentTime: paymentTime,
            bookId: bookId
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
    /// 容错：末尾若残留运算符则丢弃；解析失败返回 0。
    static func evaluate(_ expr: String) -> Double {
        var s = expr
            .replacingOccurrences(of: "×", with: "*")
            .replacingOccurrences(of: "÷", with: "/")
        while let last = s.last, "+-*/".contains(last) {
            s.removeLast()
        }
        if s.isEmpty { return 0 }
        // NSExpression 不接受 ".5" 这种（首位是 .），补 0
        if s.first == "." { s = "0" + s }
        // 同时把 "+." / "-." 等不合法形态补 0
        for op in ["+", "-", "*", "/"] {
            s = s.replacingOccurrences(of: "\(op).", with: "\(op)0.")
        }
        let nse = NSExpression(format: s)
        if let n = nse.expressionValue(with: nil, context: nil) as? NSNumber {
            let v = n.doubleValue
            return v.isFinite ? v : 0
        }
        return 0
    }
}
