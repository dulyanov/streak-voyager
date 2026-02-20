import Foundation
import Testing
@testable import StreakVoyage

@MainActor
struct HomeDashboardViewModelTests {
    @Test
    func firstWorkoutCompletionInitializesDailyProgressAndStreak() {
        let store = InMemoryProgressStore()
        let now = makeDate("2026-02-19T10:00:00Z")
        let viewModel = HomeDashboardViewModel(
            store: store,
            calendar: makeCalendarUTC(),
            nowProvider: { now }
        )

        viewModel.handleWorkoutCompletion(
            WorkoutCompletionEvent(workoutID: "squats", xpAwarded: 50, completedAt: now)
        )

        #expect(viewModel.totalWorkouts == 1)
        #expect(viewModel.totalXP == 50)
        #expect(viewModel.currentStreak == 1)
        #expect(viewModel.todayCompletedCount == 1)
        #expect(viewModel.isWorkoutCompletedToday("squats"))
        #expect(store.snapshot?.currentStreak == 1)
    }

    @Test
    func secondWorkoutSameDayDoesNotIncreaseStreak() {
        let store = InMemoryProgressStore()
        let now = makeDate("2026-02-19T10:00:00Z")
        let viewModel = HomeDashboardViewModel(
            store: store,
            calendar: makeCalendarUTC(),
            nowProvider: { now }
        )

        viewModel.handleWorkoutCompletion(
            WorkoutCompletionEvent(workoutID: "squats", xpAwarded: 50, completedAt: now)
        )
        viewModel.handleWorkoutCompletion(
            WorkoutCompletionEvent(workoutID: "pushups", xpAwarded: 50, completedAt: now)
        )

        #expect(viewModel.totalWorkouts == 2)
        #expect(viewModel.totalXP == 100)
        #expect(viewModel.currentStreak == 1)
        #expect(viewModel.todayCompletedCount == 2)
    }

    @Test
    func sameWorkoutTwiceInOneDayIsIgnored() {
        let store = InMemoryProgressStore()
        let now = makeDate("2026-02-19T10:00:00Z")
        let viewModel = HomeDashboardViewModel(
            store: store,
            calendar: makeCalendarUTC(),
            nowProvider: { now }
        )

        viewModel.handleWorkoutCompletion(
            WorkoutCompletionEvent(workoutID: "squats", xpAwarded: 50, completedAt: now)
        )
        viewModel.handleWorkoutCompletion(
            WorkoutCompletionEvent(workoutID: "squats", xpAwarded: 50, completedAt: now)
        )

        #expect(viewModel.totalWorkouts == 1)
        #expect(viewModel.totalXP == 50)
        #expect(viewModel.todayCompletedCount == 1)
    }

    @Test
    func consecutiveDayWorkoutIncreasesStreakAndResetsDailyCompletion() {
        let dayOne = makeDate("2026-02-19T10:00:00Z")
        let dayTwo = makeDate("2026-02-20T08:00:00Z")
        let seededSnapshot = DashboardProgressSnapshot(
            totalWorkouts: 1,
            totalXP: 50,
            currentStreak: 1,
            longestStreak: 1,
            lastWorkoutAt: dayOne,
            dailyCompletedDate: dayOne,
            dailyCompletedWorkoutIDs: ["squats"]
        )
        let store = InMemoryProgressStore(snapshot: seededSnapshot)
        let viewModel = HomeDashboardViewModel(
            store: store,
            calendar: makeCalendarUTC(),
            nowProvider: { dayTwo }
        )

        #expect(viewModel.todayCompletedCount == 0)
        #expect(viewModel.currentStreak == 1)

        viewModel.handleWorkoutCompletion(
            WorkoutCompletionEvent(workoutID: "pushups", xpAwarded: 50, completedAt: dayTwo)
        )

        #expect(viewModel.totalWorkouts == 2)
        #expect(viewModel.totalXP == 100)
        #expect(viewModel.currentStreak == 2)
        #expect(viewModel.todayCompletedCount == 1)
        #expect(viewModel.isWorkoutCompletedToday("pushups"))
    }

