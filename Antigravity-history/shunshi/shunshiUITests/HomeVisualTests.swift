
import XCTest

final class HomeVisualTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = true // Continue to capture as much as possible
    }

    @MainActor
    func testHomeScreenVisuals() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Wait for launch
        sleep(5)
        
        // Log hierarchy for debugging
        print(app.debugDescription)
        
        // 1. Capture Top Screen
        // Try to find the header, but capture anyway
        let homeHero = app.descendants(matching: .any)["HomeHeroHeader"].firstMatch
        let exists = homeHero.waitForExistence(timeout: 5)
        
        if !exists {
            print("⚠️ HomeHeroHeader not found. Capturing screen anyway.")
        }
        
        takeScreenshot(named: "1_HomeScreen_Top", app: app)

        // 2. Scroll and Capture Rituals
        app.swipeUp()
        sleep(1) // Wait for scroll animation
        takeScreenshot(named: "2_HomeScreen_Middle", app: app)
        
        // 3. Scroll and Capture Bottom
        app.swipeUp()
        sleep(1)
        takeScreenshot(named: "3_HomeScreen_Bottom", app: app)
    }
    
    func takeScreenshot(named name: String, app: XCUIApplication) {
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
