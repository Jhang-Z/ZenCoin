import Foundation

enum ExpenseCategory: String, CaseIterable, Codable, Sendable, Identifiable {
    // Expense (12) — fits a 4×3 grid.
    case dining, transport, shopping, daily
    case fun, housing, medical, clothing
    case telecom, travel, education, other
    // Income (4) — fits a 4×1 grid.
    case salary, bonus, invest, otherIncome

    var id: String { rawValue }

    var isIncome: Bool {
        switch self {
        case .salary, .bonus, .invest, .otherIncome: return true
        default: return false
        }
    }

    static var expenseCases: [ExpenseCategory] {
        [
            .dining, .transport, .shopping, .daily,
            .fun, .housing, .medical, .clothing,
            .telecom, .travel, .education, .other,
        ]
    }

    static var incomeCases: [ExpenseCategory] {
        [.salary, .bonus, .invest, .otherIncome]
    }

    var displayName: String {
        switch self {
        case .dining:      return "餐饮"
        case .transport:   return "交通"
        case .shopping:    return "购物"
        case .daily:       return "日用"
        case .fun:         return "娱乐"
        case .housing:     return "住房"
        case .medical:     return "医疗"
        case .clothing:    return "服饰"
        case .telecom:     return "通讯"
        case .travel:      return "旅行"
        case .education:   return "教育"
        case .other:       return "其他"
        case .salary:      return "工资"
        case .bonus:       return "奖金"
        case .invest:      return "理财"
        case .otherIncome: return "其他收入"
        }
    }

    /// SF Symbol — monochrome by design.
    var iconName: String {
        switch self {
        case .dining:      return "fork.knife"
        case .transport:   return "tram.fill"
        case .shopping:    return "bag"
        case .daily:       return "cart"
        case .fun:         return "music.note"
        case .housing:     return "house"
        case .medical:     return "cross.case"
        case .clothing:    return "tshirt"
        case .telecom:     return "antenna.radiowaves.left.and.right"
        case .travel:      return "airplane"
        case .education:   return "book"
        case .other:       return "circle.grid.2x2"
        case .salary:      return "banknote"
        case .bonus:       return "gift"
        case .invest:      return "chart.line.uptrend.xyaxis"
        case .otherIncome: return "arrow.down.circle"
        }
    }
}
