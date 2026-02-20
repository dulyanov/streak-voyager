import Foundation
import Combine

@MainActor
final class HomeDashboardViewModel: ObservableObject {
    @Published private(set) var totalWorkouts = 0
    @Published private(set) var totalXP = 0
    @Published private(set) var currentStreak = 0
    @Published private(set) var longestStreak = 0
    @Published private(set) var completedWorkoutIDs: Set<String> = []
    @Published private(set) var reminderEnabled = false
    @Published private(set) var reminderTime = Date()
    @Published private(set) var reminderPermissionStatus: ReminderPermissionStatus = .notDetermined

    private let store: DashboardProgressStoring
    private let reminderStore: ReminderSettingsStoring
    private let reminderScheduler: DailyReminderScheduling
    private let calendar: Calendar
    private let nowProvider: () -> Date
    private var snapshot = DashboardProgressSnapshot()
    private var reminderSnapshot = ReminderSettingsSnapshot()

    init(
        store: DashboardProgressStoring? = nil,
        reminderStore: ReminderSettingsStoring? = nil,
        reminderScheduler: DailyReminderScheduling? = nil,
        calendar: Calendar = .current,
        nowProvider: @escaping () -> Date = Date.init
    ) {
        self.store = store ?? UserDefaultsDashboardProgressStore()
        self.reminderStore = reminderStore ?? UserDefaultsReminderSettingsStore()
        self.reminderScheduler = reminderScheduler ?? UserNotificationDailyReminderScheduler()
        self.calendar = calendar
        self.nowProvider = nowProvider
        load()
        loadReminderSettings()
    }

    var currentLevel: Int {
        (totalXP / 100) + 1
    }

    var levelXPProgress: Int {
        totalXP % 100
    }

    var todayCompletedCount: Int {
        completedWorkoutIDs.count
    }

    func isWorkoutCompletedToday(_ workoutID: String) -> Bool {
        completedWorkoutIDs.contains(workoutID)
    }

    func refreshForCurrentDate() {
        let normalized = normalize(snapshot, relativeTo: nowProvider())
        setSnapshot(normalized, persist: normalized != snapshot)
    }

    func refreshReminderStatus() async {
        let status = await reminderScheduler.authorizationStatus()
        reminderPermissionStatus = status

        guard reminderSnapshot.isEnabled else { return }

        guard status.allowsScheduling else {
            var disabled = reminderSnapshot
            disabled.isEnabled = false
            setReminderSnapshot(disabled, persist: true)
            await reminderScheduler.cancelDailyReminder()
            return
        }

        await scheduleReminderIfPossible()
    }

    func handleWorkoutCompletion(_ event: WorkoutCompletionEvent) {
        var next = normalize(snapshot, relativeTo: event.completedAt)

        if let completedDate = next.dailyCompletedDate {
            if !calendar.isDate(completedDate, inSameDayAs: event.completedAt) {
                next.dailyCompletedDate = event.completedAt
                next.dailyCompletedWorkoutIDs = []
            }
        } else {
            next.dailyCompletedDate = event.completedAt
            next.dailyCompletedWorkoutIDs = []
        }

        guard !next.dailyCompletedWorkoutIDs.contains(event.workoutID) else { return }

        next.dailyCompletedWorkoutIDs.append(event.workoutID)
        next.totalWorkouts += 1
        next.totalXP += event.xpAwarded
        updateStreak(&next, completionDate: event.completedAt)
        next.lastWorkoutAt = event.completedAt
        next.longestStreak = max(next.longestStreak, next.currentStreak)

        setSnapshot(next, persist: true)
    }

    func setReminderEnabled(_ isEnabled: Bool) async {
        if !isEnabled {
            var next = reminderSnapshot
            next.isEnabled = false
            setReminderSnapshot(next, persist: true)
            await reminderScheduler.cancelDailyReminder()
            return
        }

        let status = await reminderScheduler.authorizationStatus()
        reminderPermissionStatus = status

        switch status {
        case .authorized:
            var enabled = reminderSnapshot
            enabled.isEnabled = true
            setReminderSnapshot(enabled, persist: true)
            await scheduleReminderIfPossible()
        case .notDetermined:
            let granted = await reminderScheduler.requestAuthorization()
            let refreshedStatus = await reminderScheduler.authorizationStatus()
            reminderPermissionStatus = refreshedStatus

            guard granted, refreshedStatus.allowsScheduling else {
                var disabled = reminderSnapshot
                disabled.isEnabled = false
                setReminderSnapshot(disabled, persist: true)
                return
            }

            var enabled = reminderSnapshot
            enabled.isEnabled = true
            setReminderSnapshot(enabled, persist: true)
            await scheduleReminderIfPossible()
        case .denied:
            var disabled = reminderSnapshot
            disabled.isEnabled = false
            setReminderSnapshot(disabled, persist: true)
        }
    }

