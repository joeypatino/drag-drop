import XCTest

/// A representable inside SwiftUI's scrolling containers. A swipe that starts
/// on a chip should scroll; a press and hold should still drag.
final class SwiftUIScrollTests: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    /// A touch that moves at once, with no hold: what a scroll looks like.
    @MainActor
    private func swipeUp(from element: XCUIElement) {
        let start = element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        start.press(forDuration: 0,
                    thenDragTo: start.withOffset(CGVector(dx: 0, dy: -250)),
                    withVelocity: .fast,
                    thenHoldForDuration: 0)
    }

    @MainActor
    private func assertASwipeOnAChipScrolls(_ configuration: String,
                                            file: StaticString = #filePath, line: UInt = #line) {
        let app = launchHarness(configuration)
        let top = app.staticTexts["scroll-top"]
        let a = container("panel-a", in: app)
        XCTAssertTrue(a.waitForExistence(timeout: 5), file: file, line: line)

        let chips = waitFor("chip-", inside: a, of: app, toCount: 3)
        let before = top.frame.minY

        swipeUp(from: app.otherElements[chips[0]])
        attachScreenshot(app, "\(configuration)-after-swipe")

        // Scrolled away entirely also counts: a missing element reports an
        // empty frame, so check existence before comparing positions.
        let scrolled = !top.isHittable || top.frame.minY < before - 50
        XCTAssertTrue(scrolled, "the swipe dragged the chip instead of scrolling", file: file, line: line)
    }

    /// C5, ScrollView. Predicted to fail today: defect F3.
    @MainActor
    func testASwipeStartingOnAChipScrollsAScrollView() {
        assertASwipeOnAChipScrolls("scroll")
    }

    /// C5, List. Predicted to fail today: defect F3.
    @MainActor
    func testASwipeStartingOnAChipScrollsAList() {
        assertASwipeOnAChipScrolls("list")
    }

    /// C5. Passes today, and must still pass after the fix.
    @MainActor
    func testAPressAndHoldStillDragsAChipInsideAScrollView() {
        let app = launchHarness("scroll")
        let a = container("panel-a", in: app)
        let b = container("panel-b", in: app)
        XCTAssertTrue(a.waitForExistence(timeout: 5))

        let chips = waitFor("chip-", inside: a, of: app, toCount: 3)
        drag(app.otherElements[chips[0]], onto: b)

        waitFor("chip-", inside: b, of: app, toCount: 1)
    }
}
