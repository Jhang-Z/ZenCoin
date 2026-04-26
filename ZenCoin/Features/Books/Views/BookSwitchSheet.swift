import SwiftUI

/// 账本切换 sheet。列出所有账本（主账本顶 sticky），点击即切换并 dismiss。
/// 底部一行「+ 新建账本」直接落到「设置 → 账本」管理页。
struct BookSwitchSheet: View {
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss

    let books: [Book]
    let currentBookId: UUID
    let onPick: (UUID) -> Void
    let onManage: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("BOOK / 账本")
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

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(books) { book in
                        Button {
                            onPick(book.id)
                            dismiss()
                        } label: {
                            HStack(spacing: 14) {
                                Circle()
                                    .fill(book.id == currentBookId ? theme.accent : theme.bgInput)
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
                                if book.id == currentBookId {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(theme.accent)
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 16)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if book.id != books.last?.id {
                            Rectangle()
                                .fill(theme.separator)
                                .frame(height: 1)
                                .padding(.horizontal, 24)
                        }
                    }
                }
                .padding(.top, 16)
            }

            Button {
                dismiss()
                // delay so the parent sheet finishes dismissing first
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onManage()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .medium))
                    Text("管理账本")
                        .font(theme.type.body)
                }
                .foregroundStyle(theme.textPrimary)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(
                    RoundedRectangle(cornerRadius: theme.radiusSmall)
                        .fill(theme.bgSurface)
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
        .background(theme.bgPrimary)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
    }
}
