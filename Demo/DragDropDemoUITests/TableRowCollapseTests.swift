import XCTest

/// Dragging a row's view into the Drop Target panel used to leave a blank 90pt
/// band behind: the table's row count was hardcoded, so nothing could shrink
/// it. Worse, scrolling the emptied rows off screen and back manufactured fresh
/// views in them.
final class TableRowCollapseTests: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    // MARK: - Helpers

    private func coordinate(_ point: CGPoint, in app: XCUIApplication) -> XCUICoordinate {
        app.windows.element(boundBy: 0)
            .coordinate(withNormalizedOffset: .zero)
            .withOffset(CGVector(dx: point.x, dy: point.y))
    }

    /// Mean colour of a normalised region of the screenshot. The blue views are
    /// plain UIViews with no accessibility, so pixels are the only evidence.
    private func meanColor(_ screenshot: XCUIScreenshot, _ region: CGRect) -> (r: Double, b: Double) {
        guard let cg = screenshot.image.cgImage else { return (0, 0) }

        let crop = CGRect(x: region.minX * CGFloat(cg.width), y: region.minY * CGFloat(cg.height),
                          width: region.width * CGFloat(cg.width), height: region.height * CGFloat(cg.height))
        guard let cropped = cg.cropping(to: crop) else { return (0, 0) }

        var pixel = [UInt8](repeating: 0, count: 4)
        guard let ctx = CGContext(data: &pixel, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
                                  space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return (0, 0) }

        ctx.interpolationQuality = .medium
        ctx.draw(cropped, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        return (Double(pixel[0]), Double(pixel[2]))
    }

    /// The bordered panel on the right half: the tallest plain view over there.
    private func dropTargetPanel(in app: XCUIApplication) -> CGRect? {
        let midX = app.windows.element(boundBy: 0).frame.midX
        let others = app.descendants(matching: .other)

        var best: CGRect?
        for index in 0..<others.count {
            let frame = others.element(boundBy: index).frame
            guard frame.minX > midX, frame.height > 400, frame.width < midX else { continue }
            if best == nil || frame.height > best!.height { best = frame }
        }

        return best
    }

    /// Whether the `row`-th 90pt band of the table holds a blue view.
    private func rowIsFilled(_ app: XCUIApplication, row: Int, tableTop: CGFloat) -> Bool {
        let window = app.windows.element(boundBy: 0).frame
        let y = (tableTop + CGFloat(row) * 90 + 45) / window.height
        let colour = meanColor(app.screenshot(), CGRect(x: 0.10, y: y, width: 0.20, height: 0.01))
        return colour.b - colour.r > 40
    }

    private func dragRow(_ row: Int, of app: XCUIApplication, toPanel panel: CGRect, tableTop: CGFloat) {
        let window = app.windows.element(boundBy: 0).frame

        coordinate(CGPoint(x: window.width * 0.25, y: tableTop + CGFloat(row) * 90 + 45), in: app)
            .press(forDuration: 0.6,
                   thenDragTo: coordinate(CGPoint(x: panel.midX, y: panel.midY), in: app),
                   withVelocity: .slow,
                   thenHoldForDuration: 1.2)
        sleep(2)
    }

    private func attach(_ app: XCUIApplication, _ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }

    private func openTableDemo() -> (app: XCUIApplication, panel: CGRect, tableTop: CGFloat) {
        let app = XCUIApplication()
        app.launch()
        app.tables.staticTexts["Table View"].tap()
        sleep(1)

        guard let panel = dropTargetPanel(in: app) else {
            XCTFail("could not find the Drop Target panel")
            return (app, .zero, 0)
        }

        // The panel is inset 20pt inside the same frame the table fills, so the
        // table's first row starts 20pt above the panel's top edge.
        return (app, panel, panel.minY - 20)
    }

    /// The item numbers showing in the table's rows, top to bottom. The panel's
    /// own "Drop Target" caption and any view sitting in it are excluded by
    /// taking only the left half.
    private func tableLabels(in app: XCUIApplication) -> [String] {
        let window = app.windows.element(boundBy: 0).frame
        let texts = app.staticTexts

        var found: [(y: CGFloat, label: String)] = []
        for index in 0..<texts.count {
            let element = texts.element(boundBy: index)
            let frame = element.frame

            // A cell that exists but has not been laid out reports a
            // degenerate frame pinned to the table's top-left corner. A real
            // row label is centred in its blue view, around x = 95.
            guard !frame.isEmpty, frame.minX > 20,
                  frame.midX < window.midX,
                  frame.minY >= 0, frame.maxY <= window.height,
                  Int(element.label) != nil else { continue }

            found.append((frame.minY, element.label))
        }

        return found.sorted { $0.y < $1.y }.map(\.label)
    }

    // MARK: - Tests

    /// The whole point: the table gets shorter and the rows below move up.
    func testDraggingRowsOutCollapsesTheTable() {
        let (app, panel, tableTop) = openTableDemo()

        XCTAssertEqual(tableLabels(in: app), ["0", "1", "2", "3", "4", "5", "6", "7"],
                       "precondition: the first eight rows are on screen")

        dragRow(0, of: app, toPanel: panel, tableTop: tableTop)
        dragRow(0, of: app, toPanel: panel, tableTop: tableTop)

        attach(app, "table-after-two-rows-removed")

        // Had the rows merely been emptied, 0 and 1 would still be here as
        // blank bands and the second drag would have grabbed nothing. Two more
        // rows have scrolled up into view, which only happens if the table
        // actually got shorter.
        XCTAssertEqual(tableLabels(in: app), ["2", "3", "4", "5", "6", "7", "8", "9"],
                       "the rows below should have moved up, leaving no blank band")

        XCTAssertTrue(rowIsFilled(app, row: 0, tableTop: tableTop),
                      "the top band should hold a view, not a hole")
    }

    /// The rows stayed gone rather than being manufactured again by
    /// cellForRowAt, which is what used to happen.
    func testTheRemovedRowsDoNotComeBackOnScroll() {
        let (app, panel, tableTop) = openTableDemo()

        dragRow(0, of: app, toPanel: panel, tableTop: tableTop)
        dragRow(0, of: app, toPanel: panel, tableTop: tableTop)

        let table = app.tables.element(boundBy: 0)
        for _ in 0..<3 { table.swipeUp(velocity: .slow); sleep(1) }
        for _ in 0..<6 { table.swipeDown(velocity: .slow); sleep(1) }
        sleep(2)

        attach(app, "table-after-scroll-round-trip")

        XCTAssertEqual(tableLabels(in: app), ["2", "3", "4", "5", "6", "7", "8", "9"],
                       "0 and 1 should still be gone after scrolling away and back")
    }

    /// And the other direction: a view dragged off the panel onto the table
    /// makes a row appear.
    func testDraggingAViewOntoTheTableInsertsARow() {
        let (app, panel, tableTop) = openTableDemo()
        let window = app.windows.element(boundBy: 0).frame

        dragRow(0, of: app, toPanel: panel, tableTop: tableTop)
        XCTAssertEqual(tableLabels(in: app), ["1", "2", "3", "4", "5", "6", "7", "8"],
                       "precondition: one row shorter")

        // Off the panel's top slot, back onto the fourth row of the table.
        coordinate(CGPoint(x: panel.midX, y: panel.minY + 40), in: app)
            .press(forDuration: 0.6,
                   thenDragTo: coordinate(CGPoint(x: window.width * 0.25,
                                                  y: tableTop + 3 * 90 + 45), in: app),
                   withVelocity: .slow,
                   thenHoldForDuration: 1.2)
        sleep(2)

        attach(app, "table-after-row-inserted")

        // The demo numbers a newly inserted item 10, and it lands where the
        // finger was.
        XCTAssertEqual(tableLabels(in: app), ["1", "2", "3", "10", "4", "5", "6", "7"],
                       "a row should have appeared at the drop point")
    }
}
