import SwiftUI

struct CategoryPickerView: View {
    @Environment(\.theme) private var theme
    let isIncome: Bool
    @Binding var selected: ExpenseCategory

    private var categories: [ExpenseCategory] {
        isIncome ? ExpenseCategory.incomeCases : ExpenseCategory.expenseCases
    }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 14) {
            ForEach(categories) { cat in
                Button {
                    selected = cat
                    UISelectionFeedbackGenerator().selectionChanged()
                } label: {
                    cell(cat)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 24)
    }

    private func cell(_ cat: ExpenseCategory) -> some View {
        let isSelected = cat == selected
        return VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(isSelected ? theme.accent : theme.bgSurface)
                    .frame(width: 44, height: 44)
                Image(systemName: cat.iconName)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(isSelected ? theme.bgPrimary : theme.textPrimary)
            }
            Text(cat.displayName)
                .font(theme.type.micro)
                .foregroundStyle(isSelected ? theme.textPrimary : theme.textSecondary)
                .lineLimit(1)
        }
    }
}
