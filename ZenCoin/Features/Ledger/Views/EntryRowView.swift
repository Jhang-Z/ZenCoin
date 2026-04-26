import SwiftUI

struct EntryRowView: View {
    @Environment(\.theme) private var theme
    let entry: Expense
    let isSelectionMode: Bool
    let isSelected: Bool

    init(entry: Expense, isSelectionMode: Bool = false, isSelected: Bool = false) {
        self.entry = entry
        self.isSelectionMode = isSelectionMode
        self.isSelected = isSelected
    }

    var body: some View {
        HStack(spacing: 14) {
            if isSelectionMode {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(isSelected ? theme.accent : theme.separator)
                    .frame(width: 24)
                    .transition(.opacity.combined(with: .move(edge: .leading)))
            }

            ZStack {
                Circle()
                    .fill(theme.accentMuted)
                    .frame(width: 36, height: 36)
                Image(systemName: entry.category.iconName)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(theme.accent)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(primaryText)
                    .font(theme.type.heading)
                    .foregroundStyle(theme.textPrimary)
                    .lineLimit(1)
                Text(secondaryText)
                    .font(theme.type.caption)
                    .foregroundStyle(theme.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Text(CurrencyFormatter.format(
                entry.amount,
                signed: true,
                isIncome: entry.isIncome
            ))
            .font(theme.type.headingNumeric)
            .monospacedDigit()
            .foregroundStyle(entry.isIncome ? theme.accent : theme.textPrimary)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }

    /// 主标题：备注（fallback：分类名）
    private var primaryText: String {
        let trimmed = entry.note.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? entry.category.displayName : trimmed
    }

    /// 副标题：永远展示「时间」+（如果有备注）「分类」。
    /// 没备注时只展示时间（避免和主标题重复"分类 · 时间 · 分类"）。
    private var secondaryText: String {
        let trimmed = entry.note.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            return timeText
        }
        return "\(entry.category.displayName) · \(timeText)"
    }

    private var timeText: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "HH:mm"
        return f.string(from: entry.paymentTime)
    }
}
