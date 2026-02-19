import SwiftUI
import Foundation

struct DashboardStat: Identifiable {
    let id: String
    let symbolName: String
    let value: String
    let title: String
    let tint: Color
}

struct WorkoutPlan: Identifiable {
    let id: String
    let name: String
    let subtitle: String
    let formTip: String
    let repsBySet: [Int]
    let xpReward: Int
    let iconEmoji: String
    let iconBackground: Color
    let accent: Color

    var totalReps: Int {
        repsBySet.reduce(0, +)
    }

    var setsSummary: String {
        "\(repsBySet.count) sets - \(totalReps) reps"
    }
}

extension WorkoutPlan {
    static let squats = WorkoutPlan(
        id: "squats",
        name: "Squats",
        subtitle: "Build strong legs and glutes",
        formTip: "Keep your chest up, knees in line with toes, and drive through your heels.",
        repsBySet: [10, 12, 10],
        xpReward: 50,
        iconEmoji: "🦵",
        iconBackground: AppTheme.Colors.warmIconBackground,
        accent: AppTheme.Colors.squatAccent
    )

    static let pushups = WorkoutPlan(
        id: "pushups",
        name: "Push-ups",
        subtitle: "Strengthen chest, arms and core",
        formTip: "Keep your body in a straight line and lower with control to protect your shoulders.",
        repsBySet: [8, 10, 8],
        xpReward: 50,
        iconEmoji: "💪",
        iconBackground: AppTheme.Colors.coolIconBackground,
        accent: AppTheme.Colors.pushupAccent
    )

    static let mvpPlans = [squats, pushups]
}

struct WorkoutCompletionEvent {
    let workoutID: String
    let xpAwarded: Int
    let completedAt: Date
}
