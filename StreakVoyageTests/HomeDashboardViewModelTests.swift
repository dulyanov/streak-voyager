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
