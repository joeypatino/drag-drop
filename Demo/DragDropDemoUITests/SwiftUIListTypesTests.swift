import XCTest

/// The table and collection view extensions inside SwiftUI representables.
final class SwiftUIListTypesTests: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    /// C6: out of the table into a panel, and back in.
    @MainActor
    func testARowLeavesAWrappedTableForAPanelAndComesBack() {
        let app = launchHarness("table")
        let table = container("harness-table", in: app)
        let saved = container("panel-saved", in: app)
        let counts = app.staticTexts["counts"]
        XCTAssertTrue(table.waitForExistence(timeout: 5))
        waitForLabel(counts, "saved:0 table:5")

        let rows = identifiers(withPrefix: "row-", inside: table, of: app)
        drag(app.otherElements[rows[0]], onto: saved)
        XCTAssertEqual(waitFor("row-", inside: saved, of: app, toCount: 1), [rows[0]])
        waitForLabel(counts, "saved:1 table:4")

        drag(app.otherElements[rows[0]], onto: table)
        waitFor("row-", inside: saved, of: app, toCount: 0)
        waitForLabel(counts, "saved:0 table:5")
        XCTAssertEqual(app.otherElements.matching(identifier: rows[0]).count, 1,
                       "the dropped view was left floating over the row that replaced it")
        attachScreenshot(app, "table-after-round-trip")
    }

    /// C7: one card from one wrapped collection view to another.
    @MainActor
    func testACardMovesBetweenTwoWrappedCollectionViews() {
        let app = launchHarness("collection")
        let starters = container("starters", in: app)
        let bench = container("bench", in: app)
        let counts = app.staticTexts["counts"]
        XCTAssertTrue(starters.waitForExistence(timeout: 5))
        waitForLabel(counts, "bench:2 starters:4")

        let players = waitFor("player-", inside: starters, of: app, toCount: 4)
        drag(app.otherElements[players[0]], onto: bench)

        waitFor("player-", inside: bench, of: app, toCount: 3)
        waitFor("player-", inside: starters, of: app, toCount: 3)
        waitForLabel(counts, "bench:3 starters:3")
        attachScreenshot(app, "collection-after-move")
    }
}
