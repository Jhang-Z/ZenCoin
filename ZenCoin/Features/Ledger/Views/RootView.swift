import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.bookStore) private var bookStore

    @State private var selectedTab: Tab = .ledger
    @State private var showingEntry = false

    @State private var ledgerVM: LedgerViewModel?
    @State private var selection = LedgerSelectionStore()
    @State private var confirmingBatchDelete = false
    @State private var showingMoveSheet = false

    enum Tab { case ledger, insight }

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .ledger:
                    LedgerView(
                        ledgerVM: $ledgerVM,
                        selection: selection,
                        onShowSettings: nil
                    )
                case .insight:
                    InsightView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(theme.bgPrimary.ignoresSafeArea())

            if selection.isActive {
                selectionBar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .ignoresSafeArea(.keyboard, edges: .bottom)
            } else {
                BottomBar(
                    selected: $selectedTab,
                    onAdd: { showingEntry = true }
                )
                .transition(.opacity)
                // 键盘弹起时锁定 tab bar 在屏幕底部，不跟随上浮
                // （关键：必须在外部调用点应用，内部 modifier 抵不过父级 ZStack 重排）
                .ignoresSafeArea(.keyboard, edges: .bottom)
            }
        }
        .animation(.easeInOut(duration: 0.22), value: selection.isActive)
        .sheet(isPresented: $showingEntry) {
            // detents 由 EntrySheet 内部按模式（支出 / 收入）反应式决定
            EntrySheet()
                .environment(\.modelContext, modelContext)
                .presentationDragIndicator(.hidden)
                .presentationBackground(theme.bgPrimary)
        }
        .zenConfirm(
            isPresented: $confirmingBatchDelete,
            kind: .destructive,
            title: "删除选中的 \(selection.ids.count) 条记录？",
            message: "此操作无法撤销。",
            confirmLabel: "删除"
        ) {
            ledgerVM?.deleteMany(ids: selection.ids)
            selection.exit()
        }
        .sheet(isPresented: $showingMoveSheet) {
            if let store = bookStore {
                BookPickerSheet(
                    books: store.books,
                    excludeId: store.currentBookId,
                    title: "MOVE TO / 移动到"
                ) { targetId in
                    ledgerVM?.moveMany(ids: selection.ids, toBookId: targetId)
                    selection.exit()
                }
                .presentationBackground(theme.bgPrimary)
            }
        }
    }

    private var selectionBar: some View {
        let totals: (expense: Double, income: Double) =
            ledgerVM?.selectionTotals(ids: selection.ids) ?? (expense: 0, income: 0)
        // 至少要有 2 个账本（来源 + 至少 1 个目标）才显示「移动」
        let canMove = (bookStore?.books.count ?? 0) >= 2
        return SelectionSummaryBar(
            count: selection.ids.count,
            totalExpense: totals.expense,
            totalIncome: totals.income,
            canMove: canMove,
            onClear: { selection.exit() },
            onMove: { showingMoveSheet = true },
            onDelete: { confirmingBatchDelete = true }
        )
    }
}

// MARK: - Bottom bar

private struct BottomBar: View {
    @Environment(\.theme) private var theme
    @Binding var selected: RootView.Tab
    let onAdd: () -> Void

    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                tabButton(.ledger, label: "LEDGER", icon: "list.bullet")
                Spacer().frame(width: 80)
                tabButton(.insight, label: "INSIGHT", icon: "chart.bar")
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 10)
            .padding(.bottom, 4)
            .padding(.horizontal, 24)
            .background(
                theme.bgSurface
                    .overlay(Rectangle().fill(theme.separator).frame(height: 1), alignment: .top)
                    .ignoresSafeArea(edges: .bottom)
            )

            Button(action: onAdd) {
                ZStack {
                    Circle().fill(theme.accent)
                        .frame(width: 56, height: 56)
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(theme.bgPrimary)
                }
            }
            .offset(y: -22)
            .accessibilityLabel("新增记账")
        }
    }

    private func tabButton(_ tab: RootView.Tab, label: String, icon: String) -> some View {
        let isSelected = selected == tab
        return Button {
            selected = tab
            UISelectionFeedbackGenerator().selectionChanged()
        } label: {
            VStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: isSelected ? .medium : .regular))
                Text(label)
                    .font(theme.type.micro)
                    .tracking(0.8)
                Rectangle()
                    .fill(isSelected ? theme.accent : Color.clear)
                    .frame(width: 16, height: 1)
            }
            .foregroundStyle(isSelected ? theme.textPrimary : theme.textSecondary)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
