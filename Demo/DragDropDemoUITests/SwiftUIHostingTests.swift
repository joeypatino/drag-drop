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

    @MainActor
    func testAChipCrossesBetweenTwoRepresentablesAndBack() {
        let app = launchHarness("siblings")
        let a = container("panel-a", in: app)
        let b = container("panel-b", in: app)
        let counts = app.staticTexts["counts"]
        XCTAssertTrue(a.waitForExistence(timeout: 5))
        waitForLabel(counts, "a:3 b:0")

        let chips = waitFor("chip-", inside: a, of: app, toCount: 3)
        drag(app.otherElements[chips[0]], onto: b)
        waitFor("chip-", inside: b, of: app, toCount: 1)
        waitForLabel(counts, "a:2 b:1")

        drag(app.otherElements[chips[0]], onto: a)
        waitFor("chip-", inside: a, of: app, toCount: 3)
        waitForLabel(counts, "a:3 b:0")

        XCTAssertEqual(probe(in: app), "ok")
        attachScreenshot(app, "siblings-after-round-trip")
    }

    /// C3. Predicted to fail today: defect F1.
    @MainActor
    func testAChipMovesBetweenPanelsInsideAPageSheet() {
        let app = launchHarness("sheet")
        let a = container("panel-a", in: app)
        let b = container("panel-b", in: app)
        XCTAssertTrue(a.waitForExistence(timeout: 5))

        let chips = waitFor("chip-", inside: a, of: app, toCount: 3)
        drag(app.otherElements[chips[0]], onto: b, at: CGVector(dx: 0.5, dy: 0.9))

        attachScreenshot(app, "sheet-after-drop")
        waitFor("chip-", inside: b, of: app, toCount: 1)
        XCTAssertEqual(probe(in: app), "ok")
    }

    /// C4. Predicted to fail today: defect F2.
    @MainActor
    func testAChipMovesBetweenPanelsUnderADetentSheet() {
        let app = launchHarness("detent")
        XCTAssertTrue(app.staticTexts["Inspector"].waitForExistence(timeout: 5))
        let a = container("panel-a", in: app)
        let b = container("panel-b", in: app)

        let chips = waitFor("chip-", inside: a, of: app, toCount: 3)
        drag(app.otherElements[chips[0]], onto: b)

        attachScreenshot(app, "detent-after-drop")
        waitFor("chip-", inside: b, of: app, toCount: 1)
        XCTAssertEqual(probe(in: app), "ok")
    }
}
