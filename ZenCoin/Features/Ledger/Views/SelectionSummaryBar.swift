import SwiftUI

struct SelectionSummaryBar: View {
    @Environment(\.theme) private var theme
    let count: Int
    let totalExpense: Double
    let totalIncome: Double
    /// 已选笔的"我的份额"求和（按 amount/participantColors.count 加和）。
    /// 仅当 ≥1 笔含 ≥2 人时显示这一行；否则与 totalExpense 相同（无需重复展示）。
    let myShareExpense: Double
    /// 是否显示「移动」按钮（只有多账本场景才有意义）
    let canMove: Bool
    let onClear: () -> Void
    let onMove: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("SELECTED · \(count)")
                    .font(theme.type.micro)
                    .tracking(0.8)
                    .foregroundStyle(theme.textSecondary)
                amountLine
            }

            Spacer(minLength: 8)

            Button(action: onClear) {
                Text("取消")
                    .font(theme.type.body)
                    .foregroundStyle(theme.textSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: theme.radiusSmall)
                            .fill(theme.bgInput)
                    )
            }
            .buttonStyle(.plain)

            if canMove {
                Button(action: onMove) {
                    Text("移动")
                        .font(theme.type.body)
                        .foregroundStyle(theme.textPrimary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: theme.radiusSmall)
                                .fill(theme.bgSurface)
                                .overlay(
                                    RoundedRectangle(cornerRadius: theme.radiusSmall)
                                        .stroke(theme.separator, lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(.plain)
                .disabled(count == 0)
                .opacity(count == 0 ? 0.4 : 1)
            }

            Button(action: onDelete) {
                Text("删除")
                    .font(theme.type.body.weight(.semibold))
                    .foregroundStyle(theme.bgPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: theme.radiusSmall)
                            .fill(theme.error)
                    )
            }
            .buttonStyle(.plain)
            .disabled(count == 0)
            .opacity(count == 0 ? 0.4 : 1)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(
            theme.bgSurface
                .overlay(Rectangle().fill(theme.separator).frame(height: 1), alignment: .top)
        )
    }

    @ViewBuilder
    private var amountLine: some View {
        if totalExpense == 0 && totalIncome == 0 {
            Text("—")
                .font(theme.type.headingNumeric)
                .foregroundStyle(theme.textPrimary)
        } else {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 14) {
                    if totalExpense > 0 {
                        Text("- " + CurrencyFormatter.format(totalExpense))
                            .font(theme.type.headingNumeric)
                            .monospacedDigit()
                            .foregroundStyle(theme.textPrimary)
                    }
                    if totalIncome > 0 {
                        Text("+ " + CurrencyFormatter.format(totalIncome))
                            .font(theme.type.headingNumeric)
                            .monospacedDigit()
                            .foregroundStyle(theme.accent)
                    }
                }
                // 仅当我的份额 != 总支出（即至少有一笔分摊了）才显示份额行，避免冗余
                if showsShare {
                    Text("我的份额 " + CurrencyFormatter.format(myShareExpense))
                        .font(theme.type.micro)
                        .tracking(0.4)
                        .monospacedDigit()
                        .foregroundStyle(theme.textSecondary)
                }
            }
        }
    }

    private var showsShare: Bool {
        totalExpense > 0
            && abs(myShareExpense - totalExpense) > 0.005
    }
}
