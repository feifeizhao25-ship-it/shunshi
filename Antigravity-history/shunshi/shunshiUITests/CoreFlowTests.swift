
import XCTest

final class CoreFlowTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testConstitutionTestFlow() throws {
        let app = XCUIApplication()
        app.launch()
        
        // 1. Verify Home Screen loads and shows Invitation Card
        let invitationCard = app.buttons["ConstitutionInvitationCard"]
        let exists = invitationCard.waitForExistence(timeout: 10)
        XCTAssertTrue(exists, "Constitution Invitation Card should appear on Home Screen")
        
        // 2. Start Test
        invitationCard.tap()
        
        // 3. Loop through questions
        // We assume the test has multiple questions. We'll loop until we see the result view.
        // Timeout after a reasonable number of steps to prevent infinite loops.
        let maxSteps = 30
        var testCompleted = false
        
        for _ in 0..<maxSteps {
            // Check for Finish Button (Result Screen)
            let finishButton = app.buttons["FinishTestButton"]
            if finishButton.waitForExistence(timeout: 2) {
                testCompleted = true
                break
            }
            
            // Check for Options
            // We look for any button with identifier starting with "Option_"
            let predicate = NSPredicate(format: "identifier BEGINSWITH 'Option_'")
            let options = app.buttons.containing(predicate)
            
            if options.firstMatch.waitForExistence(timeout: 5) {
                // Tap the first option (usually "No" or "Sometimes")
                // Adding a small delay to simulate user reading and to ensure animation completes
                // XCUITest actions are usually fast, but the app might have transitions.
                options.firstMatch.tap()
                
                // Wait for processing (AI thinking or transition)
                sleep(1) 
            } else {
                // If no options and no finish button, valid wait or error?
                // Might be loading the next question or the AI is slow.
                // We'll wait a bit longer in the next loop via the waitForExistence checks.
                print("Waiting for next question or result...")
            }
        }
        
        // 4. Verify Result
        XCTAssertTrue(testCompleted, "Should reach the result screen")
        
        // 5. Finish Test
        app.buttons["FinishTestButton"].tap()
        
        // 6. Verify Back to Home
        // The invitation card might still be there or might be gone depending on logic,
        // but the Result View should definitely be gone.
        let finishButtonAfter = app.buttons["FinishTestButton"]
        XCTAssertFalse(finishButtonAfter.exists, "Result screen should be dismissed")
    }
}
