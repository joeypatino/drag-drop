import XCTest

/// The table actually gets shorter when a row is dragged out, and longer when
/// one is dropped in. These were pixel probes over a hard-coded blue; they now
/// assert on identity, which is what they were approximating all along.
final class TableRowCollapseTests: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    @MainActor
    private func openQueue() -> (app: XCUIApplication, table: XCUIElement, panel: XCUIElement) {
        let app = launchDemo("TableRowMoveViewController")
        let table = container("queue-table", in: app)
        let panel = container("panel-saved", in: app)
        XCTAssertTrue(panel.waitForExistence(timeout: 5))
        return (app, table, panel)
    }

    @MainActor
    private func queue(_ app: XCUIApplication, _ table: XCUIElement) -> [String] {
        identifiers(withPrefix: "track-", inside: table, of: app)
    }

    @MainActor
    func testDraggingRowsOutCollapsesTheTable() {
        let (app, table, panel) = openQueue()

        let before = queue(app, table)
        XCTAssertGreaterThanOrEqual(before.count, 4, "precondition: several rows on screen")
        let topSlot = app.otherElements[before[0]].frame

        drag(app.otherElements[before[0]], onto: panel)
        waitFor("track-", inside: panel, of: app, toCount: 1)

        drag(app.otherElements[before[1]], onto: panel)
        waitFor("track-", inside: panel, of: app, toCount: 2)
        attachScreenshot(app, "table-after-two-rows-removed")

        let after = queue(app, table)
        XCTAssertFalse(after.contains(before[0]))
        XCTAssertFalse(after.contains(before[1]))

        // Had the rows merely been emptied, they would still be here as blank
        // bands. The third row moving into the first slot is what says the
        // table actually got shorter.
        XCTAssertEqual(after.first, before[2],
                       "the rows below should have moved up, leaving no blank band")
        XCTAssertEqual(app.otherElements[before[2]].frame, topSlot,
                       "the top band should hold a row, not a hole")
    }

    /// The rows stayed gone rather than being manufactured again by
    /// cellForRowAt, which is what used to happen.
    @MainActor
    func testTheRemovedRowsDoNotComeBackOnScroll() {
        let (app, table, panel) = openQueue()

        let before = queue(app, table)
        drag(app.otherElements[before[0]], onto: panel)
        waitFor("track-", inside: panel, of: app, toCount: 1)
        drag(app.otherElements[before[1]], onto: panel)
        waitFor("track-", inside: panel, of: app, toCount: 2)

        for _ in 0..<3 { table.swipeUp(velocity: .slow) }
        for _ in 0..<6 { table.swipeDown(velocity: .slow) }
        attachScreenshot(app, "table-after-scroll-round-trip")

        let after = queue(app, table)
        XCTAssertFalse(after.contains(before[0]),
                       "\(before[0]) came back after scrolling away and back")
        XCTAssertFalse(after.contains(before[1]),
                       "\(before[1]) came back after scrolling away and back")
    }

    /// And the other direction: a card dragged off the panel onto the table
    /// makes a row appear, at the drop point.
    @MainActor
    func testDraggingAViewOntoTheTableInsertsARow() {
        let (app, table, panel) = openQueue()

        let before = queue(app, table)
        let moved = before[0]
        drag(app.otherElements[moved], onto: panel)

        let shortened = queue(app, table)
        XCTAssertFalse(shortened.contains(moved), "precondition: one row shorter")

        // Back onto the table, aimed at the third visible row.
        drag(app.otherElements[moved], onto: app.otherElements[shortened[2]])
        attachScreenshot(app, "table-after-row-inserted")

        let after = queue(app, table)
        XCTAssertTrue(after.contains(moved), "a row should have appeared at the drop point")
        XCTAssertEqual(Set(after).count, after.count, "a row is drawn twice: \(after)")
        XCTAssertTrue(identifiers(withPrefix: "track-", inside: panel, of: app).isEmpty,
                      "the panel should have given the card up")
    }
}
