import SwiftUI
import SwiftData

/// 账本管理页 — 设置 → 账本入口。新建 / 重命名 / 删除。
struct BookManagementView: View {
    @Environment(\.theme) private var theme
    @Environment(\.bookStore) private var bookStore
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var showingCreateSheet = false
    @State private var actionsTarget: Book?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("LEDGERS / 账本列表")
                    .font(theme.type.micro)
                    .tracking(0.8)
                    .foregroundStyle(theme.textSecondary)

                VStack(spacing: 0) {
                    ForEach(bookStore?.books ?? []) { book in
                        bookRow(book)
                        if book.id != bookStore?.books.last?.id {
                            Rectangle().fill(theme.separator).frame(height: 1).padding(.horizontal, 16)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: theme.radiusMedium)
                        .fill(theme.bgSurface)
                )

                Button {
                    showingCreateSheet = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .medium))
                        Text("新建账本")
                            .font(theme.type.body)
                    }
                    .foregroundStyle(theme.bgPrimary)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(
                        RoundedRectangle(cornerRadius: theme.radiusSmall)
                            .fill(theme.accent)
                    )
                }
                .buttonStyle(.plain)
                .padding(.top, 8)

                Text("主账本不可删除、不可重命名 —— 它是「全账本视图」，会汇总你所有账本里的记录。从其他账本删除时，记录默认会保留在主账本里。")
                    .font(theme.type.caption)
                    .foregroundStyle(theme.textSecondary)
                    .padding(.horizontal, 4)
                    .padding(.top, 4)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 64)
        }
        .background(theme.bgPrimary.ignoresSafeArea())
        .navigationTitle("账本")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingCreateSheet) {
            BookEditorSheet(title: "新建账本", initialName: "") { name in
                _ = bookStore?.create(name: name)
            }
            .presentationBackground(theme.bgPrimary)
        }
        .sheet(item: $actionsTarget) { book in
            BookActionsSheet(
                book: book,
                recordCount: recordCount(for: book.id),
                onRenameCommit: { name in
                    bookStore?.rename(book, to: name)
                },
                onDeleteConfirm: { cascade in
                    bookStore?.delete(book, migrateExpensesToDefault: !cascade)
                }
            )
            .presentationBackground(theme.bgPrimary)
        }
    }

    /// 数一个账本下有多少条记录（给 BookDeleteSheet 用）。
    private func recordCount(for bookId: UUID) -> Int {
        let descriptor = FetchDescriptor<Expense>(
            predicate: #Predicate { $0.bookId == bookId }
        )
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    @ViewBuilder
    private func bookRow(_ book: Book) -> some View {
        HStack(spacing: 14) {
            Circle()
                .fill(book.id == bookStore?.currentBookId ? theme.accent : theme.bgInput)
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
            if !book.isDefault {
                Button {
                    actionsTarget = book
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(theme.textSecondary)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }
}

