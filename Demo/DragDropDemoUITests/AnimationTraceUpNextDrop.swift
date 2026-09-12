import XCTest

/// Drives the reported Up Next repro, slowly and with still beats either side,
/// so a recording of it can be measured frame by frame.
///
///   1. A track leaves the queue for the Saved panel.
///   2. The same track is dragged back and dropped on the second row.
///
/// It is the second drop the trace is about: the rows below the drop point are
/// reported to move after the dropped row lands, rather than with it.
final class AnimationTraceUpNextDrop: XCTestCase {

    @MainActor
    func testDropBackIntoTheQueue() {
        let app = XCUIApplication()
        app.launchArguments += ["-demo", "TableRowMoveViewController", "-animation-trace"]
        app.launch()

        let table = container("queue-table", in: app)
        let panel = container("panel-saved", in: app)
        XCTAssertTrue(table.waitForExistence(timeout: 5))

        let queue = identifiers(withPrefix: "track-", inside: table, of: app)
        XCTAssertGreaterThan(queue.count, 3, "need rows below the drop point to observe")
        let travelling = queue[0]

        // A still beat before anything moves, so the recording has a clean
        // baseline. Every pause here is the shortest that leaves the screen
        // visibly at rest in the capture.
        Thread.sleep(forTimeInterval: 0.5)

        drag(app.otherElements[travelling], onto: panel)
        waitFor("track-", inside: panel, of: app, toCount: 1)
        Thread.sleep(forTimeInterval: 0.8)

        // Row 1 of what is left: below the first cell, with rows under it that
        // have somewhere to move.
        let remaining = identifiers(withPrefix: "track-", inside: table, of: app)
        XCTAssertEqual(remaining.first, queue[1], "the queue should have closed its gap")
        let secondRow = app.otherElements[remaining[1]]
        XCTAssertTrue(secondRow.isHittable)

        app.otherElements[travelling].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            .press(forDuration: 0.3,
                   thenDragTo: secondRow.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)),
                   withVelocity: .slow,
                   // Longer than the plain drag's hold: the measurement needs
                   // the gap not merely open but at rest before the release.
                   thenHoldForDuration: 0.8)

        // Long enough that every animation the drop starts finishes inside the
        // recording rather than at its edge. The drop and the row updates are
        // 0.25s and 0.3s, so this is roughly twice the longest of them.
        Thread.sleep(forTimeInterval: 1.2)

        let after = identifiers(withPrefix: "track-", inside: table, of: app)
        XCTAssertEqual(after.count, queue.count, "the track should be back in the queue")
        XCTAssertEqual(after[1], travelling, "dropped on row 1, so it should land at row 1")
    }
}
