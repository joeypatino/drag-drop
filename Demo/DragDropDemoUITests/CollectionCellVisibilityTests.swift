import XCTest

/// The collection view demos draw white cells. The original relied on
/// UICollectionView's old default black background to separate them; modern iOS
/// defaults it to white, which made the cells invisible. These sample the
/// continuous vertical gutter between the two columns, which must be darker
/// than the cells either side of it.
final class CollectionCellVisibilityTests: XCTestCase {

    private func meanColor(_ screenshot: XCUIScreenshot, _ region: CGRect) -> (r: Double, g: Double, b: Double) {
        guard let cg = screenshot.image.cgImage else { return (255, 255, 255) }
        let crop = CGRect(x: region.minX * CGFloat(cg.width),
                          y: region.minY * CGFloat(cg.height),
                          width: region.width * CGFloat(cg.width),
                          height: region.height * CGFloat(cg.height))
        guard let cropped = cg.cropping(to: crop) else { return (255, 255, 255) }
        var px = [UInt8](repeating: 0, count: 4)
        guard let ctx = CGContext(data: &px, width: 1, height: 1, bitsPerComponent: 8,
                                  bytesPerRow: 4, space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { return (255, 255, 255) }
        ctx.interpolationQuality = .medium
        ctx.draw(cropped, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        return (Double(px[0]), Double(px[1]), Double(px[2]))
    }

    private func assertCellsAreDistinguishable(_ title: String,
                                               gutter: CGRect,
                                               cell: CGRect,
                                               file: StaticString = #filePath,
                                               line: UInt = #line) {
        let app = XCUIApplication()
        app.launch()
        app.tables.staticTexts[title].tap()
        sleep(2)

        let shot = app.screenshot()
        let a = XCTAttachment(screenshot: shot); a.name = title; a.lifetime = .keepAlways; add(a)

        let gutterColor = meanColor(shot, gutter)
        let cellColor = meanColor(shot, cell)
        let contrast = cellColor.r - gutterColor.r

        XCTAssertGreaterThan(contrast, 60,
                             "Cells are not distinguishable from the collection view background in \(title): cell \(cellColor) vs gutter \(gutterColor)",
                             file: file, line: line)
    }

    func testCollectionViewCellsAreVisible() {
        // Single collection view: the gutter between the two columns sits at x = 0.5.
        assertCellsAreDistinguishable("Collection View",
                                      gutter: CGRect(x: 0.494, y: 0.30, width: 0.012, height: 0.30),
                                      cell: CGRect(x: 0.20, y: 0.30, width: 0.10, height: 0.30))
    }

    func testDoubleCollectionViewCellsAreVisible() {
        // Left collection view occupies the left half; its gutter is at x = 0.25.
        assertCellsAreDistinguishable("Double Collection View",
                                      gutter: CGRect(x: 0.244, y: 0.30, width: 0.012, height: 0.20),
                                      cell: CGRect(x: 0.10, y: 0.30, width: 0.08, height: 0.20))
    }
}
