import SwiftUI

struct HomeDashboardView: View {
    private let stats: [DashboardStat] = [
        DashboardStat(
            id: "workouts",
            symbolName: "trophy.fill",
            value: "0",
            title: "Workouts",
            tint: AppTheme.Colors.levelAccent
        ),
        DashboardStat(
            id: "streak",
            symbolName: "flame.fill",
            value: "0",
            title: "Day Streak",
            tint: AppTheme.Colors.squatAccent
        ),
        DashboardStat(
            id: "xp",
            symbolName: "bolt.fill",
            value: "0",
            title: "Total XP",
            tint: AppTheme.Colors.squatAccent
        )
    ]

    private let exercises: [ExerciseSummary] = [
        ExerciseSummary(
            id: "squats",
            name: "Squats",
            subtitle: "Build strong legs and glutes",
            setsSummary: "3 sets - 32 reps",
            xpReward: 50,
            symbolName: "figure.strengthtraining.traditional",
            iconBackground: AppTheme.Colors.warmIconBackground,
            accent: AppTheme.Colors.squatAccent
        ),
        ExerciseSummary(
            id: "pushups",
            name: "Push-ups",
            subtitle: "Strengthen chest, arms and core",
            setsSummary: "3 sets - 26 reps",
            xpReward: 50,
            symbolName: "figure.push.up",
            iconBackground: AppTheme.Colors.coolIconBackground,
            accent: AppTheme.Colors.pushupAccent
        )
    ]

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sectionSpacing) {
                    header
                    LevelProgressCard(level: 1, currentXP: 0, goalXP: 100)
                    statsRow
                    workoutSectionHeader
                    dailyProgressRow

                    ForEach(exercises) { exercise in
                        ExerciseCardView(exercise: exercise)
                    }

                    ReminderCardView(isEnabled: true)
                }
                .padding(.horizontal, AppTheme.Spacing.screenPadding)
                .padding(.top, AppTheme.Spacing.screenPadding)
                .padding(.bottom, 26)
            }
            .background(AppTheme.Colors.screenBackground.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Good evening!")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.Colors.textSecondary)

                Text("StreakVoyage")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
            }

            Spacer()

            DashboardCard(padding: 10, cornerRadius: 14) {
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(AppTheme.Colors.squatAccent)

                    Text("0")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppTheme.Colors.squatAccent)
                }
                .padding(.horizontal, 8)
            }
        }
    }

    private var statsRow: some View {
        HStack(spacing: AppTheme.Spacing.rowSpacing) {
            ForEach(stats) { stat in
                StatTileView(stat: stat)
            }
        }
    }

    private var workoutSectionHeader: some View {
        HStack {
            Text("Today's Workout")
                .font(.system(size: 19, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.Colors.textPrimary)

            Spacer()

            Text("0/2")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
    }

    private var dailyProgressRow: some View {
        HStack(spacing: 8) {
            DailyProgressBar(progress: 0)
            DailyProgressBar(progress: 0)
        }
    }
}

#Preview {
    HomeDashboardView()
}
