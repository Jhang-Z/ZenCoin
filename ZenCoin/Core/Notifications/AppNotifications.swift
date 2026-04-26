import Foundation

extension Notification.Name {
    /// Posted whenever the expense store changes (insert / update / delete).
    /// Carries no payload — listeners just reload.
    static let expenseStoreDidChange = Notification.Name("expenseStoreDidChange")

    /// Posted when the user switches the active Book.
    static let currentBookDidChange = Notification.Name("currentBookDidChange")
}
