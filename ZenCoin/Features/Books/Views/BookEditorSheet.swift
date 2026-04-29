import SwiftUI
import UIKit

/// 新建 / 重命名账本的输入 sheet。
/// 同时被「设置 → 账本」管理页与首页 BookSwitchSheet 复用。
struct BookEditorSheet: View {
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss

    let title: String
    let initialName: String
    /// 是否在保存后自动收起本 sheet。
    /// - 设为 `false`：调用方在 `onCommit` 闭包里自行处理收起（一般是收起更外层的父 sheet，
    ///   让 iOS 把整个 sheet 栈一次性合掉，避免「先收 editor、再收父 sheet」两段动画）。
    let dismissesOnCommit: Bool
    let onCommit: (String) -> Void

    @State private var name: String = ""

    init(
        title: String,
        initialName: String,
        dismissesOnCommit: Bool = true,
        onCommit: @escaping (String) -> Void
    ) {
        self.title = title
        self.initialName = initialName
        self.dismissesOnCommit = dismissesOnCommit
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

            AutoFocusTextField(
                text: $name,
                placeholder: "账本名称",
                textColor: UIColor(theme.textPrimary),
                placeholderColor: UIColor(theme.textSecondary.opacity(0.6)),
                onSubmit: { commit() }
            )
            .frame(height: 24)
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: theme.radiusSmall)
                    .fill(theme.bgSurface)
            )

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
        .dismissKeyboardOnBackgroundTap()
        .background(theme.bgPrimary)
        .presentationDetents([.height(280)])
        .presentationDragIndicator(.hidden)
    }

    private func commit() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        onCommit(trimmed)
        if dismissesOnCommit {
            dismiss()
        }
    }
}

// MARK: - AutoFocusTextField

/// `UITextField` 包装，专门解决 SwiftUI `@FocusState` 在 sheet 中的滞后：
/// `becomeFirstResponder()` 在 `makeUIView` 同步触发，让键盘和 sheet 一起升起，
/// 而不是 sheet 落定之后键盘再单独冒上来。
private struct AutoFocusTextField: UIViewRepresentable {
    @Binding var text: String
    let placeholder: String
    let textColor: UIColor
    let placeholderColor: UIColor
    let onSubmit: () -> Void

    func makeUIView(context: Context) -> UITextField {
        let field = UITextField()
        field.text = text
        field.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: placeholderColor]
        )
        field.textColor = textColor
        field.font = .preferredFont(forTextStyle: .body)
        field.adjustsFontForContentSizeCategory = true
        field.returnKeyType = .done
        field.autocorrectionType = .no
        field.delegate = context.coordinator
        field.addTarget(context.coordinator,
                        action: #selector(Coordinator.editingChanged(_:)),
                        for: .editingChanged)
        // 同步置为 first responder：iOS 会把键盘升起合并进 sheet 的呈现动画。
        field.becomeFirstResponder()
        return field
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: AutoFocusTextField
        init(_ parent: AutoFocusTextField) { self.parent = parent }

        @objc func editingChanged(_ textField: UITextField) {
            parent.text = textField.text ?? ""
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            parent.onSubmit()
            return false
        }
    }
}
