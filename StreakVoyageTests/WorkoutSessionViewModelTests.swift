import Testing
@testable import StreakVoyage

@MainActor
struct WorkoutSessionViewModelTests {
    @Test
    func sessionCompletesAfterAllSetsAndEmitsCompletionEvent() {
        let viewModel = WorkoutSessionViewModel(
            plan: .squats,
            restDurationSeconds: 5,
            usesAutomaticRestTimer: false
        )

        viewModel.startWorkout()

        for _ in 0..<10 { viewModel.countRep() }
        #expect(viewModel.phase == .rest)

        viewModel.skipRest()
        for _ in 0..<12 { viewModel.countRep() }
        #expect(viewModel.phase == .rest)

        viewModel.skipRest()
        for _ in 0..<10 { viewModel.countRep() }

        #expect(viewModel.phase == .completed)
        #expect(viewModel.completionEvent?.workoutID == "squats")
        #expect(viewModel.completionEvent?.xpAwarded == 50)
    }

    @Test
    func restCountdownMovesWorkoutToNextSet() {
        let viewModel = WorkoutSessionViewModel(
            plan: .pushups,
            restDurationSeconds: 2,
            usesAutomaticRestTimer: false
        )

        viewModel.startWorkout()
        for _ in 0..<8 { viewModel.countRep() }

        #expect(viewModel.phase == .rest)
        #expect(viewModel.currentSetIndex == 0)
        #expect(viewModel.restSecondsRemaining == 2)

        viewModel.tickRestCountdown()
        #expect(viewModel.phase == .rest)
        #expect(viewModel.restSecondsRemaining == 1)

        viewModel.tickRestCountdown()
        #expect(viewModel.phase == .activeSet)
        #expect(viewModel.currentSetIndex == 1)
        #expect(viewModel.currentRepCount == 0)
    }

    @Test
    func completeSetActionSkipsRepTappingAndFinishesWorkout() {
        let viewModel = WorkoutSessionViewModel(
            plan: .pushups,
            restDurationSeconds: 1,
            usesAutomaticRestTimer: false
        )

        viewModel.startWorkout()
        #expect(viewModel.canCompleteSet)

        viewModel.completeSet()
        #expect(viewModel.phase == .rest)
        #expect(viewModel.currentRepCount == 8)

        viewModel.skipRest()
        viewModel.completeSet()
        #expect(viewModel.phase == .rest)
        #expect(viewModel.currentRepCount == 10)

        viewModel.skipRest()
        viewModel.completeSet()

        #expect(viewModel.phase == .completed)
        #expect(viewModel.completionEvent?.workoutID == "pushups")
        #expect(viewModel.completionEvent?.xpAwarded == 50)
    }
}
