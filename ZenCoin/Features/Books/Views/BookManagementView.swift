import SwiftUI

/// 账本管理页 — 设置 → 账本入口。新建 / 重命名 / 删除。
struct BookManagementView: View {
    @Environment(\.theme) private var theme
    @Environment(\.bookStore) private var bookStore
    @Environment(\.dismiss) private var dismiss

    @State private var showingCreateSheet = false
    @State private var renameTarget: Book?
    @State private var deleteTarget: Book?
    @State private var deleteMigrate: Bool = true
    @State private var confirmingDelete = false

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

                Text("主账本不可删除、不可重命名。删除其他账本时，可选择把记录迁移到主账本，或一并清空。")
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
            BookEditorSheet(
                title: "新建账本",
                initialName: ""
            ) { name in
                _ = bookStore?.create(name: name)
            }
            .presentationBackground(theme.bgPrimary)
        }
        .sheet(item: $renameTarget) { book in
            BookEditorSheet(
                title: "重命名",
                initialName: book.name
            ) { name in
                bookStore?.rename(book, to: name)
            }
            .presentationBackground(theme.bgPrimary)
        }
        .zenConfirm(
            isPresented: $confirmingDelete,
            kind: .destructive,
            title: deleteTitleText,
            message: deleteMessageText,
            confirmLabel: deleteMigrate ? "迁移并删除账本" : "全部清空"
        ) {
            if let target = deleteTarget {
                bookStore?.delete(target, migrateExpensesToDefault: deleteMigrate)
            }
            deleteTarget = nil
        }
    }

    private var deleteTitleText: String {
        guard let t = deleteTarget else { return "" }
        return "删除账本「\(t.name)」？"
    }

    private var deleteMessageText: String {
        deleteMigrate
            ? "把这个账本下的所有记录迁移到主账本，然后删除账本本身。"
            : "把这个账本和它下的所有记录一并删除。此操作无法撤销。"
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
                Menu {
                    Button {
                        renameTarget = book
                    } label: {
                        Label("重命名", systemImage: "pencil")
                    }
                    Section {
                        Button {
                            deleteTarget = book
                            deleteMigrate = true
                            confirmingDelete = true
                        } label: {
                            Label("删除（迁移记录）", systemImage: "arrow.right.doc.on.clipboard")
                        }
                        Button(role: .destructive) {
                            deleteTarget = book
                            deleteMigrate = false
                            confirmingDelete = true
                        } label: {
                            Label("删除（含记录）", systemImage: "trash")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(theme.textSecondary)
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }
}

// MARK: - Editor sheet (create / rename)

private struct BookEditorSheet: View {
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss

    let title: String
    let initialName: String
    let onCommit: (String) -> Void

    @State private var name: String = ""
    @FocusState private var nameFocused: Bool

    init(title: String, initialName: String, onCommit: @escaping (String) -> Void) {
        self.title = title
        self.initialName = initialName
        self.onCommit = onCommit
        _name = State(initialValue: initialName)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(title.uppercased() + " / " + title)
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

            TextField("账本名称", text: $name)
                .font(theme.type.body)
                .foregroundStyle(theme.textPrimary)
                .focused($nameFocused)
                .submitLabel(.done)
                .onSubmit { commit() }
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: theme.radiusSmall)
                        .fill(theme.bgSurface)
                )
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("完成") { nameFocused = false }
                            .foregroundStyle(theme.accent)
                    }
                }

            Button {
                commit()
            } label: {
                Text("保存")
                    .font(theme.type.body.weight(.semibold))
                    .foregroundStyle(theme.bgPrimary)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(
                        RoundedRectangle(cornerRadius: theme.radiusSmall)
                            .fill(theme.accent)
                    )
            }
            .buttonStyle(.plain)
            .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            .opacity(name.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .background(theme.bgPrimary)
        .presentationDetents([.height(280)])
        .presentationDragIndicator(.hidden)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { nameFocused = true }
        }
    }

    private func commit() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        onCommit(trimmed)
        dismiss()
    }
}
