import SwiftUI
import UIKit

enum AppTheme {
    enum Colors {
        static let screenBackground = Color.adaptive(
            light: UIColor(red: 0.95, green: 0.96, blue: 0.98, alpha: 1),
            dark: UIColor(red: 0.09, green: 0.11, blue: 0.15, alpha: 1)
        )
        static let cardBackground = Color.adaptive(
            light: UIColor(red: 1.00, green: 1.00, blue: 1.00, alpha: 1),
            dark: UIColor(red: 0.15, green: 0.18, blue: 0.24, alpha: 1)
        )
        static let cardBorder = Color.adaptive(
            light: UIColor(red: 0.80, green: 0.83, blue: 0.90, alpha: 1),
            dark: UIColor(red: 0.30, green: 0.34, blue: 0.42, alpha: 1)
        )
        static let cardShadow = Color.adaptive(
            light: UIColor(red: 0.75, green: 0.80, blue: 0.88, alpha: 0.75),
            dark: UIColor(red: 0.00, green: 0.00, blue: 0.00, alpha: 0.45)
        )

        static let textPrimary = Color.adaptive(
            light: UIColor(red: 0.12, green: 0.16, blue: 0.23, alpha: 1),
            dark: UIColor(red: 0.93, green: 0.95, blue: 0.99, alpha: 1)
        )
        static let textSecondary = Color.adaptive(
            light: UIColor(red: 0.41, green: 0.46, blue: 0.58, alpha: 1),
            dark: UIColor(red: 0.66, green: 0.72, blue: 0.84, alpha: 1)
        )
        static let mutedTrack = Color.adaptive(
            light: UIColor(red: 0.89, green: 0.91, blue: 0.95, alpha: 1),
            dark: UIColor(red: 0.25, green: 0.29, blue: 0.36, alpha: 1)
        )

        static let levelAccent = Color.adaptive(
            light: UIColor(red: 0.97, green: 0.79, blue: 0.08, alpha: 1),
            dark: UIColor(red: 0.95, green: 0.78, blue: 0.21, alpha: 1)
        )
        static let squatAccent = Color.adaptive(
            light: UIColor(red: 0.99, green: 0.49, blue: 0.12, alpha: 1),
            dark: UIColor(red: 1.00, green: 0.58, blue: 0.25, alpha: 1)
        )
        static let pushupAccent = Color.adaptive(
            light: UIColor(red: 0.20, green: 0.56, blue: 0.95, alpha: 1),
            dark: UIColor(red: 0.40, green: 0.70, blue: 1.00, alpha: 1)
        )

        static let warmTagBackground = Color.adaptive(
            light: UIColor(red: 0.99, green: 0.90, blue: 0.73, alpha: 1),
            dark: UIColor(red: 0.42, green: 0.32, blue: 0.20, alpha: 1)
        )
        static let warmIconBackground = Color.adaptive(
            light: UIColor(red: 0.98, green: 0.92, blue: 0.85, alpha: 1),
            dark: UIColor(red: 0.36, green: 0.28, blue: 0.21, alpha: 1)
        )
        static let coolIconBackground = Color.adaptive(
            light: UIColor(red: 0.88, green: 0.93, blue: 0.98, alpha: 1),
            dark: UIColor(red: 0.20, green: 0.29, blue: 0.40, alpha: 1)
        )
    }

    enum Spacing {
        static let screenPadding: CGFloat = 20
        static let sectionSpacing: CGFloat = 18
        static let cardPadding: CGFloat = 16
        static let compactCardPadding: CGFloat = 14
        static let itemSpacing: CGFloat = 8
        static let rowSpacing: CGFloat = 12
    }

    enum Radius {
        static let card: CGFloat = 18
        static let compactCard: CGFloat = 16
        static let pill: CGFloat = 10
        static let icon: CGFloat = 14
        static let button: CGFloat = 26
    }

    enum Stroke {
        static let width: CGFloat = 1
    }

    enum Shadow {
        static let yOffset: CGFloat = 4
    }
}

private extension Color {
    static func adaptive(light: UIColor, dark: UIColor) -> Color {
        Color(
            UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark ? dark : light
            }
        )
    }
}
