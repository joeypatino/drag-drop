import XCTest

final class DragDropDemoUITests: XCTestCase {

    /// Extended to all seven once the collection view demos land.
    private let exampleTitles = [
        "4x4",
        "Container-Embedded",
        "Container-2xEmbedded",
        "Drop Target Embedded",
        "Table View"
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
}
