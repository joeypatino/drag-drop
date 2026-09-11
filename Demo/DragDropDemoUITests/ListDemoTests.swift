import XCTest

/// The three list-backed screens: the play queue's table, the moodboard's
/// masonry grid, and the lineup's two grids with a move the datasource can veto.
final class ListDemoTests: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    // MARK: - Up Next

    @MainActor
    func testDraggingATrackOutOfTheQueueMovesItToSaved() {
        let app = launchDemo("NormalTableViewController")

        let panel = container("panel-saved", in: app)
        let table = container("queue-table", in: app)
        XCTAssertTrue(panel.waitForExistence(timeout: 5))
        XCTAssertTrue(identifiers(withPrefix: "track-", inside: panel, of: app).isEmpty,
                      "Saved starts empty")

        let queueBefore = identifiers(withPrefix: "track-", inside: table, of: app)
        let moved = queueBefore[0]

        drag(app.otherElements[moved], onto: panel)

        XCTAssertEqual(identifiers(withPrefix: "track-", inside: panel, of: app), [moved],
                       "The dragged row should be the only thing in Saved")
        XCTAssertFalse(identifiers(withPrefix: "track-", inside: table, of: app).contains(moved),
                       "\(moved) should have left the queue")
        attachScreenshot(app, "queue-after-drag-out")
    }

    @MainActor
    func testTheSavedPanelClosesTheGapWhenATrackLeaves() {
        let app = launchDemo("NormalTableViewController")

        let panel = container("panel-saved", in: app)
        let table = container("queue-table", in: app)
        XCTAssertTrue(panel.waitForExistence(timeout: 5))

        let queue = identifiers(withPrefix: "track-", inside: table, of: app)
        drag(app.otherElements[queue[0]], onto: panel)
        waitFor("track-", inside: panel, of: app, toCount: 1)
        let firstSlot = app.otherElements[queue[0]].frame

        drag(app.otherElements[queue[1]], onto: panel)
        waitFor("track-", inside: panel, of: app, toCount: 2)
        XCTAssertEqual(identifiers(withPrefix: "track-", inside: panel, of: app),
                       [queue[0], queue[1]],
                       "Both tracks should be stacked in Saved, in the order they arrived")

        // Take the first one back out; the second must move up into its slot
        // rather than leaving a hole.
        drag(app.otherElements[queue[0]], onto: table)

        XCTAssertEqual(identifiers(withPrefix: "track-", inside: panel, of: app), [queue[1]])
        XCTAssertEqual(app.otherElements[queue[1]].frame, firstSlot,
                       "The survivor should close the gap rather than hold slot 1")
        attachScreenshot(app, "saved-after-gap-close")
    }

    // MARK: - Moodboard

    @MainActor
    func testReorderingAMoodboardCardLeavesNoHoleAndNoOverlap() {
        let app = launchDemo("NormalCollectionViewController")

        let grid = container("moodboard", in: app)
        XCTAssertTrue(grid.waitForExistence(timeout: 5))

        let before = identifiers(withPrefix: "swatch-", inside: grid, of: app)
        XCTAssertGreaterThan(before.count, 3, "The grid should be showing cards")

        // Third visible card onto the first, which is a reorder within the grid.
        drag(app.otherElements[before[2]], onto: app.otherElements[before[0]])

        let after = identifiers(withPrefix: "swatch-", inside: grid, of: app)
        XCTAssertEqual(Set(after).count, after.count, "A card is drawn twice: \(after)")
        XCTAssertTrue(after.contains(before[2]), "The dragged card vanished")

        // Nothing stacked at one origin -- the failure mode that reads healthy
        // in UIKit's own bookkeeping while the screen is visibly wrong.
        let frames = after.map { app.otherElements[$0].frame }
        for (index, frame) in frames.enumerated() {
            for other in frames[(index + 1)...] {
                XCTAssertNotEqual(frame.origin, other.origin,
                                  "Two cards share an origin: \(frame) and \(other)")
            }
        }
        attachScreenshot(app, "moodboard-after-reorder")
    }

    // MARK: - Lineup

    @MainActor
    func testAPlayerMovesFromTheBenchToTheStarters() {
        let app = launchDemo("DoubleCollectionViewController")

        let starters = container("starters", in: app)
        let bench = container("bench", in: app)
        XCTAssertTrue(starters.waitForExistence(timeout: 5))

        let startersBefore = identifiers(withPrefix: "player-", inside: starters, of: app)
        let benchBefore = identifiers(withPrefix: "player-", inside: bench, of: app)
        XCTAssertEqual(startersBefore.count, 8)
        XCTAssertEqual(benchBefore.count, 8)

        let moved = benchBefore[0]
        drag(app.otherElements[moved], onto: app.otherElements[startersBefore[0]])

        let startersAfter = identifiers(withPrefix: "player-", inside: starters, of: app)
        XCTAssertTrue(startersAfter.contains(moved), "\(moved) should have joined the starters")
        XCTAssertFalse(identifiers(withPrefix: "player-", inside: bench, of: app).contains(moved),
                       "\(moved) should have left the bench")
        XCTAssertEqual(Set(startersAfter).count, startersAfter.count,
                       "A player is on the list twice: \(startersAfter)")
        attachScreenshot(app, "lineup-after-move")
    }

    /// The collection views close their own gap. This pins that down so the
    /// library's re-flow -- which a collection view's drop target opts out of --
    /// cannot start fighting UIKit for the layout.
    @MainActor
    func testDraggingACardOutOfAGridClosesTheGap() {
        let app = launchDemo("DoubleCollectionViewController")

        let starters = container("starters", in: app)
        let bench = container("bench", in: app)
        XCTAssertTrue(starters.waitForExistence(timeout: 5))

        let before = identifiers(withPrefix: "player-", inside: starters, of: app)
        let slots = before.map { app.otherElements[$0].frame }

        drag(app.otherElements[before[0]], onto: bench)
        attachScreenshot(app, "starters-after-gap-close")

        let after = identifiers(withPrefix: "player-", inside: starters, of: app)
        XCTAssertEqual(after, Array(before.dropFirst()),
                       "the first player should have left and the rest closed up")
        XCTAssertEqual(after.map { app.otherElements[$0].frame },
                       Array(slots.prefix(after.count)),
                       "the survivors should occupy the first slots, leaving no hole")
    }
}
