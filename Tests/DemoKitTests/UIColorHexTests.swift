import XCTest
import UIKit
@testable import DemoKit

final class UIColorHexTests: XCTestCase {

    private func rgb(_ color: UIColor) -> (r: CGFloat, g: CGFloat, b: CGFloat) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (r, g, b)
    }

    func testParsesSixDigitHexWithAndWithoutAHash() {
        let withHash = UIColor(hex: "#E86A4A")
        let without = UIColor(hex: "E86A4A")
        XCTAssertNotNil(withHash)
        XCTAssertEqual(withHash, without)
    }

    func testChannelsLandInTheRightOrder() {
        let colour = UIColor(hex: "#FF8000")!
        let (r, g, b) = rgb(colour)
        XCTAssertEqual(r, 1.0, accuracy: 0.01)
        XCTAssertEqual(g, 128.0 / 255.0, accuracy: 0.01)
        XCTAssertEqual(b, 0.0, accuracy: 0.01)
    }

    func testMalformedHexIsRejectedRatherThanGuessed() {
        XCTAssertNil(UIColor(hex: ""))
        XCTAssertNil(UIColor(hex: "#FFF"))
        XCTAssertNil(UIColor(hex: "#GGGGGG"))
        XCTAssertNil(UIColor(hex: "#E86A4AFF"))
    }

    func testEverySamplePaletteHexParses() {
        for palette in SampleData.palettes {
            XCTAssertNotNil(UIColor(hex: palette.hex), "\(palette.name): \(palette.hex)")
        }
    }

    func testTheGradientPartnerIsDarkerButRecognisablyTheSameColour() {
        for palette in SampleData.palettes {
            let base = UIColor(hex: palette.hex)!
            var baseBrightness: CGFloat = 0, partnerBrightness: CGFloat = 0
            var baseHue: CGFloat = 0, partnerHue: CGFloat = 0
            var s: CGFloat = 0, a: CGFloat = 0

            base.getHue(&baseHue, saturation: &s, brightness: &baseBrightness, alpha: &a)
            base.gradientPartner.getHue(&partnerHue, saturation: &s,
                                        brightness: &partnerBrightness, alpha: &a)

            XCTAssertLessThan(partnerBrightness, baseBrightness, palette.name)
            // Within a twentieth of the wheel, wrapping at 1.0.
            let shift = min(abs(partnerHue - baseHue), 1 - abs(partnerHue - baseHue))
            XCTAssertLessThanOrEqual(shift, 0.06, palette.name)
        }
    }
}
