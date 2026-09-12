import XCTest

final class DragDropDemoUITests: XCTestCase {

    private let exampleTitles = [
        "Shift Rota",
        "Shared Album",
        "Widget Composer",
        "Files",
        "Up Next",
        "Moodboard",
        "Lineup"
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
    /// moodboard and asserts the ordering actually changed.
    @MainActor
    func testDraggingACellReordersTheCollectionView() {
        let app = launchDemo("CollectionRearrangeViewController")

        let grid = container("moodboard", in: app)
        XCTAssertTrue(grid.waitForExistence(timeout: 5))

        // By identifier and visual position, not by `boundBy`: that orders by
        // the accessibility hierarchy, so "cell 1" need not be the cell on
        // screen at position 1.
        let before = identifiers(withPrefix: "swatch-", inside: grid, of: app)
        XCTAssertGreaterThan(before.count, 3, "the grid should be showing cards")

        drag(app.otherElements[before[0]], onto: app.otherElements[before[3]])

        let after = identifiers(withPrefix: "swatch-", inside: grid, of: app)
        XCTAssertNotEqual(before.first, after.first,
                          "dragging the first card away should change which card is first")
        XCTAssertEqual(Set(after).count, after.count, "a card is drawn twice: \(after)")
    }
}
