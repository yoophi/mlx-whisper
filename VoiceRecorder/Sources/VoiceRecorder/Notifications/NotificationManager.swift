import Foundation
import UserNotifications

final class NotificationManager {

    private var isAvailable: Bool {
        return Bundle.main.bundleIdentifier != nil
    }

    private var permissionGranted = false

    func requestPermission() {
        guard isAvailable else {
            print("[Notification] No app bundle — using console output only")
            return
        }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { [weak self] granted, _ in
            self?.permissionGranted = granted
            if granted {
                print("[Notification] Permission granted")
            } else {
                print("[Notification] Permission not granted (normal for unsigned app)")
            }
        }
    }

    func send(title: String, body: String) {
        print("📢 [\(title)] \(body)")

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
