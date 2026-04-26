import SwiftUI

/// 极简的年份选择 sheet。3×N 年份方格 + 步进。
struct YearPickerSheet: View {
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss

    let initialYear: Int
    let onPick: (Int) -> Void

    @State private var selectedYear: Int

    init(initialYear: Int, onPick: @escaping (Int) -> Void) {
        self.initialYear = initialYear
        self.onPick = onPick
        _selectedYear = State(initialValue: initialYear)
    }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    private var years: [Int] {
        let now = Calendar.current.component(.year, from: .now)
        // 显示当前年向前 9 年（共 9 个，3×3 网格）
        return (0..<9).map { now - $0 }.reversed()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("YEAR / 年份")
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

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(years, id: \.self) { y in
                    Button {
                        selectedYear = y
                        onPick(y)
                        dismiss()
                    } label: {
                        Text(String(y))
                            .font(.system(size: 17, weight: .medium, design: theme.fontDesign))
                            .foregroundStyle(y == selectedYear ? theme.bgPrimary : theme.textPrimary)
                            .frame(maxWidth: .infinity, minHeight: 56)
                            .background(
                                RoundedRectangle(cornerRadius: theme.radiusSmall)
                                    .fill(y == selectedYear ? theme.accent : theme.bgSurface)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)

            Spacer(minLength: 0)
        }
        .background(theme.bgPrimary)
        .presentationDetents([.height(340)])
        .presentationDragIndicator(.hidden)
    }
}
