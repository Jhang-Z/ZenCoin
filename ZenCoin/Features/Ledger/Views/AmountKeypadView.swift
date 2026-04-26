import SwiftUI

/// 金额输入键盘。4×4 数字 + 运算符布局（最后一列是 ÷ × − +），
/// 右侧贴一个全高 "保存" 按钮，按下时表达式自动求值。
struct AmountKeypadView: View {
    @Environment(\.theme) private var theme

    /// 一次按键回调；token 可能是 "0"…"9", ".", 或运算符 "+" "-" "×" "÷"。
    let onToken: (String) -> Void
    let onBackspace: () -> Void
    let onSave: () -> Void
    let canSave: Bool

    private let rows: [[String]] = [
        ["1", "2", "3", "÷"],
        ["4", "5", "6", "×"],
        ["7", "8", "9", "−"],
        [".", "0", "⌫", "+"],
    ]

    /// 单格高度（与 keyButton 的 minHeight 同步）。
    private static let keyHeight: CGFloat = 56
    /// 整个键盘的固定高度 = 4 行 × 56 + 3 个 1pt 分隔 + 8pt 底 padding。
    /// 显式锁高度，避免 saveButton 的 `.frame(maxHeight: .infinity)` 在外层
    /// VStack 里跟 Spacer 抢 flex space（症状：键盘上方出现一片灰色空白）。
    private static let totalHeight: CGFloat = keyHeight * 4 + 3 + 8

    var body: some View {
        HStack(spacing: 1) {
            VStack(spacing: 1) {
                ForEach(rows, id: \.self) { row in
                    HStack(spacing: 1) {
                        ForEach(row, id: \.self) { label in
                            keyButton(label)
                        }
                    }
                }
            }
            saveButton
        }
        .padding(.bottom, 8)
        .frame(height: Self.totalHeight)
        .background(theme.separator)
    }

    private func keyButton(_ label: String) -> some View {
        let isOperator = ["÷", "×", "−", "+"].contains(label)
        let isControl = label == "⌫"
        return Button {
            UISelectionFeedbackGenerator().selectionChanged()
            switch label {
            case "⌫": onBackspace()
            case "−": onToken("-")  // 视觉用真减号，传给 VM 的是 ASCII -
            default:  onToken(label)
            }
        } label: {
            Text(label)
                .font(.system(
                    size: isControl ? 18 : 22,
                    weight: isOperator ? .medium : .regular,
                    design: theme.fontDesign
                ))
                .tracking(theme.displayTracking * 0.3)
                .foregroundStyle(
                    isOperator ? theme.accent :
                    isControl ? theme.textSecondary :
                    theme.textPrimary
                )
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(isOperator ? theme.bgSurface : theme.bgPrimary)
        }
        .buttonStyle(.plain)
    }

    private var saveButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            onSave()
        } label: {
            VStack {
                Spacer()
                Text("保存")
                    .font(.system(size: 17, weight: .semibold, design: theme.fontDesign))
                    .foregroundStyle(canSave ? theme.bgPrimary : theme.textSecondary)
                Spacer()
            }
            .frame(width: 84)
            .frame(maxHeight: .infinity)
            .background(canSave ? theme.accent : theme.bgInput)
        }
        .buttonStyle(.plain)
        .disabled(!canSave)
    }
}
