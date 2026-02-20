import SwiftUI

struct HomeDashboardView: View {
    private let workouts = WorkoutPlan.mvpPlans

    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel = HomeDashboardViewModel()
    @State private var activeWorkout: WorkoutPlan?

    private var stats: [DashboardStat] {
        [
            DashboardStat(
                id: "workouts",
                symbolName: "trophy.fill",
                value: "\(viewModel.totalWorkouts)",
                title: "Workouts",
                tint: AppTheme.Colors.levelAccent
            ),
            DashboardStat(
                id: "streak",
                symbolName: "flame.fill",
                value: "\(viewModel.currentStreak)",
                title: "Day Streak",
                tint: AppTheme.Colors.squatAccent
            ),
            DashboardStat(
                id: "xp",
                symbolName: "bolt.fill",
                value: "\(viewModel.totalXP)",
                title: "Total XP",
                tint: AppTheme.Colors.squatAccent
            )
        ]
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sectionSpacing) {
                    header
                    LevelProgressCard(level: viewModel.currentLevel, currentXP: viewModel.levelXPProgress, goalXP: 100)
                    statsRow
                    workoutSectionHeader
                    dailyProgressRow

                    ForEach(workouts) { workout in
                        ExerciseCardView(
                            exercise: workout,
                            isCompletedToday: viewModel.isWorkoutCompletedToday(workout.id),
                            onStart: {
                                activeWorkout = workout
                            }
                        )
                    }

                    ReminderCardView(
                        isEnabled: viewModel.reminderEnabled,
                        reminderTime: viewModel.reminderTime,
                        permissionStatus: viewModel.reminderPermissionStatus,
                        onToggle: { isEnabled in
                            Task {
                                await viewModel.setReminderEnabled(isEnabled)
                            }
                        },
                        onTimeChange: { reminderTime in
                            Task {
                                await viewModel.setReminderTime(reminderTime)
                            }
                        }
                    )
                }
                .padding(.horizontal, AppTheme.Spacing.screenPadding)
                .padding(.top, AppTheme.Spacing.screenPadding)
                .padding(.bottom, 26)
            }
            .background(AppTheme.Colors.screenBackground.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(item: $activeWorkout) { workout in
            WorkoutSessionView(plan: workout) { event in
                viewModel.handleWorkoutCompletion(event)
            }
        }
        .onAppear {
            viewModel.refreshForCurrentDate()
            Task {
                await viewModel.refreshReminderStatus()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            viewModel.refreshForCurrentDate()
            Task {
                await viewModel.refreshReminderStatus()
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(greeting)
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

                    Text("\(viewModel.currentStreak)")
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

            Text("\(viewModel.todayCompletedCount)/\(workouts.count)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
    }

    private var dailyProgressRow: some View {
        HStack(spacing: 8) {
            ForEach(Array(workouts.enumerated()), id: \.offset) { index, _ in
                DailyProgressBar(progress: viewModel.todayCompletedCount > index ? 1 : 0)
            }
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "Good morning!"
        case 12..<18:
            return "Good afternoon!"
        default:
            return "Good evening!"
        }
    }
}

struct HomeDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        HomeDashboardView()
    }
}
