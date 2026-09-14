import XCTest

/// Drop targets SwiftUI keeps alive while they are not on screen. A release
/// over empty space must never land in one.
final class SwiftUIVisibilityTests: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    /// Releases over the lower part of the window, where the hidden screen's
    /// panel sits and the visible screen has nothing.
    @MainActor
    private func dragToLowerWindow(_ source: XCUIElement, in app: XCUIApplication) {
        source.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            .press(forDuration: 0.25,
                   thenDragTo: app.windows.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.75)),
                   withVelocity: .default,
                   thenHoldForDuration: 0.4)
    }

    @MainActor
    func testATargetBehindAPushNeverReceivesADrop() {
        let app = launchHarness("pushed")
        XCTAssertTrue(app.buttons["Open"].waitForExistence(timeout: 5))
        app.buttons["Open"].tap()

        let a = container("panel-a", in: app)
        XCTAssertTrue(a.waitForExistence(timeout: 5))
        let chips = waitFor("chip-", inside: a, of: app, toCount: 3)

        dragToLowerWindow(app.otherElements[chips[0]], in: app)
        attachScreenshot(app, "pushed-after-release")

        waitFor("chip-", inside: a, of: app, toCount: 3)
        waitForLabel(app.staticTexts["counts"], "a:3 home:0")
    }

    @MainActor
    func testATargetOnAnUnselectedTabNeverReceivesADrop() {
        let app = launchHarness("tabs")
        XCTAssertTrue(container("panel-hidden", in: app).waitForExistence(timeout: 5))
        app.buttons["Second"].firstMatch.tap()

        let a = container("panel-a", in: app)
        XCTAssertTrue(a.waitForExistence(timeout: 5))
        let chips = waitFor("chip-", inside: a, of: app, toCount: 3)

        dragToLowerWindow(app.otherElements[chips[0]], in: app)
        attachScreenshot(app, "tabs-after-release")

        waitFor("chip-", inside: a, of: app, toCount: 3)
        waitForLabel(app.staticTexts["counts"], "a:3 hidden:0")
    }
}
