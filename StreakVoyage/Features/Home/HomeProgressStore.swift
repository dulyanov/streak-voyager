import Foundation

struct DashboardProgressSnapshot: Codable, Equatable {
    var totalWorkouts: Int = 0
    var totalXP: Int = 0
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var lastWorkoutAt: Date?
    var dailyCompletedDate: Date?
    var dailyCompletedWorkoutIDs: [String] = []
}

protocol DashboardProgressStoring {
    func load() -> DashboardProgressSnapshot?
    func save(_ snapshot: DashboardProgressSnapshot)
}

final class UserDefaultsDashboardProgressStore: DashboardProgressStoring {
    private enum Keys {
        static let snapshot = "dashboardProgressSnapshot"
    }

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> DashboardProgressSnapshot? {
        guard let data = defaults.data(forKey: Keys.snapshot) else { return nil }
        return try? decoder.decode(DashboardProgressSnapshot.self, from: data)
    }

    func save(_ snapshot: DashboardProgressSnapshot) {
        guard let data = try? encoder.encode(snapshot) else { return }
        defaults.set(data, forKey: Keys.snapshot)
    }
}
