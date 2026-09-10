import XCTest

/// Regression test for the table view demo. The draggable views are plain
/// UIViews with no accessibility, so the assertion samples pixels: a blue view
/// appearing inside the Drop Target panel is proof the drop happened.
final class TableViewDragTests: XCTestCase {

    /// Mean colour of a normalised region of the screenshot.
    private func meanColor(_ screenshot: XCUIScreenshot,
                           _ region: CGRect) -> (r: Double, g: Double, b: Double) {
        let image = screenshot.image
        guard let cg = image.cgImage else { return (0, 0, 0) }

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

    /// Where a dropped view lands inside the Drop Target panel: the datasource
    /// places the first one at y=5 in the panel, 151x70 points.
    private let dropTargetRegion = CGRect(x: 0.60, y: 0.175, width: 0.30, height: 0.055)

    func testDraggingARowIntoTheDropTargetMovesIt() {
        let app = XCUIApplication()
        app.launch()
        app.tables.staticTexts["Table View"].tap()
        sleep(1)

        let before = meanColor(app.screenshot(), dropTargetRegion)
        XCTAssertLessThan(before.b - before.r, 40,
                          "Drop target should start with no blue view in it (got \(before))")

        let window = app.windows.element(boundBy: 0)
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.2496, dy: 0.1840))
            .press(forDuration: 0.6,
                   thenDragTo: window.coordinate(withNormalizedOffset: CGVector(dx: 0.7496, dy: 0.5296)),
                   withVelocity: .slow,
                   thenHoldForDuration: 1.2)
        sleep(2)

        let shot = app.screenshot()
        let a = XCTAttachment(screenshot: shot); a.name = "table-after-drop"; a.lifetime = .keepAlways; add(a)
        let after = meanColor(shot, dropTargetRegion)
        XCTAssertGreaterThan(after.b - after.r, 40,
                             "A blue row view should now sit inside the Drop Target (got \(after))")
    }
}