    @Test
    func missedDayResetsStreakOnLoad() {
        let dayOne = makeDate("2026-02-19T10:00:00Z")
        let dayFour = makeDate("2026-02-22T10:00:00Z")
        let seededSnapshot = DashboardProgressSnapshot(
            totalWorkouts: 3,
            totalXP: 150,
            currentStreak: 3,
            longestStreak: 3,
            lastWorkoutAt: dayOne,
            dailyCompletedDate: dayOne,
            dailyCompletedWorkoutIDs: ["squats", "pushups"]
        )
        let store = InMemoryProgressStore(snapshot: seededSnapshot)
        let viewModel = HomeDashboardViewModel(
            store: store,
            calendar: makeCalendarUTC(),
            nowProvider: { dayFour }
        )

        #expect(viewModel.currentStreak == 0)
        #expect(viewModel.totalWorkouts == 3)
        #expect(viewModel.totalXP == 150)
        #expect(viewModel.todayCompletedCount == 0)
        #expect(store.saveCallCount > 0)
    }

    @Test
    func refreshForCurrentDateResetsDailyCompletionWhenDayChanges() {
        let dayOne = makeDate("2026-02-19T10:00:00Z")
        var now = dayOne
        let store = InMemoryProgressStore(
            snapshot: DashboardProgressSnapshot(
                totalWorkouts: 3,
                totalXP: 150,
                currentStreak: 3,
                longestStreak: 3,
                lastWorkoutAt: dayOne,
                dailyCompletedDate: dayOne,
                dailyCompletedWorkoutIDs: ["squats", "pushups"]
            )
        )
        let viewModel = HomeDashboardViewModel(
            store: store,
            calendar: makeCalendarUTC(),
            nowProvider: { now }
        )

        #expect(viewModel.todayCompletedCount == 2)

        now = makeDate("2026-02-20T09:00:00Z")
        viewModel.refreshForCurrentDate()

        #expect(viewModel.todayCompletedCount == 0)
        #expect(store.snapshot?.dailyCompletedWorkoutIDs.isEmpty == true)
        #expect(store.snapshot?.dailyCompletedDate == now)
        #expect(store.saveCallCount > 0)
    }

    @Test
    func enablingReminderWhenAuthorizedSchedulesDailyNotification() async {
        let now = makeDate("2026-02-19T10:00:00Z")
        let reminderStore = InMemoryReminderSettingsStore()
        let reminderScheduler = FakeReminderScheduler(fallbackAuthorizationStatus: .authorized)
        let viewModel = HomeDashboardViewModel(
            store: InMemoryProgressStore(),
            reminderStore: reminderStore,
            reminderScheduler: reminderScheduler,
            calendar: makeCalendarUTC(),
            nowProvider: { now }
        )

        await viewModel.setReminderEnabled(true)

        #expect(viewModel.reminderEnabled)
        #expect(reminderStore.snapshot?.isEnabled == true)
        #expect(reminderScheduler.scheduleCalls.count == 1)
        #expect(reminderScheduler.scheduleCalls.first?.hour == ReminderSettingsSnapshot.defaultHour)
        #expect(reminderScheduler.scheduleCalls.first?.minute == ReminderSettingsSnapshot.defaultMinute)
    }

    @Test
    func enablingReminderRequestsPermissionWhenStatusIsNotDetermined() async {
        let now = makeDate("2026-02-19T10:00:00Z")
        let reminderStore = InMemoryReminderSettingsStore()
        let reminderScheduler = FakeReminderScheduler(
            authorizationStatuses: [.notDetermined, .authorized],
            fallbackAuthorizationStatus: .authorized,
            requestAuthorizationResult: true
        )
        let viewModel = HomeDashboardViewModel(
            store: InMemoryProgressStore(),
            reminderStore: reminderStore,
            reminderScheduler: reminderScheduler,
            calendar: makeCalendarUTC(),
            nowProvider: { now }
        )

        await viewModel.setReminderEnabled(true)

        #expect(viewModel.reminderEnabled)
        #expect(reminderScheduler.requestAuthorizationCallCount == 1)
        #expect(reminderScheduler.scheduleCalls.count == 1)
    }

    @Test
    func enablingReminderStaysOffWhenPermissionIsDenied() async {
        let now = makeDate("2026-02-19T10:00:00Z")
        let reminderStore = InMemoryReminderSettingsStore()
        let reminderScheduler = FakeReminderScheduler(fallbackAuthorizationStatus: .denied)
        let viewModel = HomeDashboardViewModel(
            store: InMemoryProgressStore(),
            reminderStore: reminderStore,
            reminderScheduler: reminderScheduler,
            calendar: makeCalendarUTC(),
            nowProvider: { now }
        )

        await viewModel.setReminderEnabled(true)

        #expect(!viewModel.reminderEnabled)
        #expect(reminderStore.snapshot?.isEnabled == false)
        #expect(reminderScheduler.scheduleCalls.isEmpty)
    }

