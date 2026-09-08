import Foundation

/// One entry in the notification inbox behind Home's bell icon. `module` is
/// nil for app-level notices (e.g. a welcome message) that don't belong to
/// any one vertical.
struct AppNotification: Identifiable, Hashable {
    let id: UUID
    let module: ServiceModule?
    let icon: String
    let title: String
    let message: String
    let date: Date
    var isRead: Bool

    init(
        id: UUID = UUID(),
        module: ServiceModule?,
        icon: String,
        title: String,
        message: String,
        date: Date,
        isRead: Bool = false
    ) {
        self.id = id
        self.module = module
        self.icon = icon
        self.title = title
        self.message = message
        self.date = date
        self.isRead = isRead
    }
}
