import XCTest

/// When a view is dragged out of a container and dropped somewhere else, the
/// views left behind must shuffle up to fill the slot it vacated. Before this
/// was fixed the 4x4 demo left a visible hole wherever the square had been.
final class GapClosingTests: XCTestCase {

    private let squareSize = CGSize(width: 40, height: 40)
    private let squareStride: CGFloat = 45
    private let squareMargin: CGFloat = 5
    private let columns = 4

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    // MARK: - 4x4

    /// The four drop targets, ordered top-left, top-right, bottom-left,
    /// bottom-right. They are the only plain views that share the largest
    /// repeated size on screen.
    private func quadrants(in app: XCUIApplication) -> [CGRect] {
        let others = app.descendants(matching: .other)
        var frames: [CGRect] = []

        for index in 0..<others.count {
            let frame = others.element(boundBy: index).frame
            if frame.width > 100 && frame.width < 250 && frame.height > 250 {
                frames.append(frame)
            }
        }

        return frames.sorted { ($0.minY, $0.minX) < ($1.minY, $1.minX) }
    }

    private func squares(in app: XCUIApplication, within quadrant: CGRect) -> [CGRect] {
        let others = app.descendants(matching: .other)
        var frames: [CGRect] = []

        for index in 0..<others.count {
            let frame = others.element(boundBy: index).frame
            guard frame.size == squareSize, quadrant.contains(frame) else { continue }
            frames.append(frame)
        }

        return frames.sorted { ($0.minY, $0.minX) < ($1.minY, $1.minX) }
    }

    /// Where the `index`-th square belongs in a quadrant, matching the flow the
    /// demo lays its squares out in.
    private func slot(_ index: Int, in quadrant: CGRect) -> CGRect {
        CGRect(x: quadrant.minX + squareMargin + squareStride * CGFloat(index % columns),
               y: quadrant.minY + squareMargin + squareStride * CGFloat(index / columns),
               width: squareSize.width, height: squareSize.height)
    }

    private func assertSquaresFillTheFirstSlots(_ found: [CGRect],
                                                in quadrant: CGRect,
                                                file: StaticString = #filePath,
                                                line: UInt = #line) {
        let expected = (0..<found.count).map { slot($0, in: quadrant) }
        XCTAssertEqual(found, expected,
                       "squares should occupy the first \(found.count) slots with no hole",
                       file: file, line: line)
    }

    func testDraggingASquareOutOfAQuadrantClosesTheGapItLeaves() {
        let app = XCUIApplication()
        app.launch()
        app.tables.staticTexts["4x4"].tap()

        let quadrantFrames = quadrants(in: app)
        XCTAssertEqual(quadrantFrames.count, 4, "expected the four drop targets")

        let topLeft = quadrantFrames[0]
        let topRight = quadrantFrames[1]

        let before = squares(in: app, within: topLeft)
        XCTAssertEqual(before.count, 5, "the demo puts five squares in TopLeft")
        assertSquaresFillTheFirstSlots(before, in: topLeft)

        // The first square, dropped into the empty middle of TopRight.
        let start = coordinate(CGPoint(x: before[0].midX, y: before[0].midY), in: app)
        let end = coordinate(CGPoint(x: topRight.midX, y: topRight.midY), in: app)

        start.press(forDuration: 1.0, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 2.0)
        sleep(2)

        attach(app, "4x4-after-drag")

        let after = squares(in: app, within: topLeft)
        XCTAssertEqual(after.count, 4, "one square should have left TopLeft")
        assertSquaresFillTheFirstSlots(after, in: topLeft)
    }

    // MARK: - Table View

    /// The table demo's Drop Target panel stacks the views dropped into it. Take
    /// the top one back out and the one under it has to move up.
    ///
    /// The blue views are plain UIViews with no accessibility, so this samples
    /// pixels: blue in a slot means a view is sitting there.
    func testDraggingAViewOutOfTheDropTargetPanelClosesTheGap() {
        let app = XCUIApplication()
        app.launch()
        app.tables.staticTexts["Table View"].tap()
        sleep(1)

        let window = app.windows.element(boundBy: 0).frame
        guard let panel = dropTargetPanel(in: app) else {
            return XCTFail("could not find the Drop Target panel")
        }

        let firstSlot = slotRegion(0, in: panel, of: window)
        let secondSlot = slotRegion(1, in: panel, of: window)

        XCTAssertFalse(isBlue(app, firstSlot), "the panel should start empty")
        XCTAssertFalse(isBlue(app, secondSlot), "the panel should start empty")

        // Two rows dragged across, so the panel holds a stack of two.
        dragRow(at: 0, of: app, into: panel, in: window)
        dragRow(at: 1, of: app, into: panel, in: window)

        XCTAssertTrue(isBlue(app, firstSlot), "the first drop should fill the top slot")
        XCTAssertTrue(isBlue(app, secondSlot), "the second drop should fill the slot below")

        // Send the top one back to a row well below the two now empty.
        coordinate(CGPoint(x: panel.midX, y: panel.minY + 40), in: app)
            .press(forDuration: 0.6,
                   thenDragTo: coordinate(CGPoint(x: window.width * 0.25,
                                                  y: window.height * 0.65), in: app),
                   withVelocity: .slow,
                   thenHoldForDuration: 1.2)
        sleep(2)

        attach(app, "panel-after-drag-out")

        XCTAssertTrue(isBlue(app, firstSlot),
                      "the view below should have moved up into the vacated slot")
        XCTAssertFalse(isBlue(app, secondSlot),
                       "the slot it came from should now be empty")
    }

