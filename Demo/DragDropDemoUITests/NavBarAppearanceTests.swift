import XCTest

/// The navigation bar was rendering black on the pushed demo screens: iOS 26
/// defaults bars to a transparent background, and these storyboard scenes lay
/// out below the bar, so the nil-backgrounded window showed through.
final class NavBarAppearanceTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // These two assert on rendered pixels, so they have to pin the
        // appearance rather than inherit whatever the simulator was last
        // left in -- a dark-mode simulator makes the nav bar legitimately
        // black and the test legitimately wrong.
        XCUIDevice.shared.appearance = .light
    }

    /// Mean colour of a normalised region of a screenshot.
    private func meanColor(_ screenshot: XCUIScreenshot, _ region: CGRect) -> (r: Double, g: Double, b: Double) {
        guard let cg = screenshot.image.cgImage else { return (0, 0, 0) }
        let crop = CGRect(x: region.minX * CGFloat(cg.width),
                          y: region.minY * CGFloat(cg.height),
                          width: region.width * CGFloat(cg.width),
                          height: region.height * CGFloat(cg.height))
        guard let cropped = cg.cropping(to: crop) else { return (0, 0, 0) }
        var px = [UInt8](repeating: 0, count: 4)
        guard let ctx = CGContext(data: &px, width: 1, height: 1, bitsPerComponent: 8,
                                  bytesPerRow: 4, space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { return (0, 0, 0) }
        ctx.interpolationQuality = .medium
        ctx.draw(cropped, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        return (Double(px[0]), Double(px[1]), Double(px[2]))
    }

    /// The bar area, avoiding the back button on the left.
    private let barRegion = CGRect(x: 0.35, y: 0.055, width: 0.55, height: 0.03)

    private let demos = [
        "Shift Rota", "Shared Album", "Widget Composer",
        "Files", "Up Next", "Moodboard", "Lineup"
    ]

    func testNavigationBarIsNotBlackOnAnyDemoScreen() {
        let app = XCUIApplication()
        app.launch()

        for title in demos {
            let row = app.tables.staticTexts[title]
            XCTAssertTrue(row.waitForExistence(timeout: 5), "Missing row: \(title)")
            row.tap()
            sleep(1)

            let c = meanColor(app.screenshot(), barRegion)
            XCTAssertGreaterThan(min(c.r, c.g, c.b), 100,
                                 "Navigation bar renders dark on \(title): \(c)")

            app.navigationBars.buttons.element(boundBy: 0).tap()
            sleep(1)
        }
    }
}