    func setReminderTime(_ date: Date) async {
        let normalizedDate = normalizedReminderDate(from: date)
        let components = calendar.dateComponents([.hour, .minute], from: normalizedDate)

        var next = reminderSnapshot
        next.hour = components.hour ?? ReminderSettingsSnapshot.defaultHour
        next.minute = components.minute ?? ReminderSettingsSnapshot.defaultMinute
        setReminderSnapshot(next, persist: true)

        guard next.isEnabled else { return }
        await scheduleReminderIfPossible()
    }

    private func load() {
        let stored = store.load() ?? DashboardProgressSnapshot()
        let normalized = normalize(stored, relativeTo: nowProvider())
        setSnapshot(normalized, persist: normalized != stored)
    }

    private func loadReminderSettings() {
        let stored = reminderStore.load() ?? ReminderSettingsSnapshot()
        let normalized = normalizeReminderSnapshot(stored)
        setReminderSnapshot(normalized, persist: normalized != stored)
    }

    private func setSnapshot(_ snapshot: DashboardProgressSnapshot, persist: Bool) {
        self.snapshot = snapshot
        totalWorkouts = snapshot.totalWorkouts
        totalXP = snapshot.totalXP
        currentStreak = snapshot.currentStreak
        longestStreak = snapshot.longestStreak
        completedWorkoutIDs = Set(snapshot.dailyCompletedWorkoutIDs)

        if persist {
            store.save(snapshot)
        }
    }

    private func setReminderSnapshot(_ snapshot: ReminderSettingsSnapshot, persist: Bool) {
        reminderSnapshot = snapshot
        reminderEnabled = snapshot.isEnabled
        reminderTime = reminderDate(forHour: snapshot.hour, minute: snapshot.minute)

        if persist {
            reminderStore.save(snapshot)
        }
    }

    private func normalize(_ snapshot: DashboardProgressSnapshot, relativeTo now: Date) -> DashboardProgressSnapshot {
        var normalized = snapshot

        if let completedDate = normalized.dailyCompletedDate,
           !calendar.isDate(completedDate, inSameDayAs: now) {
            normalized.dailyCompletedDate = now
            normalized.dailyCompletedWorkoutIDs = []
        }

        if let lastWorkoutAt = normalized.lastWorkoutAt,
           !calendar.isDate(lastWorkoutAt, inSameDayAs: now),
           !isYesterday(lastWorkoutAt, relativeTo: now) {
            normalized.currentStreak = 0
        }

        return normalized
    }

    private func normalizeReminderSnapshot(_ snapshot: ReminderSettingsSnapshot) -> ReminderSettingsSnapshot {
        var normalized = snapshot

        if !(0...23).contains(normalized.hour) {
            normalized.hour = ReminderSettingsSnapshot.defaultHour
        }

        if !(0...59).contains(normalized.minute) {
            normalized.minute = ReminderSettingsSnapshot.defaultMinute
        }

        return normalized
    }

    private func updateStreak(_ snapshot: inout DashboardProgressSnapshot, completionDate: Date) {
        guard let lastWorkoutAt = snapshot.lastWorkoutAt else {
            snapshot.currentStreak = 1
            return
        }

        if calendar.isDate(lastWorkoutAt, inSameDayAs: completionDate) {
            return
        }

        if isYesterday(lastWorkoutAt, relativeTo: completionDate) {
            snapshot.currentStreak = max(1, snapshot.currentStreak + 1)
            return
        }

        snapshot.currentStreak = 1
    }

    private func isYesterday(_ date: Date, relativeTo referenceDate: Date) -> Bool {
        let startOfReferenceDay = calendar.startOfDay(for: referenceDate)
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: startOfReferenceDay) else {
            return false
        }

        return calendar.isDate(date, inSameDayAs: yesterday)
    }

    private func reminderDate(forHour hour: Int, minute: Int) -> Date {
        var components = calendar.dateComponents([.year, .month, .day], from: nowProvider())
        components.hour = hour
        components.minute = minute

        return calendar.date(from: components) ?? nowProvider()
    }

    private func normalizedReminderDate(from date: Date) -> Date {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        let hour = components.hour ?? ReminderSettingsSnapshot.defaultHour
        let minute = components.minute ?? ReminderSettingsSnapshot.defaultMinute
        return reminderDate(forHour: hour, minute: minute)
    }

    private func scheduleReminderIfPossible() async {
        guard reminderSnapshot.isEnabled else { return }

        let status = await reminderScheduler.authorizationStatus()
        reminderPermissionStatus = status
        guard status.allowsScheduling else { return }

        do {
            try await reminderScheduler.scheduleDailyReminder(
                hour: reminderSnapshot.hour,
                minute: reminderSnapshot.minute
            )
        } catch {
            var disabled = reminderSnapshot
            disabled.isEnabled = false
            setReminderSnapshot(disabled, persist: true)
        }
    }
}
