import Foundation
import Observation

@Observable
@MainActor
final class LedgerSelectionStore {
    var isActive: Bool = false
    var ids: Set<UUID> = []

    func enter(with id: UUID) {
        isActive = true
        ids.insert(id)
    }

    func toggle(_ id: UUID) {
        if ids.contains(id) {
            ids.remove(id)
            if ids.isEmpty { exit() }
        } else {
            ids.insert(id)
        }
    }

    func exit() {
        isActive = false
        ids.removeAll()
    }
}
