import Foundation
import SwiftUI
import Combine

enum WorkoutPhase: Equatable {
    case formTip
    case activeSet
    case rest
    case completed
}

@MainActor
final class WorkoutSessionViewModel: ObservableObject {
    @Published private(set) var phase: WorkoutPhase = .formTip
    @Published private(set) var currentSetIndex = 0
    @Published private(set) var currentRepCount = 0
    @Published private(set) var restSecondsRemaining = 30
    @Published private(set) var completionEvent: WorkoutCompletionEvent?

    let plan: WorkoutPlan

    private let restDurationSeconds: Int
    private let usesAutomaticRestTimer: Bool
    private var restTimer: Timer?

    init(
        plan: WorkoutPlan,
        restDurationSeconds: Int = 30,
        usesAutomaticRestTimer: Bool = true
    ) {
        self.plan = plan
        self.restDurationSeconds = max(restDurationSeconds, 1)
        self.usesAutomaticRestTimer = usesAutomaticRestTimer
        self.restSecondsRemaining = max(restDurationSeconds, 1)
    }

    var totalSets: Int {
        plan.repsBySet.count
    }

    var currentSetTarget: Int {
        guard plan.repsBySet.indices.contains(currentSetIndex) else { return 0 }
        return plan.repsBySet[currentSetIndex]
    }

    var currentSetNumber: Int {
        min(currentSetIndex + 1, totalSets)
    }

    var completedSetsCount: Int {
        switch phase {
        case .formTip:
            return 0
        case .activeSet:
            return currentSetIndex
        case .rest:
            return currentSetIndex + 1
        case .completed:
            return totalSets
        }
    }

    var canCountRep: Bool {
        phase == .activeSet
    }

    func startWorkout() {
        resetForStart()
        phase = .activeSet
    }

    func countRep() {
        guard phase == .activeSet else { return }
        guard currentRepCount < currentSetTarget else { return }

        currentRepCount += 1

        if currentRepCount == currentSetTarget {
            completeCurrentSet()
        }
    }

    func skipRest() {
        guard phase == .rest else { return }
        restSecondsRemaining = 0
        moveToNextSetAfterRest()
    }

    func tickRestCountdown() {
        guard phase == .rest else { return }
        guard restSecondsRemaining > 0 else {
            moveToNextSetAfterRest()
            return
        }

        restSecondsRemaining -= 1

        if restSecondsRemaining == 0 {
            moveToNextSetAfterRest()
        }
    }

    private func resetForStart() {
        stopRestTimer()
        completionEvent = nil
        currentSetIndex = 0
        currentRepCount = 0
        restSecondsRemaining = restDurationSeconds
    }

    private func completeCurrentSet() {
        if currentSetIndex >= totalSets - 1 {
            finishWorkout()
            return
        }

        startRest()
    }

    private func startRest() {
        phase = .rest
        restSecondsRemaining = restDurationSeconds

        guard usesAutomaticRestTimer else { return }
        startRestTimer()
    }

    private func moveToNextSetAfterRest() {
        stopRestTimer()
        currentSetIndex += 1
        currentRepCount = 0
        phase = .activeSet
    }

    private func finishWorkout() {
        stopRestTimer()
        phase = .completed
        completionEvent = WorkoutCompletionEvent(
            workoutID: plan.id,
            xpAwarded: plan.xpReward,
            completedAt: Date()
        )
    }

    private func startRestTimer() {
        stopRestTimer()

        restTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor [self] in
                self.tickRestCountdown()
            }
        }
    }

    private func stopRestTimer() {
        restTimer?.invalidate()
        restTimer = nil
    }

    deinit {
        restTimer?.invalidate()
    }
}
