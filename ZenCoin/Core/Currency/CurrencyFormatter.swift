import Foundation

enum CurrencySymbol: String, CaseIterable, Identifiable {
    case yuan = "¥"
    case dollar = "$"
    case euro = "€"

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .yuan: return "CNY (¥)"
        case .dollar: return "USD ($)"
        case .euro: return "EUR (€)"
        }
    }
}

enum CurrencyFormatter {
    private static let storageKey = "currencySymbol"

    static var symbol: CurrencySymbol {
        get {
            let raw = UserDefaults.standard.string(forKey: storageKey) ?? CurrencySymbol.yuan.rawValue
            return CurrencySymbol(rawValue: raw) ?? .yuan
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: storageKey)
        }
    }

    static func format(_ amount: Double, signed: Bool = false, isIncome: Bool = false) -> String {
        let abs = String(format: "%.2f", amount)
        let body = "\(symbol.rawValue)\(abs)"
        guard signed else { return body }
        return isIncome ? "+\(body)" : "−\(body)"
    }
}
