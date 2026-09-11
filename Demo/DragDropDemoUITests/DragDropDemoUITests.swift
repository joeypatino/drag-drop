import XCTest

final class DragDropDemoUITests: XCTestCase {

    private let exampleTitles = [
        "4x4",
        "Container-Embedded",
        "Container-2xEmbedded",
        "Drop Target Embedded",
        "Table View",
        "Collection View",
        "Double Collection View"
    ]

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testEveryExampleScreenIsReachable() {
        let app = XCUIApplication()
        app.launch()

        for title in exampleTitles {
            let row = app.tables.staticTexts[title]
            XCTAssertTrue(row.waitForExistence(timeout: 5), "Missing row: \(title)")
            row.tap()

            let backButton = app.navigationBars.buttons.element(boundBy: 0)
            XCTAssertTrue(backButton.waitForExistence(timeout: 5),
                          "Did not navigate into: \(title)")

            let shot = XCTAttachment(screenshot: app.screenshot())
            shot.name = title
            shot.lifetime = .keepAlways
            add(shot)

            backButton.tap()
        }
    }

    /// Rendering is not proof the engine works. This drives a real drag in the
    /// collection view demo and asserts the ordering actually changed.
    func testDraggingACellReordersTheCollectionView() {
        let app = XCUIApplication()
        app.launch()

        let row = app.tables.staticTexts["Collection View"]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()

        let cells = app.collectionViews.cells
        XCTAssertTrue(cells.element(boundBy: 0).waitForExistence(timeout: 5))

        let firstLabelBefore = cells.element(boundBy: 0).staticTexts.element(boundBy: 0).label
        let fourthCell = cells.element(boundBy: 3)
        XCTAssertTrue(fourthCell.exists)

        // kDragPickupBeginDelay is 0.12s for anything inside a scroll view, so
        // the press must be held before moving or DragDropGesture fails. The
        // velocity/hold form also generates the intermediate touchesMoved events
        // the drag depends on; the short form can register as a scroll instead.
        cells.element(boundBy: 0)
            .coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            .press(forDuration: 0.6,
                   thenDragTo: fourthCell.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)),
                   withVelocity: .slow,
                   thenHoldForDuration: 1.2)

        // Let the drop animation settle.
        let settled = expectation(description: "drop settles")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { settled.fulfill() }
        wait(for: [settled], timeout: 5)

        let firstLabelAfter = cells.element(boundBy: 0).staticTexts.element(boundBy: 0).label
        XCTAssertNotEqual(firstLabelBefore, firstLabelAfter,
                          "Dragging the first cell away should change which item is first")
    }
}
