import SwiftUI

/// 账本切换 sheet。列出所有账本（主账本顶 sticky），点击即切换并 dismiss。
/// 底部一行「+ 新建账本」直接弹出新建账本输入框，跟「设置 → 账本」里走的是同一条路径。
struct BookSwitchSheet: View {
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss

    let books: [Book]
    let currentBookId: UUID
    let onPick: (UUID) -> Void
    /// 父层负责实际创建账本（拿到 BookStore），并切到新账本。
    let onCreate: (String) -> Void

    @State private var showingCreateBook = false

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
                showingCreateBook = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .medium))
                    Text("新建账本")
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
        .sheet(isPresented: $showingCreateBook) {
            // dismissesOnCommit: false —— 由本层 BookSwitchSheet 的 dismiss() 一次性
            // 把 editor + 自身一起收起，避免「先收 editor、再回到切换页、再收切换页」
            // 那种两段式动画。
            BookEditorSheet(title: "新建账本", initialName: "", dismissesOnCommit: false) { name in
                onCreate(name)
                dismiss()
            }
            .presentationBackground(theme.bgPrimary)
        }
    }
}
