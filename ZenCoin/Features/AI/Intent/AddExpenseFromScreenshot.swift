import AppIntents
import CryptoKit
import SwiftData
import UIKit

/// 由 iOS 快捷指令调用 —— 接收一张截图（如「截取屏幕」动作的输出），
/// 静默调 AI 识别 → 直接写入 SwiftData → 系统横幅提示「记账成功」。
///
/// `openAppWhenRun = false`：全程在后台跑，app 不进前台。
struct AddExpenseFromScreenshot: AppIntent {
    static var title: LocalizedStringResource = "AI 截图记账"
    static var description: IntentDescription = IntentDescription(
        "从截图识别支付信息并自动记账",
        categoryName: "记账"
    )
    static var openAppWhenRun: Bool = false

    @Parameter(
        title: "截图",
        description: "要识别的支付截图",
        inputConnectionBehavior: .connectToPreviousIntentResult
    )
    var screenshot: IntentFile

    static var parameterSummary: some ParameterSummary {
        Summary("识别 \(\.$screenshot) 并记账")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let imageData = screenshot.data
        guard let image = UIImage(data: imageData) else {
            return .result(dialog: "无法读取截图")
        }

        if isDuplicateScreenshot(imageData) {
            return .result(dialog: "已跳过：与上次截图相同")
        }

        let drafts: [AIExpenseDraft]
        do {
            drafts = try await ExpenseAIService.shared.recognize(image: image)
        } catch {
            return .result(dialog: "识别失败：\(error.localizedDescription)")
        }

        guard !drafts.isEmpty else {
            return .result(dialog: "未识别到支付信息")
        }

        // 在 AppIntent 进程里独立打开同一个 SwiftData 容器写入。
        let container = try ModelContainer(for: Expense.self, Book.self)
        let context = ModelContext(container)

        // 与前台 BookStore 共用 UserDefaults key，落到用户当前选中的账本。
        let currentBookId: UUID = {
            if let s = UserDefaults.standard.string(forKey: "currentBookId"),
               let uuid = UUID(uuidString: s) {
                return uuid
            }
            return Book.defaultID
        }()

        var inserted: [AIExpenseDraft] = []
        var skipped = 0
        for draft in drafts {
            let paymentTime = draft.paymentTime ?? Date()
            if isDuplicateExpense(amount: draft.amount, paymentTime: paymentTime,
                                  bookId: currentBookId, context: context) {
                skipped += 1
                continue
            }
            let expense = Expense(
                amount: draft.amount,
                isIncome: draft.isIncome,
                category: draft.category,
                note: draft.note,
                paymentTime: paymentTime,
                bookId: currentBookId
            )
            context.insert(expense)
            inserted.append(draft)
        }

        guard !inserted.isEmpty else {
            return .result(dialog: "已跳过：账单已记录过")
        }
        try context.save()

        // 通知正在前台的 app 刷新（如果用户已经打开过 ledger）。
        NotificationCenter.default.post(name: .expenseStoreDidChange, object: nil)

        let summary: String
        if inserted.count == 1 {
            let d = inserted[0]
            let prefix = d.isIncome ? "+" : "-"
            let skipNote = skipped > 0 ? "（跳过重复 \(skipped) 笔）" : ""
            summary = "\(d.category.displayName) \(prefix)\(CurrencyFormatter.format(d.amount))\(skipNote)"
        } else {
            let skipNote = skipped > 0 ? "，跳过重复 \(skipped) 笔" : ""
            summary = "已记 \(inserted.count) 笔\(skipNote)"
        }
        return .result(dialog: "记账成功 · \(summary)")
    }

    // MARK: - Duplicate detection

    /// 同账本内金额相同且支付时间在同一分钟内的记录视为重复。
    private func isDuplicateExpense(amount: Double, paymentTime: Date,
                                    bookId: UUID, context: ModelContext) -> Bool {
        guard let minuteStart = Calendar.current.date(bySetting: .second, value: 0,
                                                      of: paymentTime) else { return false }
        let minuteEnd = minuteStart.addingTimeInterval(60)
        var descriptor = FetchDescriptor<Expense>(
            predicate: #Predicate<Expense> { e in
                e.amount == amount
                    && e.bookId == bookId
                    && e.paymentTime >= minuteStart
                    && e.paymentTime < minuteEnd
            }
        )
        descriptor.fetchLimit = 1
        return (try? context.fetch(descriptor))?.isEmpty == false
    }

    /// 10 分钟内相同截图视为重复，返回 true 则跳过本次记账。
    private func isDuplicateScreenshot(_ data: Data) -> Bool {
        let hash = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        let defaults = UserDefaults.standard
        let lastHash = defaults.string(forKey: "lastScreenshotHash")
        let lastTime = defaults.double(forKey: "lastScreenshotTime")
        let now = Date().timeIntervalSince1970
        let isDuplicate = hash == lastHash && now - lastTime < 600
        // 无论是否重复都更新，保证下一张新截图能正常记录
        if !isDuplicate {
            defaults.set(hash, forKey: "lastScreenshotHash")
            defaults.set(now, forKey: "lastScreenshotTime")
        }
        return isDuplicate
    }
}
