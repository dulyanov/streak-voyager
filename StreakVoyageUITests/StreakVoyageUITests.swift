//
//  StreakVoyageUITests.swift
//  StreakVoyageUITests
//
//  Created by Danila Ulyanov on 2/18/26.
//

import XCTest

final class StreakVoyageUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testDashboardLaunchesWithExpectedInitialState() throws {
        let app = makeApp()
        app.launch()

        XCTAssertTrue(app.staticTexts["home.title"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["home.stat.workouts.value"].label, "0")
        XCTAssertEqual(app.staticTexts["home.daily.progress.count"].label, "0/2")
        XCTAssertTrue(app.buttons["home.workout.start.squats"].exists)
    }

    @MainActor
    func testCompleteSetFlowUpdatesDashboardProgress() throws {
        let app = makeApp()
        app.launch()

        let startSquatsButton = app.buttons["home.workout.start.squats"]
        XCTAssertTrue(startSquatsButton.waitForExistence(timeout: 5))
        startSquatsButton.tap()

        let startWorkoutButton = app.buttons["workout.start"]
        XCTAssertTrue(startWorkoutButton.waitForExistence(timeout: 5))
        startWorkoutButton.tap()

        for _ in 0..<2 {
            let completeSetButton = app.buttons["workout.completeSet"]
            XCTAssertTrue(completeSetButton.waitForExistence(timeout: 5))
            completeSetButton.tap()

            let skipRestButton = app.buttons["workout.skipRest"]
            XCTAssertTrue(skipRestButton.waitForExistence(timeout: 5))
            skipRestButton.tap()
        }

        let finalCompleteSetButton = app.buttons["workout.completeSet"]
        XCTAssertTrue(finalCompleteSetButton.waitForExistence(timeout: 5))
        finalCompleteSetButton.tap()

        let completedTitle = app.staticTexts["workout.completed.title"]
        XCTAssertTrue(completedTitle.waitForExistence(timeout: 5))

        let doneButton = app.buttons["workout.done"]
        XCTAssertTrue(doneButton.exists)
        doneButton.tap()

        let workoutsValue = app.staticTexts["home.stat.workouts.value"]
        XCTAssertTrue(workoutsValue.waitForExistence(timeout: 5))
        XCTAssertEqual(workoutsValue.label, "1")
        XCTAssertEqual(app.staticTexts["home.daily.progress.count"].label, "1/2")
        XCTAssertTrue(app.staticTexts["home.workout.done.squats"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            makeApp().launch()
        }
    }

    private func makeApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments.append("-reset-state-for-ui-tests")
        return app
    }
}
