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

    /// 进入选择模式并一次性勾选一组 id（dot strip 点击触发的"自动归桶"用）。
    /// 已经在选择模式时调用：把这组 id 替换为传入集合（更明确的"切换 scope"语义）。
    func enter(withGroup groupIds: [UUID]) {
        guard !groupIds.isEmpty else { return }
        isActive = true
        ids = Set(groupIds)
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
