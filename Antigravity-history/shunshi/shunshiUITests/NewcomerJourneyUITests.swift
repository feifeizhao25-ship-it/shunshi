import XCTest

final class NewcomerJourneyUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        // 使用 -ui-testing 来跳过一些耗时的网络请求或重置状态
        app.launchArguments = ["-ui-testing"]
        app.launch()
    }

    func testNewcomerCompleteTasks() throws {
        // 1. Onboarding (如果存在)
        let nextButton = app.buttons["OnboardingNextButton"]
        if nextButton.exists {
            nextButton.tap()
            nextButton.tap()
            nextButton.tap()
            app.buttons["StartWellnessButton"].tap()
        }
        
        // 2. Quick Profile (如果存在)
        let skipButton = app.buttons["跳过"]
        while skipButton.exists {
            skipButton.tap()
        }

        // 3. Home Page - Verify Guide Section
        let guideHeader = app.staticTexts["新手三件事"]
        XCTAssertTrue(guideHeader.waitForExistence(timeout: 5))

        // Task 1: Constitution Test (Identify by accessibilityIdentifier)
        let task1 = app.buttons["NewcomerTask_1"]
        XCTAssertTrue(task1.exists)
        task1.tap()
        
        // 返回首页
        if app.buttons["Close"].exists {
            app.buttons["Close"].tap()
        } else {
            app.buttons.firstMatch.tap() // Fallback back
        }

        // Task 2: AI Consultant
        let task2 = app.buttons["NewcomerTask_2"]
        task2.tap()
        XCTAssertTrue(app.staticTexts["顺时小师"].waitForExistence(timeout: 5))
        
        let inputField = app.textFieldComponents["TextField"].firstMatch 
        // Note: Field text might vary, use type
        if inputField.exists {
            inputField.tap()
            inputField.typeText("处暑怎么养生？\n")
        }
        
        let backButton = app.buttons.matching(identifier: "Back").firstMatch
        if backButton.exists {
            backButton.tap()
        } else {
            // Dismiss consultant
            app.swipeDown(velocity: .fast)
        }

        // Task 3: Journal
        let task3 = app.buttons["NewcomerTask_3"]
        task3.tap()
        XCTAssertTrue(app.staticTexts["开启第一步"].exists || app.staticTexts["养生打卡"].exists)
    }
}

extension XCUIApplication {
    var textFieldComponents: XCUIElementQuery {
        return descendants(matching: .textField)
    }
}
