import SwiftUI

/// 账本管理页里点「⋯」时弹出的 zen 风格操作面板。
/// 替代 SwiftUI Menu —— 系统 Menu 的视觉跟 app 的设计语言冲突（圆角灰块、平台默认字体）。
///
/// 重命名 / 删除 用 child sheet 方式呈现，由本层 dismiss 一次性把整个栈收掉，
/// 避免「先收 actions、等 0.35s、再弹 delete/rename」的两段式延迟。
struct BookActionsSheet: View {
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss

    let book: Book
    let recordCount: Int
    let onRenameCommit: (String) -> Void
    let onDeleteConfirm: (_ cascadeRecords: Bool) -> Void

    @State private var showingRename = false
    @State private var showingDelete = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 头部 caps 标签 + ✕
            HStack {
                Text("BOOK · \(book.name)")
                    .font(theme.type.micro)
                    .tracking(0.8)
                    .foregroundStyle(theme.textSecondary)
                    .lineLimit(1)
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

            VStack(spacing: 0) {
                actionRow(
                    label: "重命名",
                    icon: "pencil",
                    tint: theme.textPrimary
                ) {
                    showingRename = true
                }
                Rectangle().fill(theme.separator).frame(height: 1).padding(.horizontal, 24)
                actionRow(
                    label: "删除账本…",
                    icon: "trash",
                    tint: theme.error
                ) {
                    showingDelete = true
                }
            }
            .padding(.top, 16)

            Spacer(minLength: 0)
        }
        .background(theme.bgPrimary)
        .presentationDetents([.height(220)])
        .presentationDragIndicator(.hidden)
        .sheet(isPresented: $showingRename) {
            BookEditorSheet(
                title: "重命名",
                initialName: book.name,
                dismissesOnCommit: false
            ) { name in
                onRenameCommit(name)
                dismiss() // collapse the whole stack in one animation
            }
            .presentationBackground(theme.bgPrimary)
        }
        .sheet(isPresented: $showingDelete) {
            BookDeleteSheet(
                book: book,
                recordCount: recordCount,
                dismissesOnConfirm: false
            ) { cascade in
                onDeleteConfirm(cascade)
                dismiss()
            }
            .presentationBackground(theme.bgPrimary)
        }
    }

    private func actionRow(label: String, icon: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(tint)
                    .frame(width: 20)
                Text(label)
                    .font(theme.type.body)
                    .foregroundStyle(tint)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(theme.textSecondary)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// 删除账本时的二段确认面板：让用户明确选「保留记录到主账本」还是「连记录一并删除」。
/// 因为主账本现在是「全账本视图」，所以「保留」= 那些记录依然在主账本可见。
struct BookDeleteSheet: View {
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss

    let book: Book
    let recordCount: Int
    /// 是否在确认后自动收起。`false` = 调用方在 `onConfirm` 闭包里自行处理收起
    /// （一般是收起更外层的父 sheet，让 iOS 一次性把 sheet 栈合掉）。
    let dismissesOnConfirm: Bool
    /// 用户选完后调用，参数是 `cascadeDeleteRecords`（true = 同时删记录）
    let onConfirm: (Bool) -> Void

    init(
        book: Book,
        recordCount: Int,
        dismissesOnConfirm: Bool = true,
        onConfirm: @escaping (Bool) -> Void
    ) {
        self.book = book
        self.recordCount = recordCount
        self.dismissesOnConfirm = dismissesOnConfirm
        self.onConfirm = onConfirm
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("DELETE / 删除")
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

            VStack(alignment: .leading, spacing: 8) {
                Text("删除账本「\(book.name)」？")
                    .font(theme.type.heading)
                    .foregroundStyle(theme.textPrimary)
                Text(recordCount > 0
                     ? "这本下有 \(recordCount) 条记录。主账本是全账本视图，所以保留时它们仍可见。"
                     : "这本是空的，可直接删除。")
                    .font(theme.type.caption)
                    .foregroundStyle(theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 24)
            .padding(.top, 18)

            VStack(spacing: 0) {
                actionRow(
                    label: "保留记录，仅删除账本",
                    sub: recordCount > 0 ? "\(recordCount) 条记录归到主账本" : nil,
                    icon: "tray.and.arrow.down",
                    tint: theme.textPrimary,
                    weight: .medium
                ) {
                    confirm(cascade: false)
                }
                Rectangle().fill(theme.separator).frame(height: 1).padding(.horizontal, 24)
                actionRow(
                    label: "全部删除（含记录）",
                    sub: recordCount > 0 ? "永久删除 \(recordCount) 条记录，无法恢复" : nil,
                    icon: "trash.fill",
                    tint: theme.error,
                    weight: .semibold
                ) {
                    confirm(cascade: true)
                }
            }
            .padding(.top, 18)

            Spacer(minLength: 0)
        }
        .background(theme.bgPrimary)
        .presentationDetents([.height(recordCount > 0 ? 340 : 290)])
        .presentationDragIndicator(.hidden)
    }

    private func actionRow(
        label: String,
        sub: String?,
        icon: String,
        tint: Color,
        weight: Font.Weight,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(tint)
                    .frame(width: 20)
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(theme.type.body.weight(weight))
                        .foregroundStyle(tint)
                    if let sub {
                        Text(sub)
                            .font(theme.type.caption)
                            .foregroundStyle(theme.textSecondary)
                            .lineLimit(2)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func confirm(cascade: Bool) {
        onConfirm(cascade)
        if dismissesOnConfirm {
            dismiss()
        }
    }
}
