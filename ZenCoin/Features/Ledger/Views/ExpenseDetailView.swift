import SwiftUI
import SwiftData

struct ExpenseDetailView: View {
    let expenseId: UUID

    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var expense: Expense?
    @State private var editAmount: String = ""
    @State private var editNote: String = ""
    @State private var editPaymentTime: Date = .now
    @State private var editCategory: ExpenseCategory = .dining
    @State private var editIsIncome: Bool = false

    @State private var showCategorySheet = false
    @State private var showDateSheet = false
    @State private var showAmountSheet = false
    @State private var confirmingDelete = false
    @FocusState private var noteFocused: Bool

    private var service: ExpenseDataService { ExpenseDataService(modelContext: modelContext) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                amountHero
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 32)

                infoCard
                    .padding(.horizontal, 24)

                noteCard
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
            }
        }
        .background(theme.bgPrimary.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(editIsIncome ? "INCOME" : "EXPENSE")
                    .font(theme.type.micro)
                    .tracking(1.2)
                    .foregroundStyle(theme.textSecondary)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    confirmingDelete = true
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(theme.error)
                }
                .accessibilityLabel("删除记录")
            }
        }
        .dismissKeyboardOnBackgroundTap()
        .sheet(isPresented: $showCategorySheet) { categorySheet }
        .sheet(isPresented: $showDateSheet) { dateSheet }
        .sheet(isPresented: $showAmountSheet) { amountSheet }
        .zenConfirm(
            isPresented: $confirmingDelete,
            kind: .destructive,
            title: "删除这条记录？",
            message: "此操作无法撤销。",
            confirmLabel: "删除"
        ) {
            performDelete()
        }
        .onAppear { loadExpense() }
        .onChange(of: editNote) { _, _ in commit() }
        .onChange(of: editPaymentTime) { _, _ in commit() }
        .onChange(of: editCategory) { _, _ in commit() }
    }

    // MARK: - Hero

    private var amountHero: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(editIsIncome ? "INCOME" : "EXPENSE")
                .font(theme.type.micro)
                .tracking(1.2)
                .foregroundStyle(theme.textSecondary)

            Button {
                showAmountSheet = true
            } label: {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(displayAmount)
                        .font(.system(size: 56, weight: .medium, design: theme.fontDesign))
                        .tracking(theme.displayTracking)
                        .foregroundStyle(editIsIncome ? theme.accent : theme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var displayAmount: String {
        let amt = Double(editAmount) ?? 0
        let prefix = editIsIncome ? "+" : "-"
        return "\(prefix) \(CurrencyFormatter.format(amt))"
    }

    // MARK: - Info card

    private var infoCard: some View {
        VStack(spacing: 0) {
            row(label: "CATEGORY", value: editCategory.displayName, icon: editCategory.iconName) {
                showCategorySheet = true
            }
            divider
            row(label: "TIME", value: timeText, icon: "clock") {
                showDateSheet = true
            }
        }
        .background(
            RoundedRectangle(cornerRadius: theme.radiusMedium)
                .fill(theme.bgSurface)
        )
    }

    private func row(label: String, value: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(theme.accent)
                    .frame(width: 20)
                Text(label)
                    .font(theme.type.micro)
                    .tracking(0.8)
                    .foregroundStyle(theme.textSecondary)
                Spacer()
                Text(value)
                    .font(theme.type.body)
                    .foregroundStyle(theme.textPrimary)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(theme.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .buttonStyle(.plain)
    }

    private var divider: some View {
        Rectangle().fill(theme.separator).frame(height: 1).padding(.horizontal, 16)
    }

    private var timeText: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "M月d日 HH:mm"
        return f.string(from: editPaymentTime)
    }

    // MARK: - Note

    private var noteCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("DESCRIPTION")
                .font(theme.type.micro)
                .tracking(0.8)
                .foregroundStyle(theme.textSecondary)
                .padding(.horizontal, 16)
                .padding(.top, 14)

            TextField("添加描述…", text: $editNote, axis: .vertical)
                .font(theme.type.body)
                .foregroundStyle(theme.textPrimary)
                .focused($noteFocused)
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
                .padding(.top, 2)
                .lineLimit(1...6)
        }
        .background(
            RoundedRectangle(cornerRadius: theme.radiusMedium)
                .fill(theme.bgSurface)
        )
    }

    // MARK: - Sheets

    private var categorySheet: some View {
        let cases = editIsIncome ? ExpenseCategory.incomeCases : ExpenseCategory.expenseCases
        return CategoryGridSheet(cases: cases, selected: editCategory) { picked in
            editCategory = picked
            showCategorySheet = false
        }
    }

    private var dateSheet: some View {
        VStack(spacing: 0) {
            DatePicker(
                "",
                selection: $editPaymentTime,
                displayedComponents: [.date, .hourAndMinute]
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .padding(.top, 16)

            Button {
                showDateSheet = false
            } label: {
                Text("完成")
                    .font(theme.type.body.weight(.semibold))
                    .foregroundStyle(theme.bgPrimary)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(
                        RoundedRectangle(cornerRadius: theme.radiusSmall)
                            .fill(theme.accent)
                    )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(theme.bgPrimary)
        .presentationDetents([.height(360)])
        .presentationDragIndicator(.visible)
    }

    private var amountSheet: some View {
        AmountEditSheet(
            initialAmount: editAmount,
            isIncome: editIsIncome
        ) { newAmount in
            editAmount = newAmount
            commit()
            showAmountSheet = false
        }
    }

    // MARK: - Persistence

    private func loadExpense() {
        let id = expenseId
        let descriptor = FetchDescriptor<Expense>(
            predicate: #Predicate { $0.id == id }
        )
        guard let found = try? modelContext.fetch(descriptor).first else { return }
        expense = found
        editAmount = formatAmountForEditing(found.amount)
        editNote = found.note
        editPaymentTime = found.paymentTime
        editCategory = found.category
        editIsIncome = found.isIncome
    }

    private func formatAmountForEditing(_ amt: Double) -> String {
        if amt == amt.rounded() { return String(format: "%.0f", amt) }
        return String(format: "%.2f", amt)
    }

    private func commit() {
        guard let expense else { return }
        expense.amount = Double(editAmount) ?? expense.amount
        expense.note = editNote.trimmingCharacters(in: .whitespacesAndNewlines)
        expense.paymentTime = editPaymentTime
        expense.categoryRaw = editCategory.rawValue
        try? service.update(expense)
    }

    private func performDelete() {
        guard let expense else { return }
        try? service.delete(expense)
        dismiss()
    }
}

// MARK: - Category grid sheet

private struct CategoryGridSheet: View {
    @Environment(\.theme) private var theme
    let cases: [ExpenseCategory]
    let selected: ExpenseCategory
    let onPick: (ExpenseCategory) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)

    var body: some View {
        VStack(spacing: 0) {
            Text("CATEGORY")
                .font(theme.type.micro)
                .tracking(0.8)
                .foregroundStyle(theme.textSecondary)
                .padding(.top, 16)

            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(cases) { cat in
                    Button {
                        onPick(cat)
                    } label: {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(selected == cat ? theme.accent : theme.bgInput)
                                    .frame(width: 48, height: 48)
                                Image(systemName: cat.iconName)
                                    .font(.system(size: 17, weight: .regular))
                                    .foregroundStyle(selected == cat ? theme.bgPrimary : theme.textPrimary)
                            }
                            Text(cat.displayName)
                                .font(theme.type.caption)
                                .foregroundStyle(selected == cat ? theme.textPrimary : theme.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)

            Spacer(minLength: 0)
        }
        .background(theme.bgPrimary)
        .presentationDetents([.height(360)])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Amount edit sheet

private struct AmountEditSheet: View {
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss

    let initialAmount: String
    let isIncome: Bool
    let onCommit: (String) -> Void

    @State private var text: String

    init(initialAmount: String, isIncome: Bool, onCommit: @escaping (String) -> Void) {
        self.initialAmount = initialAmount
        self.isIncome = isIncome
        self.onCommit = onCommit
        _text = State(initialValue: initialAmount)
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .trailing, spacing: 4) {
                Text(displayExpression)
                    .font(.system(size: 56, weight: .medium, design: theme.fontDesign))
                    .tracking(theme.displayTracking)
                    .foregroundStyle(evaluated > 0 ? theme.accent : theme.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                if hasOperator {
                    Text("= \(CurrencyFormatter.format(evaluated))")
                        .font(theme.type.caption)
                        .foregroundStyle(theme.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 16)

            AmountKeypadView(
                onToken: appendToken,
                onBackspace: backspace,
                onSave: {
                    let v = evaluated
                    if v > 0 { onCommit(EntryViewModel.formatNumber(v)) }
                    dismiss()
                },
                canSave: evaluated > 0
            )
        }
        .background(theme.bgPrimary)
        .presentationDetents([.height(420)])
        .presentationDragIndicator(.visible)
    }

    private var hasOperator: Bool {
        text.contains { EntryViewModel.opChars.contains($0) }
    }

    private var evaluated: Double {
        EntryViewModel.evaluate(text)
    }

    private var displayExpression: String {
        if text.isEmpty || text == "0" { return CurrencyFormatter.format(0) }
        if hasOperator { return text }
        return "\(CurrencyFormatter.symbol.rawValue)\(text)"
    }

    private func appendToken(_ token: String) {
        let opChars = EntryViewModel.opChars
        if token.first.map({ opChars.contains($0) }) == true {
            if text.isEmpty || text == "0" { return }
            if let last = text.last, opChars.contains(last) {
                text = String(text.dropLast()) + token
                return
            }
            if text.hasSuffix(".") { text.removeLast() }
            text += token
            return
        }
        if token == "." {
            let cur = currentOperand()
            if cur.contains(".") { return }
            text += cur.isEmpty ? "0." : "."
            return
        }
        if text == "0" {
            text = token
            return
        }
        let cur = currentOperand()
        if let dot = cur.firstIndex(of: ".") {
            let decimals = cur.distance(from: dot, to: cur.endIndex) - 1
            if decimals >= 2 { return }
        }
        if cur.count >= 9 { return }
        text += token
    }

    private func currentOperand() -> String {
        var s = ""
        for ch in text.reversed() {
            if EntryViewModel.opChars.contains(ch) { break }
            s = String(ch) + s
        }
        return s
    }

    private func backspace() {
        if text.count <= 1 {
            text = "0"
        } else {
            text.removeLast()
            if text.isEmpty { text = "0" }
        }
    }
}
