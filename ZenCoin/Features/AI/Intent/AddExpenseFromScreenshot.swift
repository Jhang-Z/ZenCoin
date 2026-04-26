import AppIntents
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

        for draft in drafts {
            let expense = Expense(
                amount: draft.amount,
                isIncome: draft.isIncome,
                category: draft.category,
                note: draft.note,
                paymentTime: draft.paymentTime ?? Date(),
                bookId: currentBookId
            )
            context.insert(expense)
        }
        try context.save()

        // 通知正在前台的 app 刷新（如果用户已经打开过 ledger）。
        NotificationCenter.default.post(name: .expenseStoreDidChange, object: nil)

        let summary: String
        if drafts.count == 1 {
            let d = drafts[0]
            let prefix = d.isIncome ? "+" : "-"
            summary = "\(d.category.displayName) \(prefix)\(CurrencyFormatter.format(d.amount))"
        } else {
            summary = "已记 \(drafts.count) 笔"
        }
        return .result(dialog: "记账成功 · \(summary)")
    }
}
