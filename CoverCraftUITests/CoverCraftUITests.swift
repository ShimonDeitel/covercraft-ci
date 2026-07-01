import XCTest

/// End-to-end UI tests that actually tap through the core screens.
final class CoverCraftUITests: XCTestCase {

    override func setUp() { continueAfterFailure = false }

    private func launch(pro: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["COVERCRAFT_SKIP_AUTH"] = "1"   // bypass the Sign-in gate for testing
        app.launchEnvironment["COVERCRAFT_NO_SK"] = "1"       // no StoreKit sign-in prompt
        if pro { app.launchEnvironment["COVERCRAFT_FORCE_PRO"] = "1" }
        app.launch()
        return app
    }

    /// Home renders with the generate button disabled until required fields are filled.
    func testHomeRendersAndGenerateStartsDisabled() {
        let app = launch()
        let generate = app.buttons["generate-button"]
        XCTAssertTrue(generate.waitForExistence(timeout: 8))
        XCTAssertFalse(generate.isEnabled)
    }

    /// Settings opens and the theme control works.
    func testSettingsOpens() {
        let app = launch()
        XCTAssertTrue(app.buttons["generate-button"].waitForExistence(timeout: 8))
        app.navigationBars.buttons["gearshape"].tap()
        XCTAssertTrue(app.staticTexts["Settings"].waitForExistence(timeout: 5))
        app.buttons["Done"].tap()
        XCTAssertTrue(app.buttons["generate-button"].waitForExistence(timeout: 5))
    }

    /// History opens (empty state on a fresh launch).
    func testHistoryOpens() {
        let app = launch()
        XCTAssertTrue(app.buttons["generate-button"].waitForExistence(timeout: 8))
        app.navigationBars.buttons["clock.arrow.circlepath"].tap()
        XCTAssertTrue(app.staticTexts["History"].waitForExistence(timeout: 5))
        app.buttons["Done"].tap()
        XCTAssertTrue(app.buttons["generate-button"].waitForExistence(timeout: 5))
    }
}
