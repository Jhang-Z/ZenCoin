import SwiftUI
import SwiftData

struct LedgerView: View {
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.bookStore) private var bookStore

    @Binding var ledgerVM: LedgerViewModel?
    let selection: LedgerSelectionStore
    /// Unused — settings are reachable via the gear icon in this view; kept for caller flexibility.
    let onShowSettings: (() -> Void)?

    @State private var showingSettings = false
    @State private var showingMonthPicker = false
    @State private var showingBookSwitch = false
    @State private var pushedExpenseId: UUID?

    var body: some View {
        NavigationStack {
            content
                .background(theme.bgPrimary.ignoresSafeArea())
                .navigationDestination(item: $pushedExpenseId) { id in
                    ExpenseDetailView(expenseId: id)
                }
                .sheet(isPresented: $showingSettings) {
                    NavigationStack { SettingsView() }
                        .presentationBackground(theme.bgPrimary)
                }
                .sheet(isPresented: $showingMonthPicker) {
                    if let vm = ledgerVM {
                        MonthPickerSheet(initialYear: vm.year, initialMonth: vm.month) { y, m in
                            vm.setMonth(year: y, month: m)
                        }
                        .presentationBackground(theme.bgPrimary)
                    }
                }
                .sheet(isPresented: $showingBookSwitch) {
                    if let store = bookStore {
                        BookSwitchSheet(
                            books: store.books,
                            currentBookId: store.currentBookId,
                            onPick: { id in store.currentBookId = id },
                            onManage: { showingSettings = true }
                        )
                        .presentationBackground(theme.bgPrimary)
                    }
                }
        }
        .onAppear {
            if ledgerVM == nil {
                ledgerVM = LedgerViewModel(
                    modelContext: modelContext,
                    bookId: bookStore?.currentBookId ?? Book.defaultID
                )
            }
            ledgerVM?.setBook(bookStore?.currentBookId ?? Book.defaultID)
            ledgerVM?.reload()
        }
        .onReceive(NotificationCenter.default.publisher(for: .expenseStoreDidChange)) { _ in
            ledgerVM?.reload()
        }
        .onReceive(NotificationCenter.default.publisher(for: .currentBookDidChange)) { _ in
            ledgerVM?.setBook(bookStore?.currentBookId ?? Book.defaultID)
        }
    }

    @ViewBuilder
    private var content: some View {
        VStack(spacing: 0) {
            header
            if let vm = ledgerVM {
                if vm.entries.isEmpty {
                    emptyState
                } else {
                    list(vm: vm)
                }
            } else {
                Spacer()
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            // 品牌标记 + 账本指示器并排，构成 header 第一行。
            HStack(spacing: 10) {
                ZenCoinMark(size: 22)
                if let store = bookStore, let book = store.currentBook {
                    BookChip(book: book) {
                        showingBookSwitch = true
                    }
                }
            }

            HStack(spacing: 8) {
                Button {
                    showingMonthPicker = true
                } label: {
                    HStack(spacing: 6) {
                        Text(ledgerVM?.monthLabel ?? "")
                            .font(theme.type.title)
                            .foregroundStyle(theme.textPrimary)
                            .tracking(theme.displayTracking * 0.4)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(theme.textSecondary)
                    }
                }
                .buttonStyle(.plain)
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: 0.4).onEnded { _ in
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        showingBookSwitch = true
                    }
                )

                Spacer()

                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundStyle(theme.textSecondary)
                        .frame(width: 32, height: 32)
                }
                .accessibilityLabel("设置")
            }

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(formattedNet)
                    .font(theme.type.display)
                    .foregroundStyle(formattedNetColor)
                    .tracking(theme.displayTracking)
                Spacer()
            }

            HStack(alignment: .top, spacing: 0) {
                summaryItem(label: "IN", amount: ledgerVM?.monthIncomeTotal ?? 0, color: theme.accent)
                divider
                summaryItem(label: "OUT", amount: ledgerVM?.monthExpenseTotal ?? 0, color: theme.textPrimary)
                divider
                summaryItem(label: "BAL", amount: ledgerVM?.monthNet ?? 0, color: theme.textPrimary, signed: true)
            }
            .padding(.top, 8)

            Rectangle()
                .fill(theme.separator)
                .frame(height: 1)
                .padding(.top, 8)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 12)
        .gesture(
            DragGesture(minimumDistance: 28)
                .onEnded { value in
                    let dx = value.translation.width
                    if abs(dx) < 60 { return }
                    ledgerVM?.step(dx < 0 ? 1 : -1)
                }
        )
    }

    private var divider: some View {
        Rectangle().fill(theme.separator).frame(width: 1, height: 32)
    }

    private func summaryItem(label: String, amount: Double, color: Color, signed: Bool = false) -> some View {
        VStack(alignment: .center, spacing: 4) {
            Text(label)
                .font(theme.type.micro)
                .tracking(0.8)
                .foregroundStyle(theme.textSecondary)
            Text(amountText(amount, signed: signed))
                .font(theme.type.headingNumeric)
                .monospacedDigit()
                .foregroundStyle(amount == 0 ? theme.textSecondary : color)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private func amountText(_ amount: Double, signed: Bool) -> String {
        if signed {
            if amount == 0 { return CurrencyFormatter.format(0) }
            return CurrencyFormatter.format(abs(amount), signed: true, isIncome: amount > 0)
        }
        return CurrencyFormatter.format(amount)
    }

    private var formattedNet: String {
        guard let vm = ledgerVM else { return CurrencyFormatter.format(0) }
        let net = vm.monthNet
        if net == 0 { return CurrencyFormatter.format(0) }
        return CurrencyFormatter.format(abs(net), signed: true, isIncome: net > 0)
    }

    private var formattedNetColor: Color {
        let net = ledgerVM?.monthNet ?? 0
        if net > 0 { return theme.accent }
        return theme.textPrimary
    }

    // MARK: - List

    private func list(vm: LedgerViewModel) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(vm.groupedByDay, id: \.date) { group in
                    dayHeader(group.date)
                    ForEach(group.items) { entry in
                        EntryRowView(
                            entry: entry,
                            isSelectionMode: selection.isActive,
                            isSelected: selection.ids.contains(entry.id)
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            handleTap(entry)
                        }
                        .onLongPressGesture(minimumDuration: 0.35) {
                            handleLongPress(entry)
                        }
                        Rectangle()
                            .fill(theme.separator)
                            .frame(height: 1)
                            .padding(.horizontal, 24)
                    }
                }
                Color.clear.frame(height: 140)
            }
        }
    }

    private func dayHeader(_ date: Date) -> some View {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "M 月 d 日 · EEEE"
        return HStack {
            Text(f.string(from: date))
                .font(theme.type.micro)
                .tracking(0.6)
                .foregroundStyle(theme.textSecondary)
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 8)
    }

    private var emptyState: some View {
        VStack {
            Spacer()
            Text("本月还没有记录")
                .font(theme.type.body)
                .foregroundStyle(theme.textSecondary)
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Selection

    private func handleTap(_ entry: Expense) {
        if selection.isActive {
            UISelectionFeedbackGenerator().selectionChanged()
            selection.toggle(entry.id)
        } else {
            pushedExpenseId = entry.id
        }
    }

    private func handleLongPress(_ entry: Expense) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        if !selection.isActive {
            selection.enter(with: entry.id)
        } else {
            selection.toggle(entry.id)
        }
    }
}
