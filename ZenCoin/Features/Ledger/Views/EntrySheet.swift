import SwiftUI
import SwiftData

/// 手动记账表单。AI 识别走系统快捷指令 → AppIntent，不在本 sheet 出现。
struct EntrySheet: View {
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.bookStore) private var bookStore
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: EntryViewModel?
    @FocusState private var noteFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            modeHeader
                .padding(.horizontal, 24)
                .padding(.top, 18)

            amountDisplay
                .padding(.horizontal, 24)
                .padding(.top, 24)

            CategoryPickerView(
                isIncome: viewModel?.isIncome ?? false,
                selected: Binding(
                    get: { viewModel?.category ?? .dining },
                    set: { viewModel?.category = $0 }
                )
            )
            .padding(.top, 28)

            noteField
                .padding(.horizontal, 24)
                .padding(.top, 14)
                .padding(.bottom, (viewModel?.isIncome == false) ? 8 : 14)

            if let vm = viewModel, !vm.isIncome {
                participantsRow(vm: vm)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 14)
            }

            AmountKeypadView(
                onToken: { viewModel?.appendToken($0) },
                onBackspace: { viewModel?.backspace() },
                onSave: save,
                canSave: viewModel?.canSave ?? false
            )
        }
        .dismissKeyboardOnBackgroundTap()
        .background(theme.bgPrimary.ignoresSafeArea())
        // 让 sheet 高度跟着分类多寡走 —— 支出 12 类 vs 收入 4 类差 ~150pt，
        // 同一个 fraction 会在收入模式撑出 200pt 无意义呼吸区。
        .presentationDetents([
            viewModel?.isIncome == true ? .fraction(0.70) : .fraction(0.85)
        ])
        .onAppear {
            if viewModel == nil {
                viewModel = EntryViewModel(
                    modelContext: modelContext,
                    bookId: bookStore?.currentBookId ?? Book.defaultID
                )
            }
        }
    }

    // MARK: - Header

    private var modeHeader: some View {
        HStack(spacing: 8) {
            modeButton("支出", isSelected: !(viewModel?.isIncome ?? false)) {
                viewModel?.switchMode(toIncome: false)
            }
            modeButton("收入", isSelected: viewModel?.isIncome ?? false) {
                viewModel?.switchMode(toIncome: true)
            }
            Spacer()
            closeButton
        }
    }

    private func modeButton(_ label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(theme.type.body)
                .foregroundStyle(isSelected ? theme.bgPrimary : theme.textSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: theme.radiusSmall)
                        .fill(isSelected ? theme.textPrimary : theme.bgSurface)
                )
        }
        .buttonStyle(.plain)
    }

    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(theme.textSecondary)
                .frame(width: 32, height: 32)
                .background(Circle().fill(theme.bgSurface))
        }
    }

    // MARK: - Amount

    private var amountDisplay: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(viewModel?.displayExpression ?? "")
                .font(.system(size: 56, weight: .medium, design: theme.fontDesign))
                .tracking(theme.displayTracking)
                .foregroundStyle((viewModel?.amount ?? 0) > 0 ? theme.accent : theme.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .frame(maxWidth: .infinity, alignment: .trailing)
            // 当用户输入了表达式（含运算符），把求值结果作为 secondary 行展示。
            if let vm = viewModel, vm.hasOperator {
                Text("= \(CurrencyFormatter.format(vm.amount))")
                    .font(theme.type.caption)
                    .foregroundStyle(theme.textSecondary)
            }
        }
    }

    private var noteField: some View {
        HStack(spacing: 8) {
            Image(systemName: "pencil")
                .font(.system(size: 13))
                .foregroundStyle(theme.textSecondary)
            TextField("描述（可选）", text: Binding(
                get: { viewModel?.note ?? "" },
                set: { viewModel?.note = $0 }
            ))
            .font(theme.type.body)
            .foregroundStyle(theme.textPrimary)
            .focused($noteFocused)
            .submitLabel(.done)
            .onSubmit { noteFocused = false }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: theme.radiusSmall)
                .fill(theme.bgSurface)
        )
    }

    private func save() {
        guard viewModel?.save() == true else { return }
        UISelectionFeedbackGenerator().selectionChanged()
        dismiss()
    }

    // MARK: - Participants chip row

    @ViewBuilder
    private func participantsRow(vm: EntryViewModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("PARTICIPANTS / 参与人")
                    .font(theme.type.micro)
                    .tracking(0.6)
                    .foregroundStyle(theme.textSecondary)
                Spacer()
                Text(participantsMeta(vm: vm))
                    .font(theme.type.micro)
                    .tracking(0.4)
                    .monospacedDigit()
                    .foregroundStyle(theme.textSecondary)
            }
            HStack(spacing: ParticipantPalette.chipSpacing) {
                ForEach(0..<ParticipantPalette.count, id: \.self) { idx in
                    chip(idx: idx, vm: vm)
                }
                Spacer(minLength: 0)
            }
        }
    }

    /// 单个色位 chip。
    /// - 已选：实心填充对应色，alpha 100%
    /// - 未选：仅描边（用 separator）+ alpha 30% 填充提示「可点击」
    /// - idx 0 self：始终选中、不可取消（轻点反馈但状态不变）
    @ViewBuilder
    private func chip(idx: Int, vm: EntryViewModel) -> some View {
        let on = vm.participantColors.contains(idx)
        let isSelf = idx == 0
        Button {
            UISelectionFeedbackGenerator().selectionChanged()
            vm.toggleParticipantColor(idx)
        } label: {
            ZStack {
                Circle()
                    .fill(on ? ParticipantPalette.color(for: idx)
                             : ParticipantPalette.color(for: idx).opacity(0.18))
                    .frame(width: ParticipantPalette.chipSize, height: ParticipantPalette.chipSize)
                if isSelf {
                    // self chip 中央嵌一个小白点，提示「这是我」
                    Circle()
                        .fill(theme.bgPrimary)
                        .frame(width: 6, height: 6)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(isSelf)
    }

    private func participantsMeta(vm: EntryViewModel) -> String {
        let n = vm.participantColors.count
        guard n > 1, vm.amount > 0 else { return "" }
        let perHead = vm.amount / Double(n)
        return "\(n) 人均摊 · \(CurrencyFormatter.format(perHead))/人"
    }
}
