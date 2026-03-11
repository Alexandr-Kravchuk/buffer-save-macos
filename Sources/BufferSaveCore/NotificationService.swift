import Foundation
@preconcurrency import UserNotifications

public final class NotificationService: NotificationScheduling {
    let center: UNUserNotificationCenter
    var hasRequestedAuthorization = false

    public init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    public func requestAuthorization() {
        guard !hasRequestedAuthorization else {
            return
        }
        hasRequestedAuthorization = true
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in
        }
    }

    public func notifySuccess(fileName: String) {
        scheduleNotification(title: "Saved Clipboard", body: fileName)
    }

    public func notifyWarning(message: String) {
        scheduleNotification(title: "Buffer Save Permission", body: message)
    }

    public func notifyError(message: String) {
        scheduleNotification(title: "Buffer Save Error", body: message)
    }

    func scheduleNotification(title: String, body: String) {
        let center = center
        center.getNotificationSettings { settings in
            let status = settings.authorizationStatus
            guard status == .authorized || status == .provisional else {
                return
            }
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
            center.add(request) { _ in
            }
        }
    }
}
