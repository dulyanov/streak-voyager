import Foundation
import Combine

@MainActor
final class HomeDashboardViewModel: ObservableObject {
    @Published private(set) var totalWorkouts = 0
    @Published private(set) var totalXP = 0
    @Published private(set) var currentStreak = 0
    @Published private(set) var longestStreak = 0
    @Published private(set) var completedWorkoutIDs: Set<String> = []

    private let store: DashboardProgressStoring
    private let calendar: Calendar
    private let nowProvider: () -> Date
    private var snapshot = DashboardProgressSnapshot()

    init(
        store: DashboardProgressStoring = UserDefaultsDashboardProgressStore(),
        calendar: Calendar = .current,
        nowProvider: @escaping () -> Date = Date.init
    ) {
        self.store = store
        self.calendar = calendar
        self.nowProvider = nowProvider
        load()
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

    private func load() {
        let stored = store.load() ?? DashboardProgressSnapshot()
        let normalized = normalize(stored, relativeTo: nowProvider())
        setSnapshot(normalized, persist: normalized != stored)
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
}
