import Foundation
import UserNotifications

final class NotificationManager: Notifying {
    private let logger: Logging

    private var isAvailable: Bool {
        return Bundle.main.bundleIdentifier != nil
    }

    private var permissionGranted = false

    init(logger: Logging) {
        self.logger = logger
    }

    func requestPermission() {
        guard isAvailable else {
            logger.info("No app bundle — using console output only")
            return
        }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { [weak self] granted, _ in
            self?.permissionGranted = granted
            if granted {
                self?.logger.info("Permission granted")
            } else {
                self?.logger.info("Permission not granted (normal for unsigned app)")
            }
        }
    }

    func send(title: String, body: String) {
        logger.info("[\(title)] \(body)")

        guard isAvailable, permissionGranted else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { _ in }
    }
}
