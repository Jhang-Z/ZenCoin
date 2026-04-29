import SwiftUI

/// 选目标账本的 sheet，用于「把账单移动到其他账本」场景。
/// 跟 BookSwitchSheet 不同：
/// - 排除一个不可选项（来源账本本身）
/// - 不需要「管理账本」入口
/// - 标题更明确（「移动到」）
struct BookPickerSheet: View {
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss

    let books: [Book]
    /// 要排除的账本 id（一般是当前来源账本，避免移到自己）
    let excludeId: UUID
    let title: String
    let onPick: (UUID) -> Void

    private var selectable: [Book] {
        books.filter { $0.id != excludeId }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(title)
                    .font(theme.type.micro)
                    .tracking(0.8)
                    .foregroundStyle(theme.textSecondary)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(theme.textSecondary)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(theme.bgSurface))
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)

            if selectable.isEmpty {
                VStack(spacing: 8) {
                    Spacer().frame(height: 40)
                    Text("没有可选的目标账本")
                        .font(theme.type.body)
                        .foregroundStyle(theme.textSecondary)
                    Text("先到「设置 → 账本」新建一个")
                        .font(theme.type.caption)
                        .foregroundStyle(theme.textSecondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(selectable) { book in
                            Button {
                                onPick(book.id)
                                dismiss()
                            } label: {
                                HStack(spacing: 14) {
                                    Circle()
                                        .fill(book.isDefault ? theme.textSecondary : theme.accent)
                                        .frame(width: 8, height: 8)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(book.name)
                                            .font(theme.type.body)
                                            .foregroundStyle(theme.textPrimary)
                                        if book.isDefault {
                                            Text("DEFAULT")
                                                .font(theme.type.micro)
                                                .tracking(0.8)
                                                .foregroundStyle(theme.textSecondary)
                                        }
                                    }
                                    Spacer()
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(theme.textSecondary)
                                }
                                .padding(.horizontal, 24)
                                .padding(.vertical, 16)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            if book.id != selectable.last?.id {
                                Rectangle()
                                    .fill(theme.separator)
                                    .frame(height: 1)
                                    .padding(.horizontal, 24)
                            }
                        }
                    }
                    .padding(.top, 16)
                }
            }
        }
        .background(theme.bgPrimary)
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
    }
}