    @Test
    func disablingReminderCancelsScheduledNotification() async {
        let now = makeDate("2026-02-19T10:00:00Z")
        let reminderStore = InMemoryReminderSettingsStore(
            snapshot: ReminderSettingsSnapshot(isEnabled: true, hour: 20, minute: 0)
        )
        let reminderScheduler = FakeReminderScheduler(fallbackAuthorizationStatus: .authorized)
        let viewModel = HomeDashboardViewModel(
            store: InMemoryProgressStore(),
            reminderStore: reminderStore,
            reminderScheduler: reminderScheduler,
            calendar: makeCalendarUTC(),
            nowProvider: { now }
        )

        await viewModel.setReminderEnabled(false)

        #expect(!viewModel.reminderEnabled)
        #expect(reminderStore.snapshot?.isEnabled == false)
        #expect(reminderScheduler.cancelCallCount == 1)
        #expect(reminderScheduler.scheduleCalls.isEmpty)
    }

    @Test
    func changingReminderTimeReschedulesWhenReminderIsEnabled() async {
        let now = makeDate("2026-02-19T10:00:00Z")
        let reminderStore = InMemoryReminderSettingsStore(
            snapshot: ReminderSettingsSnapshot(isEnabled: true, hour: 20, minute: 0)
        )
        let reminderScheduler = FakeReminderScheduler(fallbackAuthorizationStatus: .authorized)
        let viewModel = HomeDashboardViewModel(
            store: InMemoryProgressStore(),
            reminderStore: reminderStore,
            reminderScheduler: reminderScheduler,
            calendar: makeCalendarUTC(),
            nowProvider: { now }
        )

        await viewModel.setReminderTime(makeDate("2026-02-19T06:15:00Z"))

        #expect(viewModel.reminderEnabled)
        #expect(reminderStore.snapshot?.hour == 6)
        #expect(reminderStore.snapshot?.minute == 15)
        #expect(reminderScheduler.scheduleCalls.count == 1)
        #expect(reminderScheduler.scheduleCalls.first?.hour == 6)
        #expect(reminderScheduler.scheduleCalls.first?.minute == 15)
    }

    @Test
    func changingReminderTimePersistsButDoesNotScheduleWhenReminderIsDisabled() async {
        let now = makeDate("2026-02-19T10:00:00Z")
        let reminderStore = InMemoryReminderSettingsStore(
            snapshot: ReminderSettingsSnapshot(isEnabled: false, hour: 20, minute: 0)
        )
        let reminderScheduler = FakeReminderScheduler(fallbackAuthorizationStatus: .authorized)
        let viewModel = HomeDashboardViewModel(
            store: InMemoryProgressStore(),
            reminderStore: reminderStore,
            reminderScheduler: reminderScheduler,
            calendar: makeCalendarUTC(),
            nowProvider: { now }
        )

        await viewModel.setReminderTime(makeDate("2026-02-19T06:15:00Z"))

        #expect(!viewModel.reminderEnabled)
        #expect(reminderStore.snapshot?.hour == 6)
        #expect(reminderStore.snapshot?.minute == 15)
        #expect(reminderScheduler.scheduleCalls.isEmpty)
    }

    @Test
    func refreshReminderStatusDisablesReminderWhenPermissionWasRevoked() async {
        let now = makeDate("2026-02-19T10:00:00Z")
        let reminderStore = InMemoryReminderSettingsStore(
            snapshot: ReminderSettingsSnapshot(isEnabled: true, hour: 20, minute: 0)
        )
        let reminderScheduler = FakeReminderScheduler(fallbackAuthorizationStatus: .denied)
        let viewModel = HomeDashboardViewModel(
            store: InMemoryProgressStore(),
            reminderStore: reminderStore,
            reminderScheduler: reminderScheduler,
            calendar: makeCalendarUTC(),
            nowProvider: { now }
        )

        await viewModel.refreshReminderStatus()

        #expect(!viewModel.reminderEnabled)
        #expect(reminderStore.snapshot?.isEnabled == false)
        #expect(reminderScheduler.cancelCallCount == 1)
    }

