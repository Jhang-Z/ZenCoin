import AppIntents

/// 注册 ZenCoin 在系统快捷指令 / Spotlight 里可见的语音短语和默认条目。
struct ExpenseShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddExpenseFromScreenshot(),
            phrases: [
                "用 \(.applicationName) 截图记账",
                "\(.applicationName) AI 记账",
                "\(.applicationName) 记账",
            ],
            shortTitle: "AI 截图记账",
            systemImageName: "camera.viewfinder"
        )
    }
}
