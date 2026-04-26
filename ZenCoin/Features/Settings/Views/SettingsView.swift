import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.theme) private var theme
    @Environment(\.themeManager) private var themeManager
    @Environment(\.modelContext) private var modelContext
    @Environment(\.bookStore) private var bookStore
    @Environment(\.dismiss) private var dismiss

    @State private var currency: CurrencySymbol = CurrencyFormatter.symbol
    @State private var confirmingErase = false
    @State private var aiKeyService = BailianKeyService.shared
    @State private var aiKeyDraft: String = ""
    @State private var showingAIKeyEditor = false
    @FocusState private var aiKeyFieldFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                section(title: "BOOKS / 账本") {
                    NavigationLink {
                        BookManagementView()
                    } label: {
                        rowChrome {
                            HStack {
                                Text("管理账本")
                                    .font(theme.type.body)
                                    .foregroundStyle(theme.textPrimary)
                                Spacer()
                                Text(bookStore?.currentBook?.name ?? Book.defaultName)
                                    .font(theme.type.body)
                                    .foregroundStyle(theme.textSecondary)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(theme.textSecondary)
                            }
                        }
                    }
                }

                section(title: "APPEARANCE / 外观") {
                    NavigationLink {
                        ThemePickerView()
                    } label: {
                        rowChrome {
                            HStack {
                                Text("主题")
                                    .font(theme.type.body)
                                    .foregroundStyle(theme.textPrimary)
                                Spacer()
                                Text(themeManager.currentID.displayName)
                                    .font(theme.type.body)
                                    .foregroundStyle(theme.textSecondary)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(theme.textSecondary)
                            }
                        }
                    }
                }

                section(title: "CURRENCY / 货币") {
                    HStack(spacing: 8) {
                        ForEach(CurrencySymbol.allCases) { sym in
                            Button {
                                currency = sym
                                CurrencyFormatter.symbol = sym
                            } label: {
                                Text(sym.rawValue)
                                    .font(.system(size: 18, weight: .medium, design: theme.fontDesign))
                                    .foregroundStyle(currency == sym ? theme.bgPrimary : theme.textPrimary)
                                    .frame(maxWidth: .infinity, minHeight: 44)
                                    .background(
                                        RoundedRectangle(cornerRadius: theme.radiusSmall)
                                            .fill(currency == sym ? theme.accent : theme.bgSurface)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                section(title: "AI / 智能记账") {
                    Button {
                        aiKeyDraft = aiKeyService.apiKey() ?? ""
                        showingAIKeyEditor = true
                    } label: {
                        rowChrome {
                            HStack {
                                Text("百炼 API Key")
                                    .font(theme.type.body)
                                    .foregroundStyle(theme.textPrimary)
                                Spacer()
                                Text(aiKeyService.hasAPIKey ? "已配置" : "未配置")
                                    .font(theme.type.body)
                                    .foregroundStyle(aiKeyService.hasAPIKey ? theme.accent : theme.textSecondary)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(theme.textSecondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    Button {
                        ShortcutInstallerService.install()
                    } label: {
                        rowChrome {
                            HStack {
                                Text("安装快捷指令")
                                    .font(theme.type.body)
                                    .foregroundStyle(theme.textPrimary)
                                Spacer()
                                Text(ShortcutInstallerService.hasICloudLink ? "一键导入" : "打开「快捷指令」")
                                    .font(theme.type.body)
                                    .foregroundStyle(theme.textSecondary)
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(theme.textSecondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    Text("触发方式：iOS 快捷指令（截屏 → AI 截图记账）。建议绑定到背面双击，全程在后台静默完成。")
                        .font(theme.type.caption)
                        .foregroundStyle(theme.textSecondary)
                        .padding(.horizontal, 4)
                        .padding(.top, 4)
                }

                section(title: "DATA / 数据") {
                    Button {
                        confirmingErase = true
                    } label: {
                        rowChrome {
                            HStack {
                                Text("清空当前账本记录")
                                    .font(theme.type.body)
                                    .foregroundStyle(theme.error)
                                Spacer()
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .zenConfirm(
                        isPresented: $confirmingErase,
                        kind: .destructive,
                        title: "清空所有记录？",
                        message: "此操作无法撤销。",
                        confirmLabel: "清空"
                    ) {
                        let bid = bookStore?.currentBookId ?? Book.defaultID
                        try? ExpenseDataService(modelContext: modelContext).deleteAll(bookId: bid)
                    }
                }

                section(title: "ABOUT / 关于") {
                    rowChrome {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("ZenCoin · v1.0")
                                .font(theme.type.body)
                                .foregroundStyle(theme.textPrimary)
                            Text("安静记账 · Quietly counting")
                                .font(theme.type.caption)
                                .foregroundStyle(theme.textSecondary)
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 64)
        }
        .background(theme.bgPrimary.ignoresSafeArea())
        .navigationTitle("设置")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("完成") { dismiss() }
                    .foregroundStyle(theme.accent)
            }
        }
        .sheet(isPresented: $showingAIKeyEditor) {
            aiKeyEditor
                .presentationDetents([.height(320)])
                .presentationBackground(theme.bgPrimary)
        }
    }

    @ViewBuilder
    private func section<C: View>(title: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(theme.type.micro)
                .tracking(0.8)
                .foregroundStyle(theme.textSecondary)
            content()
        }
    }

    @ViewBuilder
    private func rowChrome<C: View>(@ViewBuilder _ content: () -> C) -> some View {
        content()
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: theme.radiusSmall)
                    .fill(theme.bgSurface)
            )
    }

    // MARK: - AI key editor

    private var aiKeyEditor: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("BAILIAN API KEY")
                    .font(theme.type.micro)
                    .tracking(0.8)
                    .foregroundStyle(theme.textSecondary)
                Spacer()
                Button {
                    showingAIKeyEditor = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(theme.textSecondary)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(theme.bgSurface))
                }
            }

            SecureField("sk-…", text: $aiKeyDraft)
                .font(theme.type.body)
                .foregroundStyle(theme.textPrimary)
                .focused($aiKeyFieldFocused)
                .submitLabel(.done)
                .onSubmit { aiKeyFieldFocused = false }
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: theme.radiusSmall)
                        .fill(theme.bgSurface)
                )
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            HStack(spacing: 10) {
                if aiKeyService.hasAPIKey {
                    Button {
                        aiKeyService.remove()
                        aiKeyDraft = ""
                    } label: {
                        Text("清除")
                            .font(theme.type.body)
                            .foregroundStyle(theme.error)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(
                                RoundedRectangle(cornerRadius: theme.radiusSmall)
                                    .stroke(theme.separator, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
                Button {
                    aiKeyService.save(apiKey: aiKeyDraft)
                    showingAIKeyEditor = false
                } label: {
                    Text("保存")
                        .font(theme.type.body.weight(.semibold))
                        .foregroundStyle(theme.bgPrimary)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(
                            RoundedRectangle(cornerRadius: theme.radiusSmall)
                                .fill(theme.accent)
                        )
                }
                .buttonStyle(.plain)
                .disabled(aiKeyDraft.trimmingCharacters(in: .whitespaces).isEmpty)
                .opacity(aiKeyDraft.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .dismissKeyboardOnBackgroundTap()
    }
}
