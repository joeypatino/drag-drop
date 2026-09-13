import XCTest

/// The library inside SwiftUI hosts: the hosting root, sibling representables,
/// a page sheet, and a detent sheet the screen underneath stays usable behind.
final class SwiftUIHostingTests: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    @MainActor
    func testAChipMovesBetweenPanelsAtTheHostingRoot() {
        let app = launchHarness("baseline")
        let a = container("panel-a", in: app)
        let b = container("panel-b", in: app)
        XCTAssertTrue(a.waitForExistence(timeout: 5))

        let chips = waitFor("chip-", inside: a, of: app, toCount: 3)
        drag(app.otherElements[chips[0]], onto: b)

        XCTAssertEqual(waitFor("chip-", inside: b, of: app, toCount: 1), [chips[0]])
        waitFor("chip-", inside: a, of: app, toCount: 2)
        XCTAssertEqual(probe(in: app), "ok")
        attachScreenshot(app, "baseline-after-drop")
    }
}
