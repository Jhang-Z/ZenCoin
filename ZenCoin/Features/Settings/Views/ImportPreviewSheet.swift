import SwiftUI
import SwiftData

/// 选好账单文件后弹出的预览页。
///
/// - 头部：左侧 micro caps + 标题 + meta（n 笔可导入 / 已跳过 m 笔 / AI 推断状态）；
///   右侧依赖系统下拉指示器关闭。
/// - 列表：每行一笔交易；轻点 = 切换勾选；长按 = 打开类别选择 sheet。
/// - 关键词字典没命中的行先落到 .other / .otherIncome 占位，
///   on appear 时如果配了百炼 API key，异步批量发给 qwen-max 拿建议；
///   返回前行右侧显示 `推断中…`，返回后若类别变了显示一个 micro 的 `AI`。
/// - 底部固定 CTA：「导入 N 笔」。
struct ImportPreviewSheet: View {
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.bookStore) private var bookStore
    @Environment(\.dismiss) private var dismiss

    let parseResult: WeChatPayParser.Result

    @State private var drafts: [ImportDraft]
    @State private var importing = false
    @State private var summary: String?
    @State private var aiState: AIState = .idle
    @State private var editingDraftId: UUID?

    private enum AIState: Equatable {
        case idle
        case running(completed: Int, total: Int)
        case done(updated: Int)
        case failed(String)
    }

    init(parseResult: WeChatPayParser.Result) {
        self.parseResult = parseResult
        _drafts = State(initialValue: parseResult.drafts)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Rectangle().fill(theme.separator).frame(height: 1)
            if case .running(let c, let t) = aiState {
                aiBanner(completed: c, total: t)
                    .transition(.opacity)
            }
            list
            Rectangle().fill(theme.separator).frame(height: 1)
            footer
        }
        .animation(.easeInOut(duration: 0.22), value: aiStateKey)
        .background(theme.bgPrimary.ignoresSafeArea())
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .task { await runAI() }
        .sheet(item: Binding(
            get: { editingDraftId.flatMap { id in drafts.first(where: { $0.id == id }) } },
            set: { _ in editingDraftId = nil }
        )) { draft in
            categoryPickerSheet(for: draft)
                .presentationDetents([.height(320)])
                .presentationBackground(theme.bgPrimary)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("IMPORT / 导入预览")
                .font(theme.type.micro)
                .tracking(0.8)
                .foregroundStyle(theme.textSecondary)
            Text("微信支付账单")
                .font(theme.type.title)
                .foregroundStyle(theme.textPrimary)
                .tracking(theme.displayTracking * 0.4)
            Text(metaLabel)
                .font(theme.type.micro)
                .tracking(0.6)
                .foregroundStyle(theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 16)
    }

    private var metaLabel: String {
        let enabled = drafts.filter { $0.enabled }.count
        let skipped = parseResult.skipped.count
        var parts = ["可导入 \(enabled) 笔", "已自动跳过 \(skipped) 笔"]
        switch aiState {
        case .idle, .running:                  break  // running 状态由下方 banner 显示
        case .done(let n) where n > 0:         parts.append("AI 已推断 \(n) 笔")
        case .done:                            break
        case .failed(let msg):                 parts.append("AI 跳过：\(msg)")
        }
        return parts.joined(separator: " · ")
    }

    /// 仅区分大类，避免 .running(c, t) 内部数字变化时整段 banner 闪烁。
    /// 进度条的细粒度动画由 banner 内部自己处理。
    private var aiStateKey: String {
        switch aiState {
        case .idle:    return "idle"
        case .running: return "running"
        case .done:    return "done"
        case .failed:  return "failed"
        }
    }

    /// 下方 AI 进度 banner：bgSurface 底 + accent 文字 + monospaced 数字 + 2pt 进度条。
    /// 设计原则（DESIGN.md §9）：inline progress，不用 spinner，不闪烁；变化用 0.22s easeInOut。
    @ViewBuilder
    private func aiBanner(completed: Int, total: Int) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Text("AI 正在分析")
                    .font(theme.type.body)
                    .foregroundStyle(theme.accent)
                Spacer()
                Text("\(completed) / \(total)")
                    .font(theme.type.body)
                    .monospacedDigit()
                    .foregroundStyle(theme.textPrimary)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            // 进度条：2pt accent 填充，宽度按完成比例伸长
            GeometryReader { geom in
                let ratio = total > 0 ? CGFloat(completed) / CGFloat(total) : 0
                ZStack(alignment: .leading) {
                    Rectangle().fill(theme.separator)
                    Rectangle()
                        .fill(theme.accent)
                        .frame(width: geom.size.width * ratio)
                        .animation(.easeInOut(duration: 0.3), value: completed)
                }
            }
            .frame(height: 2)
        }
        .background(theme.bgSurface)
    }

    // MARK: - List

    private var list: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(drafts.indices, id: \.self) { idx in
                    row(at: idx)
                    if idx < drafts.count - 1 {
                        Rectangle().fill(theme.separator).frame(height: 1).padding(.horizontal, 24)
                    }
                }
                Color.clear.frame(height: 16)
            }
        }
    }

    private func row(at idx: Int) -> some View {
        let draft = drafts[idx]
        return HStack(spacing: 14) {
            Image(systemName: draft.enabled ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(draft.enabled ? theme.accent : theme.separator)
                .frame(width: 24)

            ZStack {
                Circle().fill(theme.accentMuted).frame(width: 36, height: 36)
                Image(systemName: draft.category.iconName)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(theme.accent)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(draft.note.isEmpty ? draft.category.displayName : draft.note)
                    .font(theme.type.body)
                    .foregroundStyle(theme.textPrimary)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text("\(draft.category.displayName) · \(timeText(draft.paymentTime))")
                        .font(theme.type.caption)
                        .foregroundStyle(theme.textSecondary)
                        .lineLimit(1)
                    if draft.pendingAI {
                        Text("推断中")
                            .font(theme.type.micro)
                            .tracking(0.6)
                            .foregroundStyle(theme.textSecondary)
                    } else if draft.aiSuggested {
                        Text("AI")
                            .font(theme.type.micro)
                            .tracking(0.8)
                            .foregroundStyle(theme.accent)
                    }
                }
            }

            Spacer(minLength: 8)

            Text(CurrencyFormatter.format(draft.amount, signed: true, isIncome: draft.isIncome))
                .font(theme.type.body)
                .monospacedDigit()
                .foregroundStyle(draft.isIncome ? theme.accent : theme.textPrimary)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .onTapGesture {
            UISelectionFeedbackGenerator().selectionChanged()
            drafts[idx].enabled.toggle()
        }
        .onLongPressGesture(minimumDuration: 0.35) {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            editingDraftId = draft.id
        }
    }

    private func timeText(_ d: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "M-d HH:mm"
        return f.string(from: d)
    }

    // MARK: - Category picker sheet

    @ViewBuilder
    private func categoryPickerSheet(for draft: ImportDraft) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(draft.isIncome ? "INCOME / 收入分类" : "EXPENSE / 支出分类")
                .font(theme.type.micro)
                .tracking(0.8)
                .foregroundStyle(theme.textSecondary)
                .padding(.horizontal, 24)
            Text(draft.note.isEmpty ? "—" : draft.note)
                .font(theme.type.body)
                .foregroundStyle(theme.textPrimary)
                .lineLimit(1)
                .padding(.horizontal, 24)
            CategoryPickerView(
                isIncome: draft.isIncome,
                selected: Binding(
                    get: { draft.category },
                    set: { newCat in
                        if let i = drafts.firstIndex(where: { $0.id == draft.id }) {
                            drafts[i].category = newCat
                            // 用户手改后清掉 AI 标记：这是人选的
                            drafts[i].aiSuggested = false
                            drafts[i].pendingAI = false
                        }
                        editingDraftId = nil
                    }
                )
            )
            Spacer(minLength: 0)
        }
        .padding(.top, 24)
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 8) {
            if let summary {
                Text(summary)
                    .font(theme.type.caption)
                    .foregroundStyle(theme.textSecondary)
            }
            Button {
                runImport()
            } label: {
                Text(importing ? "导入中…" : "导入 \(enabledCount) 笔")
                    .font(theme.type.body.weight(.semibold))
                    .foregroundStyle(theme.bgPrimary)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(
                        RoundedRectangle(cornerRadius: theme.radiusSmall)
                            .fill(enabledCount > 0 ? theme.accent : theme.textSecondary.opacity(0.4))
                    )
            }
            .buttonStyle(.plain)
            .disabled(enabledCount == 0 || importing)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    private var enabledCount: Int {
        drafts.filter { $0.enabled }.count
    }

    // MARK: - AI batch

    private func runAI() async {
        let pending = drafts.filter { $0.pendingAI }
        guard !pending.isEmpty else { return }
        guard BailianKeyService.shared.hasAPIKey else {
            // 未配 key — 静默把 pendingAI 复位即可
            for i in drafts.indices where drafts[i].pendingAI { drafts[i].pendingAI = false }
            return
        }

        let total = pending.count
        var completed = 0
        var changed = 0
        aiState = .running(completed: 0, total: total)

        let items = pending.map {
            ExpenseAIService.ClassifyItem(
                id: $0.id,
                counterparty: $0.rawCounterparty,
                item: $0.rawItem,
                isIncome: $0.isIncome
            )
        }

        do {
            _ = try await ExpenseAIService.shared.classifyImports(items) { partial in
                // 每批完成立刻应用结果到 drafts 并刷新进度
                for i in drafts.indices where drafts[i].pendingAI {
                    if let r = partial[drafts[i].id] {
                        drafts[i].pendingAI = false
                        var didChange = false
                        if r.category != drafts[i].category {
                            drafts[i].category = r.category
                            didChange = true
                        }
                        if let cleanedNote = r.note, cleanedNote != drafts[i].note {
                            drafts[i].note = cleanedNote
                            didChange = true
                        }
                        if didChange {
                            drafts[i].aiSuggested = true
                            changed += 1
                        }
                    }
                }
                completed += partial.count
                aiState = .running(completed: min(completed, total), total: total)
            }
            // 兜底：清掉漏网的 pendingAI（某些 batch 失败 / 模型没返回这些 id）
            for i in drafts.indices where drafts[i].pendingAI { drafts[i].pendingAI = false }
            aiState = .done(updated: changed)
        } catch {
            for i in drafts.indices where drafts[i].pendingAI { drafts[i].pendingAI = false }
            aiState = .failed(error.localizedDescription)
        }
    }

    // MARK: - Import action

    private func runImport() {
        importing = true
        let svc = ExpenseDataService(modelContext: modelContext)
        let bid = bookStore?.currentBookId ?? Book.defaultID
        do {
            let existing = try svc.existingExternalIds()
            var inserted: [Expense] = []
            var dup = 0
            for d in drafts where d.enabled {
                if let eid = d.externalId, existing.contains(eid) { dup += 1; continue }
                let e = Expense(
                    amount: d.amount,
                    isIncome: d.isIncome,
                    category: d.category,
                    note: d.note,
                    paymentTime: d.paymentTime,
                    bookId: bid,
                    externalId: d.externalId
                )
                inserted.append(e)
            }
            try svc.insertMany(inserted)
            summary = "已导入 \(inserted.count) 笔，跳过重复 \(dup) 笔"
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                dismiss()
            }
        } catch {
            summary = "导入失败：\(error.localizedDescription)"
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            importing = false
        }
    }
}
