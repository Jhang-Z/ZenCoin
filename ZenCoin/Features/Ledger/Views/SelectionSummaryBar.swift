import SwiftUI

struct SelectionSummaryBar: View {
    @Environment(\.theme) private var theme
    let count: Int
    let totalExpense: Double
    let totalIncome: Double
    let onClear: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
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
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: theme.radiusSmall)
                            .fill(theme.bgInput)
                    )
            }
            .buttonStyle(.plain)

            Button(action: onDelete) {
                Text("删除")
                    .font(theme.type.body.weight(.semibold))
                    .foregroundStyle(theme.bgPrimary)
                    .padding(.horizontal, 16)
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
                .font(theme.type.heading)
                .foregroundStyle(theme.textPrimary)
        } else {
            HStack(spacing: 14) {
                if totalExpense > 0 {
                    Text("- " + CurrencyFormatter.format(totalExpense))
                        .font(theme.type.heading)
                        .foregroundStyle(theme.textPrimary)
                }
                if totalIncome > 0 {
                    Text("+ " + CurrencyFormatter.format(totalIncome))
                        .font(theme.type.heading)
                        .foregroundStyle(theme.accent)
                }
            }
        }
    }
}