    /// Drags the blue view out of table row `row` into the panel. Rows are 90
    /// tall and the panel's top edge lines up with the table's.
    private func dragRow(at row: Int, of app: XCUIApplication, into panel: CGRect, in window: CGRect) {
        let start = CGPoint(x: window.width * 0.25,
                            y: panel.minY - 10 + CGFloat(row) * 90 + 45)

        coordinate(start, in: app)
            .press(forDuration: 0.6,
                   thenDragTo: coordinate(CGPoint(x: panel.midX, y: panel.midY), in: app),
                   withVelocity: .slow,
                   thenHoldForDuration: 1.2)
        sleep(1)
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

    /// The middle of the `index`-th panel slot, normalised for screenshot
    /// sampling. Slots are 70 tall with a 5 point margin and gap.
    private func slotRegion(_ index: Int, in panel: CGRect, of window: CGRect) -> CGRect {
        let slot = CGRect(x: panel.minX + squareMargin,
                          y: panel.minY + squareMargin + CGFloat(index) * (70 + squareMargin),
                          width: panel.width - 2 * squareMargin,
                          height: 70)
        let sample = slot.insetBy(dx: slot.width * 0.25, dy: slot.height * 0.3)

        return CGRect(x: sample.minX / window.width, y: sample.minY / window.height,
                      width: sample.width / window.width, height: sample.height / window.height)
    }

    private func isBlue(_ app: XCUIApplication, _ region: CGRect) -> Bool {
        let colour = meanColor(app.screenshot(), region)
        return colour.b - colour.r > 40
    }

    /// Mean colour of a normalised region of the screenshot.
    private func meanColor(_ screenshot: XCUIScreenshot, _ region: CGRect) -> (r: Double, g: Double, b: Double) {
        guard let cg = screenshot.image.cgImage else { return (0, 0, 0) }

        let crop = CGRect(x: region.minX * CGFloat(cg.width),
                          y: region.minY * CGFloat(cg.height),
                          width: region.width * CGFloat(cg.width),
                          height: region.height * CGFloat(cg.height))
        guard let cropped = cg.cropping(to: crop) else { return (0, 0, 0) }

        var pixel = [UInt8](repeating: 0, count: 4)
        guard let ctx = CGContext(data: &pixel, width: 1, height: 1,
                                  bitsPerComponent: 8, bytesPerRow: 4,
                                  space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { return (0, 0, 0) }

        ctx.interpolationQuality = .medium
        ctx.draw(cropped, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        return (Double(pixel[0]), Double(pixel[1]), Double(pixel[2]))
    }

    // MARK: - Double Collection View

    /// The collection views already close their own gap. This pins that down so
    /// the new re-flow -- which a collection view's drop target opts out of --
    /// cannot start fighting UIKit for the layout.
    func testDraggingACellOutOfACollectionViewClosesTheGap() {
        let app = XCUIApplication()
        app.launch()
        app.tables.staticTexts["Double Collection View"].tap()

        let cells = app.collectionViews.cells
        XCTAssertTrue(cells.element(boundBy: 0).waitForExistence(timeout: 5))

        let leftBefore = leftColumn(of: app)
        XCTAssertEqual(leftBefore.map(\.label), ["0", "1", "2", "3", "4", "5", "6", "7"])
        let slots = leftBefore.map(\.frame)

        let window = app.windows.element(boundBy: 0)
        cells.element(boundBy: 0)
            .coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            .press(forDuration: 0.6,
                   thenDragTo: window.coordinate(withNormalizedOffset: CGVector(dx: 0.75, dy: 0.3)),
                   withVelocity: .slow,
                   thenHoldForDuration: 1.2)
        sleep(2)

        attach(app, "double-collection-after-drag")

        let leftAfter = leftColumn(of: app)
        XCTAssertEqual(leftAfter.map(\.label), ["1", "2", "3", "4", "5", "6", "7"],
                       "item 0 should have left and the rest closed up")
        XCTAssertEqual(leftAfter.map(\.frame), Array(slots.prefix(leftAfter.count)),
                       "the survivors should occupy the first slots, leaving no hole")
    }

    private func leftColumn(of app: XCUIApplication) -> [(label: String, frame: CGRect)] {
        let cells = app.collectionViews.cells
        let midX = app.windows.element(boundBy: 0).frame.midX

        var found: [(label: String, frame: CGRect)] = []
        for index in 0..<cells.count {
            let cell = cells.element(boundBy: index)
            let frame = cell.frame
            guard frame.midX < midX else { continue }
            found.append((cell.staticTexts.element(boundBy: 0).label, frame))
        }

        return found.sorted { ($0.frame.minY, $0.frame.minX) < ($1.frame.minY, $1.frame.minX) }
    }

    // MARK: - Helpers

    private func coordinate(_ point: CGPoint, in app: XCUIApplication) -> XCUICoordinate {
        app.windows.element(boundBy: 0)
            .coordinate(withNormalizedOffset: .zero)
            .withOffset(CGVector(dx: point.x, dy: point.y))
    }

    private func attach(_ app: XCUIApplication, _ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }
}
