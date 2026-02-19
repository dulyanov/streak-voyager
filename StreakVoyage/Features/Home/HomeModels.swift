import SwiftUI

struct DashboardStat: Identifiable {
    let id: String
    let symbolName: String
    let value: String
    let title: String
    let tint: Color
}

struct ExerciseSummary: Identifiable {
    let id: String
    let name: String
    let subtitle: String
    let setsSummary: String
    let xpReward: Int
    let symbolName: String
    let iconBackground: Color
    let accent: Color
}
