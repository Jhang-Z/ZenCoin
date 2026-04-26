import SwiftUI

@Observable
final class ThemeManager {
    private static let storageKey = "selectedTheme"

    var currentID: ThemeID {
        didSet {
            UserDefaults.standard.set(currentID.rawValue, forKey: Self.storageKey)
        }
    }

    var tokens: ThemeTokens { ThemeTokens.preset(for: currentID) }

    init() {
        let stored = UserDefaults.standard.string(forKey: Self.storageKey)
        self.currentID = stored.flatMap(ThemeID.init(rawValue:)) ?? .claude
    }

    func switchTo(_ id: ThemeID) { currentID = id }
}

private struct ThemeManagerKey: EnvironmentKey {
    static let defaultValue = ThemeManager()
}

private struct ThemeKey: EnvironmentKey {
    static let defaultValue: ThemeTokens = .claude
}

extension EnvironmentValues {
    var themeManager: ThemeManager {
        get { self[ThemeManagerKey.self] }
        set { self[ThemeManagerKey.self] = newValue }
    }
    var theme: ThemeTokens {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}
