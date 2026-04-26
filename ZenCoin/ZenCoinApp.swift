import SwiftUI
import SwiftData

@main
struct ZenCoinApp: App {
    let container: ModelContainer
    @State private var themeManager = ThemeManager()
    @State private var bookStore: BookStore

    init() {
        let c = Self.makeContainer()
        container = c
        _bookStore = State(initialValue: BookStore(modelContext: c.mainContext))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.themeManager, themeManager)
                .environment(\.theme, themeManager.tokens)
                .environment(\.bookStore, bookStore)
                .preferredColorScheme(themeManager.tokens.colorScheme)
                .tint(themeManager.tokens.accent)
        }
        .modelContainer(container)
    }

    private static func makeContainer() -> ModelContainer {
        let schema = Schema([Expense.self, Book.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        if let c = try? ModelContainer(for: schema, configurations: config) {
            return c
        }
        wipeStore()
        return try! ModelContainer(for: schema, configurations: config)
    }

    private static func wipeStore() {
        guard let support = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return }
        for name in ["default.store", "default.store-shm", "default.store-wal"] {
            try? FileManager.default.removeItem(at: support.appending(path: name))
        }
    }
}
