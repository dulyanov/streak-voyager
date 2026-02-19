import SwiftUI

struct WorkoutSessionView: View {
    let plan: WorkoutPlan
    let onCompleted: (WorkoutCompletionEvent) -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: WorkoutSessionViewModel
    @State private var didSendCompletion = false

    init(
        plan: WorkoutPlan,
        onCompleted: @escaping (WorkoutCompletionEvent) -> Void
    ) {
        self.plan = plan
        self.onCompleted = onCompleted
        _viewModel = StateObject(wrappedValue: WorkoutSessionViewModel(plan: plan))
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sectionSpacing) {
                    header
                    setTrack

                    switch viewModel.phase {
                    case .formTip:
                        formTipContent
                    case .activeSet:
                        activeSetContent
                    case .rest:
                        restContent
                    case .completed:
                        completionContent
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.screenPadding)
                .padding(.top, AppTheme.Spacing.screenPadding)
                .padding(.bottom, 24)
            }
            .background(AppTheme.Colors.screenBackground.ignoresSafeArea())
            .navigationTitle(plan.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                }
            }
        }
        .onChange(of: viewModel.phase) { _, newPhase in
            guard newPhase == .completed else { return }
            guard !didSendCompletion else { return }
            guard let event = viewModel.completionEvent else { return }

            didSendCompletion = true
            onCompleted(event)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(plan.subtitle)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.Colors.textSecondary)

            HStack(spacing: 8) {
                WorkoutTag(
                    text: "\(plan.repsBySet.count) sets",
                    foreground: .white,
                    background: plan.accent
                )

                WorkoutTag(
                    text: "\(plan.totalReps) reps",
                    foreground: .white,
                    background: plan.accent
                )

                WorkoutTag(
                    text: "+\(plan.xpReward) XP",
                    foreground: AppTheme.Colors.textPrimary,
                    background: AppTheme.Colors.warmTagBackground
                )
            }
        }
    }

    private var setTrack: some View {
        HStack(spacing: 8) {
            ForEach(Array(plan.repsBySet.enumerated()), id: \.offset) { index, target in
                VStack(spacing: 4) {
                    Text("Set \(index + 1)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                    Text("\(target)")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(setTextColor(for: index))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(setBackground(for: index))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
    }

    private var formTipContent: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sectionSpacing) {
            DashboardCard {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Form Tip", systemImage: "checkmark.shield")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(plan.accent)

                    Text(plan.formTip)
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                }
            }

            Button("Start Workout") {
                viewModel.startWorkout()
            }
            .buttonStyle(WorkoutPrimaryButtonStyle(accent: plan.accent))
        }
    }

    private var activeSetContent: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sectionSpacing) {
            DashboardCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Set \(viewModel.currentSetNumber) of \(viewModel.totalSets)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.Colors.textPrimary)

                    Text("Target: \(viewModel.currentSetTarget) reps")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.Colors.textSecondary)

                    Text("\(viewModel.currentRepCount)/\(viewModel.currentSetTarget)")
                        .font(.system(size: 40, weight: .black, design: .rounded))
                        .foregroundStyle(plan.accent)
                }
            }

            Button {
                viewModel.countRep()
            } label: {
                VStack(spacing: 10) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 34, weight: .bold))
                    Text("Tap To Count Rep")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                }
                .frame(maxWidth: .infinity, minHeight: 180)
                .foregroundStyle(plan.accent)
                .background(plan.accent.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(plan.accent.opacity(0.3), lineWidth: 1)
                }
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.canCountRep)
        }
    }

    private var restContent: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sectionSpacing) {
            DashboardCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Rest Time")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.Colors.textPrimary)

                    Text("\(viewModel.restSecondsRemaining)s")
                        .font(.system(size: 44, weight: .black, design: .rounded))
                        .foregroundStyle(plan.accent)

                    Text("Catch your breath before set \(viewModel.currentSetNumber + 1).")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
            }

            Button("Skip Rest") {
                viewModel.skipRest()
            }
            .buttonStyle(WorkoutPrimaryButtonStyle(accent: plan.accent))
        }
    }

    private var completionContent: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sectionSpacing) {
            DashboardCard {
                VStack(alignment: .leading, spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(plan.accent)

                    Text("Workout Complete")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(AppTheme.Colors.textPrimary)

                    Text("+\(plan.xpReward) XP earned")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(plan.accent)
                }
            }

            Button("Done") {
                dismiss()
            }
            .buttonStyle(WorkoutPrimaryButtonStyle(accent: plan.accent))
        }
    }

    private func setBackground(for index: Int) -> Color {
        if index < viewModel.completedSetsCount {
            return plan.accent
        }

        if index == viewModel.currentSetIndex && viewModel.phase == .activeSet {
            return plan.accent.opacity(0.22)
        }

        return AppTheme.Colors.mutedTrack
    }

    private func setTextColor(for index: Int) -> Color {
        if index < viewModel.completedSetsCount {
            return .white
        }

        if index == viewModel.currentSetIndex && viewModel.phase == .activeSet {
            return plan.accent
        }

        return AppTheme.Colors.textSecondary
    }
}

private struct WorkoutPrimaryButtonStyle: ButtonStyle {
    let accent: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(accent.opacity(configuration.isPressed ? 0.85 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct WorkoutSessionView_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutSessionView(plan: .squats) { _ in }
    }
}
