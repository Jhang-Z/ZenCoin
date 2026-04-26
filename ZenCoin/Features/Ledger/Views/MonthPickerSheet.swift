import SwiftUI

struct MonthPickerSheet: View {
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss

    let initialYear: Int
    let initialMonth: Int
    let onPick: (Int, Int) -> Void

    @State private var year: Int

    init(initialYear: Int, initialMonth: Int, onPick: @escaping (Int, Int) -> Void) {
        self.initialYear = initialYear
        self.initialMonth = initialMonth
        self.onPick = onPick
        _year = State(initialValue: initialYear)
    }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)

    var body: some View {
        VStack(spacing: 0) {
            // Year strip
            HStack {
                Button {
                    year -= 1
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(theme.textSecondary)
                        .frame(width: 36, height: 36)
                }

                Spacer()

                Text(verbatim: "\(year)")
                    .font(.system(size: 22, weight: .medium, design: theme.fontDesign))
                    .tracking(theme.displayTracking * 0.4)
                    .foregroundStyle(theme.textPrimary)

                Spacer()

                Button {
                    year += 1
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(theme.textSecondary)
                        .frame(width: 36, height: 36)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 8)

            // Months grid
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(1...12, id: \.self) { m in
                    monthCell(m)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 24)

            Spacer(minLength: 0)
        }
        .background(theme.bgPrimary)
        .presentationDetents([.height(320)])
        .presentationDragIndicator(.visible)
    }

    private func monthCell(_ m: Int) -> some View {
        let isSelected = (year == initialYear && m == initialMonth)
        return Button {
            UISelectionFeedbackGenerator().selectionChanged()
            onPick(year, m)
            dismiss()
        } label: {
            Text(monthLabel(m))
                .font(.system(size: 15, weight: isSelected ? .semibold : .regular, design: theme.fontDesign))
                .foregroundStyle(isSelected ? theme.bgPrimary : theme.textPrimary)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(
                    RoundedRectangle(cornerRadius: theme.radiusSmall)
                        .fill(isSelected ? theme.accent : theme.bgSurface)
                )
        }
        .buttonStyle(.plain)
    }

    private func monthLabel(_ m: Int) -> String {
        "\(m) 月"
    }
}
