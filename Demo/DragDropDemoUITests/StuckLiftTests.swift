import XCTest

/// A drag can be over before the pickup animation that lifted the view has
/// finished. The lift has to come back down anyway -- a row left scaled up
/// reads as selected, and it overlaps its neighbours.
final class StuckLiftTests: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    /// Touch down, move a few points inside the same row, release. No drop
    /// target is crossed and the row lands back where it started, so the only
    /// thing that should have changed is nothing.
    @MainActor
    func testAShortQuickDragInsideOneRowLeavesItUnlifted() {
        let app = launchDemo("TableRowMoveViewController")

        let table = container("queue-table", in: app)
        XCTAssertTrue(table.waitForExistence(timeout: 5))

        let rows = identifiers(withPrefix: "track-", inside: table, of: app)
        XCTAssertGreaterThan(rows.count, 1)

        // `firstMatch` throughout: a query that resolves to more than one
        // element throws instead of answering, and a drag can leave a second
        // view carrying the same identifier.
        let subjectQuery = app.otherElements.matching(identifier: rows[0])
        let subject = subjectQuery.firstMatch
        let reference = app.otherElements.matching(identifier: rows[1]).firstMatch.frame

        let matchesBefore = subjectQuery.count

        let before = subject.frame
        XCTAssertEqual(before.width, reference.width, accuracy: 1.0,
                       "the rows should start the same width")

        // The press clears the 0.12s pickup delay so the gesture begins; the
        // release then lands inside the 0.15s pickup animation, which is the
        // case a normal drag never reaches.
        let start = subject.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        start.press(forDuration: 0.25,
                    thenDragTo: start.withOffset(CGVector(dx: 0, dy: 15)),
                    withVelocity: .fast,
                    thenHoldForDuration: 0)

        // The drop and the lift coming down are both animated, so give them a
        // bounded chance to settle rather than reading a mid-animation frame.
        let deadline = Date().addingTimeInterval(3)
        var width = subjectQuery.firstMatch.frame.width
        while Date() < deadline, abs(width - reference.width) > 1 {
            width = subjectQuery.firstMatch.frame.width
        }

        attachScreenshot(app, "after-short-drag")

        XCTAssertEqual(subjectQuery.count, matchesBefore,
                       "the drag left an extra view behind carrying the row's identifier")
        XCTAssertEqual(width, reference.width, accuracy: 1.0,
                       "the row is wider than its neighbours: something is left over it")
        XCTAssertEqual(subjectQuery.firstMatch.frame, before,
                       "the row should be back exactly where it started")
    }
}
