import SwiftUI

struct EntryRowView: View {
    @Environment(\.theme) private var theme
    let entry: Expense
    let isSelectionMode: Bool
    let isSelected: Bool
    /// 当用户 tap 这一行末尾的 dot strip 时调用。
    /// 上层（LedgerView）拿到回调后，进入选择模式并把所有 participantColors 完全相同的笔自动勾选。
    /// nil 时 dot strip 仅作展示，不响应点击。
    let onParticipantStripTap: (() -> Void)?

    init(
        entry: Expense,
        isSelectionMode: Bool = false,
        isSelected: Bool = false,
        onParticipantStripTap: (() -> Void)? = nil
    ) {
        self.entry = entry
        self.isSelectionMode = isSelectionMode
        self.isSelected = isSelected
        self.onParticipantStripTap = onParticipantStripTap
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
                HStack(spacing: 8) {
                    Text(secondaryText)
                        .font(theme.type.caption)
                        .foregroundStyle(theme.textSecondary)
                        .lineLimit(1)
                    if showsDots {
                        dotStrip
                    }
                }
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

    // MARK: - Participant dot strip

    private var showsDots: Bool {
        // 仅 1 人（仅自己）→ 不显示，跟以前一模一样
        entry.participantColors.count >= 2
    }

    private var dotStrip: some View {
        // tap 这条 strip → 触发上层"自动勾选同组"逻辑。
        // strip 是 row 内独立的 hit area，不影响 row 主体的 tap / long-press。
        let sorted = entry.participantColors.sorted()
        return HStack(spacing: ParticipantPalette.dotSpacing) {
            ForEach(sorted, id: \.self) { idx in
                Circle()
                    .fill(ParticipantPalette.color(for: idx))
                    .frame(width: ParticipantPalette.dotSize, height: ParticipantPalette.dotSize)
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            guard let cb = onParticipantStripTap else { return }
            UISelectionFeedbackGenerator().selectionChanged()
            cb()
        }
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
