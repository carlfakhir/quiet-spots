/*
Abstract:
End-to-end UI test: create an account, open a spot, measure noise, post a report, and see it listed.
Run against `npx wrangler dev` (the Simulator build talks to localhost:8787).
*/

import XCTest

final class QuietSpotsUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func testCreateAccountMeasureAndPostReport() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting"]
        app.launch()
        snapshot(app, "01-spot-list")

        // Create an account.
        app.tabBars.buttons["Account"].tap()
        // The Keychain survives reinstalls, so an earlier run may still be signed in.
        if app.buttons["Sign out"].waitForExistence(timeout: 3) { app.buttons["Sign out"].tap() }
        XCTAssertTrue(app.buttons["Create account"].firstMatch.waitForExistence(timeout: 5))
        app.buttons["Create account"].firstMatch.tap()
        let username = "tester_\(Int.random(in: 1000...9999))"
        let usernameField = app.textFields["Username"]
        XCTAssertTrue(usernameField.waitForExistence(timeout: 5))
        usernameField.tap()
        usernameField.typeText(username)
        let passwordField = app.secureTextFields["Password"]
        passwordField.tap()
        passwordField.typeText("password123")
        snapshot(app, "02-create-account")
        app.buttons["auth.submit"].tap()
        XCTAssertTrue(app.buttons["Sign out"].waitForExistence(timeout: 10), "Account screen should show after signing up")
        XCTAssertTrue(app.staticTexts["Username, \(username)"].exists, "Signed-in username should be shown")
        // iOS may offer to save the password; it covers the app, so dismiss it.
        let notNow = app.buttons["Not Now"]
        if notNow.waitForExistence(timeout: 3) { notNow.tap() }
        snapshot(app, "03-signed-in")

        // Open the first spot and measure.
        app.tabBars.buttons["Spots"].tap()
        app.staticTexts["Crosland Tower 1st Floor"].firstMatch.tap()
        XCTAssertTrue(app.buttons["spot.measure"].waitForExistence(timeout: 5))
        snapshot(app, "04-spot-detail")
        app.buttons["spot.measure"].tap()

        let post = app.buttons["measure.post"]
        XCTAssertTrue(post.waitForExistence(timeout: 5))
        snapshot(app, "05-measuring")
        let enabled = NSPredicate(format: "isEnabled == true")
        expectation(for: enabled, evaluatedWith: post)
        waitForExpectations(timeout: 15)
        app.buttons["Quiet"].firstMatch.tap()
        snapshot(app, "06-measured")
        post.tap()

        // The new report appears on the spot page, attributed to "You".
        XCTAssertTrue(app.staticTexts["You"].waitForExistence(timeout: 10), "Posted report should appear")
        snapshot(app, "07-report-posted")
    }

    private func snapshot(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
