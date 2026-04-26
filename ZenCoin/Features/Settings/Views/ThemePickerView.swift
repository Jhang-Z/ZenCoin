import SwiftUI

struct ThemePickerView: View {
    @Environment(\.theme) private var theme
    @Environment(\.themeManager) private var themeManager

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(ThemeID.allCases) { id in
                    let preview = ThemeTokens.preset(for: id)
                    Button {
                        themeManager.switchTo(id)
                    } label: {
                        cell(id: id, preview: preview)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(24)
        }
        .background(theme.bgPrimary.ignoresSafeArea())
        .navigationTitle("主题")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func cell(id: ThemeID, preview: ThemeTokens) -> some View {
        let isSelected = themeManager.currentID == id
        return HStack(spacing: 16) {
            // Live swatch in the theme's own colors
            HStack(spacing: 0) {
                preview.bgPrimary
                preview.bgSurface
                preview.accent
            }
            .frame(width: 72, height: 72)
            .clipShape(RoundedRectangle(cornerRadius: preview.radiusSmall))
            .overlay(
                RoundedRectangle(cornerRadius: preview.radiusSmall)
                    .stroke(preview.separator, lineWidth: 1)
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(id.displayName)
                    .font(.system(size: 17, weight: .semibold, design: preview.fontDesign))
                    .foregroundStyle(theme.textPrimary)
                Text(id.caption)
                    .font(theme.type.caption)
                    .foregroundStyle(theme.textSecondary)
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(theme.accent)
            } else {
                Image(systemName: "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(theme.separator)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: theme.radiusMedium)
                .fill(theme.bgSurface)
        )
    }
}
