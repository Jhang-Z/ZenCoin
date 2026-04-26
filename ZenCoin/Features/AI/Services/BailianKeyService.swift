import Foundation
import Observation

@Observable
@MainActor
final class BailianKeyService {
    static let shared = BailianKeyService()

    private let keychainKey = "bailian_api_key"
    var hasAPIKey: Bool = false

    init() {
        hasAPIKey = KeychainService.load(forKey: keychainKey) != nil
    }

    func save(apiKey: String) {
        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        KeychainService.save(trimmed, forKey: keychainKey)
        hasAPIKey = true
    }

    func apiKey() -> String? {
        KeychainService.load(forKey: keychainKey)
    }

    func remove() {
        KeychainService.delete(forKey: keychainKey)
        hasAPIKey = false
    }
}
