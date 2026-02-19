import SwiftUI

struct DashboardCard<Content: View>: View {
    private let padding: CGFloat
    private let cornerRadius: CGFloat
    private let content: Content

    init(
        padding: CGFloat = AppTheme.Spacing.cardPadding,
        cornerRadius: CGFloat = AppTheme.Radius.card,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(AppTheme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(AppTheme.Colors.cardBorder, lineWidth: AppTheme.Stroke.width)
            }
            .shadow(
                color: AppTheme.Colors.cardShadow,
                radius: 0,
                x: 0,
                y: AppTheme.Shadow.yOffset
            )
    }
}
