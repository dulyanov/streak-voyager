import SwiftUI

struct WorkoutSessionView: View {
    let plan: WorkoutPlan
    let onCompleted: (WorkoutCompletionEvent) -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: WorkoutSessionViewModel
    @State private var didSendCompletion = false
    @State private var activeSetRowWidth: CGFloat = 0

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
                    setTrackSection

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

    private var setTrackSection: some View {
        setTrack
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
        .frame(maxWidth: .infinity)
    }

    private var completeSetButton: some View {
        Button {
            viewModel.completeSet()
        } label: {
            VStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24, weight: .bold))

                Text("Complete\nSet")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .multilineTextAlignment(.center)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(plan.accent.opacity(viewModel.canCompleteSet ? 1 : 0.45))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.canCompleteSet)
    }

    private var setStatusCard: some View {
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

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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
        let edgeInset: CGFloat = 2
        let cardSpacing: CGFloat = edgeInset * 16
        let cardSide = activeSetCardSide(edgeInset: edgeInset, spacing: cardSpacing)
        let cardDimension: CGFloat? = cardSide > 0 ? cardSide : nil

        return VStack(alignment: .leading, spacing: AppTheme.Spacing.sectionSpacing) {
            HStack(alignment: .top, spacing: cardSpacing) {
                setStatusCard
                    .frame(width: cardDimension, height: cardDimension, alignment: .topLeading)

                completeSetButton
                    .frame(width: cardDimension, height: cardDimension, alignment: .center)
            }
            .padding(.horizontal, edgeInset)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                GeometryReader { proxy in
                    Color.clear
                        .preference(key: ActiveSetRowWidthPreferenceKey.self, value: proxy.size.width)
                }
            }
            .onPreferenceChange(ActiveSetRowWidthPreferenceKey.self) { width in
                activeSetRowWidth = width
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

    private func activeSetCardSide(edgeInset: CGFloat, spacing: CGFloat) -> CGFloat {
        let fallbackWidth = UIScreen.main.bounds.width - (AppTheme.Spacing.screenPadding * 2)
        let rowWidth = activeSetRowWidth > 0 ? activeSetRowWidth : fallbackWidth
        return max((rowWidth - (edgeInset * 2) - spacing) / 2, 0)
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

private struct ActiveSetRowWidthPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
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
