import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext

    @State private var selectedTab: Tab = .ledger
    @State private var showingEntry = false

    @State private var ledgerVM: LedgerViewModel?
    @State private var selection = LedgerSelectionStore()
    @State private var confirmingBatchDelete = false

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
            } else {
                BottomBar(
                    selected: $selectedTab,
                    onAdd: { showingEntry = true }
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.22), value: selection.isActive)
        .sheet(isPresented: $showingEntry) {
            EntrySheet()
                .environment(\.modelContext, modelContext)
                .presentationDetents([.fraction(0.85)])
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
    }

    private var selectionBar: some View {
        let totals: (expense: Double, income: Double) =
            ledgerVM?.selectionTotals(ids: selection.ids) ?? (expense: 0, income: 0)
        return SelectionSummaryBar(
            count: selection.ids.count,
            totalExpense: totals.expense,
            totalIncome: totals.income,
            onClear: { selection.exit() },
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
