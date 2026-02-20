//
//  StreakVoyageTests.swift
//  StreakVoyageTests
//
//  Created by Danila Ulyanov on 2/18/26.
//

import Testing
@testable import StreakVoyage

struct StreakVoyageTests {
    @Test
    func workoutPlanDerivedValuesMatchRepConfiguration() {
        #expect(WorkoutPlan.squats.totalReps == 32)
        #expect(WorkoutPlan.squats.setsSummary == "3 sets - 32 reps")
        #expect(WorkoutPlan.pushups.totalReps == 26)
        #expect(WorkoutPlan.pushups.setsSummary == "3 sets - 26 reps")
    }

    @Test
    func reminderPermissionStatusAllowsSchedulingOnlyWhenAuthorized() {
        #expect(ReminderPermissionStatus.authorized.allowsScheduling)
        #expect(!ReminderPermissionStatus.notDetermined.allowsScheduling)
        #expect(!ReminderPermissionStatus.denied.allowsScheduling)
    }
}
