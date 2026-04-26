import SwiftUI

/// Zen 风格的确认弹窗 — 取代系统 confirmationDialog（系统弹窗在视觉上与本 app 的 zen 设计语言不兼容：
/// 圆角灰色块、强制居中、字体不可控）。
///
/// 视觉要素遵循 DESIGN.md：
/// - bgPrimary 背景（与 app 同体）
/// - 顶部 micro caps 结构标签（DELETE / CONFIRM）
/// - 中部中文 title + 可选 message（caption / textSecondary）
/// - 底部双按钮：Cancel（textSecondary on bgInput） + Confirm（destructive: error 描边无填充 / 否则 accent 填充）
struct ZenConfirmDialog: View {
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss

    let kind: Kind
    let title: String
    let message: String?
    let confirmLabel: String
    let cancelLabel: String
    let onConfirm: () -> Void

    enum Kind {
        case destructive
        case neutral

        var capsLabel: String {
            switch self {
            case .destructive: return "DELETE / 删除"
            case .neutral:     return "CONFIRM / 确认"
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(kind.capsLabel)
                .font(theme.type.micro)
                .tracking(0.8)
                .foregroundStyle(theme.textSecondary)

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(theme.type.heading)
                    .foregroundStyle(theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                if let message {
                    Text(message)
                        .font(theme.type.caption)
                        .foregroundStyle(theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 0)

            HStack(spacing: 10) {
                Button {
                    dismiss()
                } label: {
                    Text(cancelLabel)
                        .font(theme.type.body)
                        .foregroundStyle(theme.textSecondary)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(
                            RoundedRectangle(cornerRadius: theme.radiusSmall)
                                .fill(theme.bgInput)
                        )
                }
                .buttonStyle(.plain)

                Button {
                    onConfirm()
                    dismiss()
                } label: {
                    confirmLabelView
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(confirmBackground)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 28)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.bgPrimary.ignoresSafeArea())
    }

    @ViewBuilder
    private var confirmLabelView: some View {
        switch kind {
        case .destructive:
            Text(confirmLabel)
                .font(theme.type.body.weight(.semibold))
                .foregroundStyle(theme.error)
        case .neutral:
            Text(confirmLabel)
                .font(theme.type.body.weight(.semibold))
                .foregroundStyle(theme.bgPrimary)
        }
    }

    @ViewBuilder
    private var confirmBackground: some View {
        switch kind {
        case .destructive:
            RoundedRectangle(cornerRadius: theme.radiusSmall)
                .stroke(theme.error.opacity(0.45), lineWidth: 1)
        case .neutral:
            RoundedRectangle(cornerRadius: theme.radiusSmall)
                .fill(theme.accent)
        }
    }
}

// MARK: - View modifier

extension View {
    /// 用本 app 的 zen 设计语言显示一个底部确认弹窗。
    func zenConfirm(
        isPresented: Binding<Bool>,
        kind: ZenConfirmDialog.Kind = .destructive,
        title: String,
        message: String? = nil,
        confirmLabel: String,
        cancelLabel: String = "取消",
        onConfirm: @escaping () -> Void
    ) -> some View {
        modifier(
            ZenConfirmModifier(
                isPresented: isPresented,
                kind: kind,
                title: title,
                message: message,
                confirmLabel: confirmLabel,
                cancelLabel: cancelLabel,
                onConfirm: onConfirm
            )
        )
    }
}

private struct ZenConfirmModifier: ViewModifier {
    @Environment(\.theme) private var theme

    @Binding var isPresented: Bool
    let kind: ZenConfirmDialog.Kind
    let title: String
    let message: String?
    let confirmLabel: String
    let cancelLabel: String
    let onConfirm: () -> Void

    func body(content: Content) -> some View {
        content.sheet(isPresented: $isPresented) {
            ZenConfirmDialog(
                kind: kind,
                title: title,
                message: message,
                confirmLabel: confirmLabel,
                cancelLabel: cancelLabel,
                onConfirm: onConfirm
            )
            .presentationDetents([.height(detentHeight)])
            .presentationDragIndicator(.hidden)
            .presentationBackground(theme.bgPrimary)
        }
    }

    private var detentHeight: CGFloat {
        message == nil ? 220 : 260
    }
}