    @Test
    func reminderSchedulingFailureDisablesReminder() async {
        let now = makeDate("2026-02-19T10:00:00Z")
        let reminderStore = InMemoryReminderSettingsStore()
        let reminderScheduler = FakeReminderScheduler(
            fallbackAuthorizationStatus: .authorized,
            scheduleError: FakeReminderSchedulerError.scheduleFailed
        )
        let viewModel = HomeDashboardViewModel(
            store: InMemoryProgressStore(),
            reminderStore: reminderStore,
            reminderScheduler: reminderScheduler,
            calendar: makeCalendarUTC(),
            nowProvider: { now }
        )

        await viewModel.setReminderEnabled(true)

        #expect(!viewModel.reminderEnabled)
        #expect(reminderStore.snapshot?.isEnabled == false)
        #expect(reminderScheduler.scheduleCalls.count == 1)
    }

    @Test
    func invalidStoredReminderTimeIsNormalizedOnLoad() {
        let now = makeDate("2026-02-19T10:00:00Z")
        let calendar = makeCalendarUTC()
        let reminderStore = InMemoryReminderSettingsStore(
            snapshot: ReminderSettingsSnapshot(isEnabled: false, hour: 99, minute: -10)
        )
        let viewModel = HomeDashboardViewModel(
            store: InMemoryProgressStore(),
            reminderStore: reminderStore,
            reminderScheduler: FakeReminderScheduler(fallbackAuthorizationStatus: .authorized),
            calendar: calendar,
            nowProvider: { now }
        )

        let reminderComponents = calendar.dateComponents([.hour, .minute], from: viewModel.reminderTime)

        #expect(reminderComponents.hour == ReminderSettingsSnapshot.defaultHour)
        #expect(reminderComponents.minute == ReminderSettingsSnapshot.defaultMinute)
        #expect(reminderStore.snapshot?.hour == ReminderSettingsSnapshot.defaultHour)
        #expect(reminderStore.snapshot?.minute == ReminderSettingsSnapshot.defaultMinute)
        #expect(reminderStore.saveCallCount > 0)
    }

    private func makeDate(_ raw: String) -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: raw)!
    }

    private func makeCalendarUTC() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }
}

private final class InMemoryProgressStore: DashboardProgressStoring {
    var snapshot: DashboardProgressSnapshot?
    var saveCallCount = 0

    init(snapshot: DashboardProgressSnapshot? = nil) {
        self.snapshot = snapshot
    }

    func load() -> DashboardProgressSnapshot? {
        snapshot
    }

    func save(_ snapshot: DashboardProgressSnapshot) {
        saveCallCount += 1
        self.snapshot = snapshot
    }
}

private final class InMemoryReminderSettingsStore: ReminderSettingsStoring {
    var snapshot: ReminderSettingsSnapshot?
    var saveCallCount = 0

    init(snapshot: ReminderSettingsSnapshot? = nil) {
        self.snapshot = snapshot
    }

    func load() -> ReminderSettingsSnapshot? {
        snapshot
    }

    func save(_ snapshot: ReminderSettingsSnapshot) {
        saveCallCount += 1
        self.snapshot = snapshot
    }
}

private final class FakeReminderScheduler: DailyReminderScheduling {
    var authorizationStatuses: [ReminderPermissionStatus]
    var fallbackAuthorizationStatus: ReminderPermissionStatus
    var requestAuthorizationResult: Bool
    var scheduleError: (any Error)?
    var scheduleCalls: [(hour: Int, minute: Int)] = []
    var cancelCallCount = 0
    var requestAuthorizationCallCount = 0

    init(
        authorizationStatuses: [ReminderPermissionStatus] = [],
        fallbackAuthorizationStatus: ReminderPermissionStatus,
        requestAuthorizationResult: Bool = true,
        scheduleError: (any Error)? = nil
    ) {
        self.authorizationStatuses = authorizationStatuses
        self.fallbackAuthorizationStatus = fallbackAuthorizationStatus
        self.requestAuthorizationResult = requestAuthorizationResult
        self.scheduleError = scheduleError
    }

    func authorizationStatus() async -> ReminderPermissionStatus {
        if !authorizationStatuses.isEmpty {
            return authorizationStatuses.removeFirst()
        }

        return fallbackAuthorizationStatus
    }

    func requestAuthorization() async -> Bool {
        requestAuthorizationCallCount += 1
        return requestAuthorizationResult
    }

    func scheduleDailyReminder(hour: Int, minute: Int) async throws {
        scheduleCalls.append((hour, minute))
        if let scheduleError {
            throw scheduleError
        }
    }

    func cancelDailyReminder() async {
        cancelCallCount += 1
    }
}

private enum FakeReminderSchedulerError: Error {
    case scheduleFailed
}
