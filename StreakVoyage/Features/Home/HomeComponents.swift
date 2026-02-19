import SwiftUI

struct LevelProgressCard: View {
    let level: Int
    let currentXP: Int
    let goalXP: Int

    private var progress: CGFloat {
        guard goalXP > 0 else { return 0 }
        return min(max(CGFloat(currentXP) / CGFloat(goalXP), 0), 1)
    }

    var body: some View {
        DashboardCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.rowSpacing) {
                Text("LEVEL PROGRESS")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.Colors.textSecondary)

                HStack(spacing: AppTheme.Spacing.rowSpacing) {
                    Text("\(level)")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                        .frame(width: 36, height: 36)
                        .background(AppTheme.Colors.levelAccent)
                        .clipShape(Circle())

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(AppTheme.Colors.mutedTrack)

                            Capsule()
                                .fill(AppTheme.Colors.levelAccent)
                                .frame(width: geo.size.width * progress)
                        }
                    }
                    .frame(height: 14)

                    Text("\(currentXP)/\(goalXP) XP")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
            }
        }
    }
}

struct StatTileView: View {
    let stat: DashboardStat

    var body: some View {
        DashboardCard(
            padding: AppTheme.Spacing.compactCardPadding,
            cornerRadius: AppTheme.Radius.compactCard
        ) {
            VStack(spacing: 6) {
                Image(systemName: stat.symbolName)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(stat.tint)

                Text(stat.value)
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundStyle(AppTheme.Colors.textPrimary)

                Text(stat.title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, minHeight: 92)
        }
    }
}

struct ExerciseCardView: View {
    let exercise: ExerciseSummary

    var body: some View {
        DashboardCard {
            HStack(spacing: AppTheme.Spacing.rowSpacing) {
                RoundedRectangle(cornerRadius: AppTheme.Radius.icon, style: .continuous)
                    .fill(exercise.iconBackground)
                    .frame(width: 64, height: 64)
                    .overlay {
                        Image(systemName: exercise.symbolName)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(exercise.accent)
                    }

                VStack(alignment: .leading, spacing: 5) {
                    Text(exercise.name)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.Colors.textPrimary)

                    Text(exercise.subtitle)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.Colors.textSecondary)

                    HStack(spacing: 6) {
                        WorkoutTag(
                            text: exercise.setsSummary,
                            foreground: .white,
                            background: exercise.accent
                        )

                        WorkoutTag(
                            text: "+\(exercise.xpReward) XP",
                            foreground: AppTheme.Colors.textPrimary,
                            background: AppTheme.Colors.warmTagBackground
                        )
                    }
                }

                Spacer(minLength: 10)
                WorkoutActionButton(accent: exercise.accent)
            }
        }
    }
}

struct WorkoutTag: View {
    let text: String
    let foreground: Color
    let background: Color

    var body: some View {
        Text(text)
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .foregroundStyle(foreground)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.pill, style: .continuous))
    }
}

struct WorkoutActionButton: View {
    let accent: Color

    var body: some View {
        Button(action: {}) {
            Image(systemName: "play.fill")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(accent)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

struct DailyProgressBar: View {
    let progress: CGFloat

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(AppTheme.Colors.mutedTrack)

                Capsule()
                    .fill(AppTheme.Colors.levelAccent)
                    .frame(width: geo.size.width * min(max(progress, 0), 1))
            }
        }
        .frame(height: 8)
    }
}

struct ReminderCardView: View {
    let isEnabled: Bool

    var body: some View {
        DashboardCard {
            HStack(spacing: AppTheme.Spacing.rowSpacing) {
                RoundedRectangle(cornerRadius: AppTheme.Radius.icon, style: .continuous)
                    .fill(AppTheme.Colors.warmIconBackground)
                    .frame(width: 52, height: 52)
                    .overlay {
                        Image(systemName: "bell")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(AppTheme.Colors.squatAccent)
                    }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Enable daily reminders")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.Colors.textPrimary)

                    Text("Protect your streak every day")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }

                Spacer()

                Text(isEnabled ? "ON" : "OFF")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(isEnabled ? AppTheme.Colors.squatAccent : AppTheme.Colors.textSecondary)
            }
        }
    }
}
