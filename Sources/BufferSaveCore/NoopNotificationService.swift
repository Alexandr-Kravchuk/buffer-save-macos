import Foundation

public final class NoopNotificationService: NotificationScheduling {
    public init() {
    }

    public func requestAuthorization() {
    }

    public func notifySuccess(fileName: String) {
    }

    public func notifyWarning(message: String) {
    }

    public func notifyError(message: String) {
    }
}
