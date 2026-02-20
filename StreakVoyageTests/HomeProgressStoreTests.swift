import Foundation
import Testing
@testable import StreakVoyage

@MainActor
struct HomeProgressStoreTests {
    @Test
    func loadReturnsNilWhenNoSnapshotExists() {
        let (defaults, suiteName) = makeIsolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = UserDefaultsDashboardProgressStore(defaults: defaults)

        #expect(store.load() == nil)
    }

    @Test
    func saveAndLoadRoundTripsSnapshot() {
        let (defaults, suiteName) = makeIsolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = UserDefaultsDashboardProgressStore(defaults: defaults)
        let snapshot = DashboardProgressSnapshot(
            totalWorkouts: 4,
            totalXP: 200,
            currentStreak: 2,
            longestStreak: 3,
            lastWorkoutAt: makeDate("2026-02-19T10:00:00Z"),
            dailyCompletedDate: makeDate("2026-02-19T10:00:00Z"),
            dailyCompletedWorkoutIDs: ["squats", "pushups"]
        )

        store.save(snapshot)

        #expect(store.load() == snapshot)
    }

    @Test
    func snapshotKeysAreIsolatedWithinSameDefaultsSuite() {
        let (defaults, suiteName) = makeIsolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let firstStore = UserDefaultsDashboardProgressStore(
            defaults: defaults,
            snapshotKey: "dashboardProgressSnapshot.first"
        )
        let secondStore = UserDefaultsDashboardProgressStore(
            defaults: defaults,
            snapshotKey: "dashboardProgressSnapshot.second"
        )

        let firstSnapshot = DashboardProgressSnapshot(totalWorkouts: 1, totalXP: 50, currentStreak: 1)
        let secondSnapshot = DashboardProgressSnapshot(totalWorkouts: 9, totalXP: 450, currentStreak: 4)

        firstStore.save(firstSnapshot)
        secondStore.save(secondSnapshot)

        #expect(firstStore.load() == firstSnapshot)
        #expect(secondStore.load() == secondSnapshot)
    }

    @Test
    func reminderSettingsSaveAndLoadRoundTrip() {
        let (defaults, suiteName) = makeIsolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = UserDefaultsReminderSettingsStore(defaults: defaults)
        let snapshot = ReminderSettingsSnapshot(
            isEnabled: true,
            hour: 7,
            minute: 45
        )

        store.save(snapshot)

        #expect(store.load() == snapshot)
    }

    @Test
    func reminderSettingsKeysAreIsolatedWithinSameDefaultsSuite() {
        let (defaults, suiteName) = makeIsolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let firstStore = UserDefaultsReminderSettingsStore(
            defaults: defaults,
            snapshotKey: "dailyReminderSettingsSnapshot.first"
        )
        let secondStore = UserDefaultsReminderSettingsStore(
            defaults: defaults,
            snapshotKey: "dailyReminderSettingsSnapshot.second"
        )

        firstStore.save(ReminderSettingsSnapshot(isEnabled: false, hour: 20, minute: 0))
        secondStore.save(ReminderSettingsSnapshot(isEnabled: true, hour: 6, minute: 30))

        #expect(firstStore.load() == ReminderSettingsSnapshot(isEnabled: false, hour: 20, minute: 0))
        #expect(secondStore.load() == ReminderSettingsSnapshot(isEnabled: true, hour: 6, minute: 30))
    }

    private func makeIsolatedDefaults() -> (UserDefaults, String) {
        let suiteName = "HomeProgressStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return (defaults, suiteName)
    }

    private func makeDate(_ raw: String) -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: raw)!
    }
}
