//
//  StreakVoyageApp.swift
//  StreakVoyage
//
//  Created by Danila Ulyanov on 2/18/26.
//

import SwiftUI

@main
struct StreakVoyageApp: App {
    init() {
        configureForUITests()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }

    private func configureForUITests() {
        guard ProcessInfo.processInfo.arguments.contains("-reset-state-for-ui-tests") else { return }
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else { return }

        UserDefaults.standard.removePersistentDomain(forName: bundleIdentifier)
        UserDefaults.standard.synchronize()
    }
}
