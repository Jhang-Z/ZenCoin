import SwiftUI

/// 主 header 左上的"账本指示器"。永远显示。
/// - 主账本：低调样式（separator 描边、textSecondary dot）—— 提示存在但不抢戏
/// - 其他账本：accent 描边 + accent dot —— 提醒"你不在主账本"
/// 末尾固定加一个 chevron.down 暗示可点击切换。
struct BookChip: View {
    @Environment(\.theme) private var theme
    let book: Book
    let onTap: () -> Void

    private var isDefault: Bool { book.isDefault }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Circle()
                    .fill(isDefault ? theme.textSecondary : theme.accent)
                    .frame(width: 8, height: 8)
                Text(book.name)
                    .font(theme.type.body)
                    .foregroundStyle(theme.textPrimary)
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(theme.textSecondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .stroke(
                        isDefault ? theme.separator : theme.accent.opacity(0.45),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("当前账本：\(book.name)，点击切换")
    }
}
