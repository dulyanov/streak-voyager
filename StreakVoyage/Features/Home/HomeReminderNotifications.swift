import Foundation
import UserNotifications

struct ReminderSettingsSnapshot: Codable, Equatable {
    static let defaultHour = 20
    static let defaultMinute = 0

    var isEnabled: Bool = false
    var hour: Int = Self.defaultHour
    var minute: Int = Self.defaultMinute
}

protocol ReminderSettingsStoring {
    func load() -> ReminderSettingsSnapshot?
    func save(_ snapshot: ReminderSettingsSnapshot)
}

final class UserDefaultsReminderSettingsStore: ReminderSettingsStoring {
    private enum Keys {
        static let snapshot = "dailyReminderSettingsSnapshot"
    }

    private let defaults: UserDefaults
    private let snapshotKey: String
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard, snapshotKey: String = Keys.snapshot) {
        self.defaults = defaults
        self.snapshotKey = snapshotKey
    }

    func load() -> ReminderSettingsSnapshot? {
        guard let data = defaults.data(forKey: snapshotKey) else { return nil }
        return try? decoder.decode(ReminderSettingsSnapshot.self, from: data)
    }

    func save(_ snapshot: ReminderSettingsSnapshot) {
        guard let data = try? encoder.encode(snapshot) else { return }
        defaults.set(data, forKey: snapshotKey)
    }
}

enum ReminderPermissionStatus: String, Codable, Equatable {
    case notDetermined
    case denied
    case authorized

    var allowsScheduling: Bool {
        self == .authorized
    }
}

protocol DailyReminderScheduling {
    func authorizationStatus() async -> ReminderPermissionStatus
    func requestAuthorization() async -> Bool
    func scheduleDailyReminder(hour: Int, minute: Int) async throws
    func cancelDailyReminder() async
}

final class UserNotificationDailyReminderScheduler: DailyReminderScheduling {
    static let requestIdentifier = "streakvoyage.dailyWorkoutReminder"

    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func authorizationStatus() async -> ReminderPermissionStatus {
        let status = await withCheckedContinuation { continuation in
            center.getNotificationSettings { settings in
                continuation.resume(returning: settings.authorizationStatus)
            }
        }

        switch status {
        case .authorized, .provisional, .ephemeral:
            return .authorized
        case .denied:
            return .denied
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .denied
        }
    }

    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                continuation.resume(returning: granted)
            }
        }
    }

    func scheduleDailyReminder(hour: Int, minute: Int) async throws {
        center.removePendingNotificationRequests(withIdentifiers: [Self.requestIdentifier])

        let content = UNMutableNotificationContent()
        content.title = "Time to train"
        content.body = "Protect your streak with today's workout."
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: Self.requestIdentifier,
            content: content,
            trigger: trigger
        )

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            center.add(request) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    func cancelDailyReminder() async {
        center.removePendingNotificationRequests(withIdentifiers: [Self.requestIdentifier])
    }
}
