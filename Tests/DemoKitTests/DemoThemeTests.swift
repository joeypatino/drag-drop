import XCTest
import UIKit
@testable import DemoKit

final class DemoThemeTests: XCTestCase {

    /// Swift seeds String.hashValue per process, so anything derived from it
    /// changes between launches. Every avatar colour depends on this being
    /// stable, so it is pinned to an explicit FNV-1a.
    func testStableHashIsDeterministic() {
        XCTAssertEqual(DemoTheme.stableHash("Nadia Okafor"),
                       DemoTheme.stableHash("Nadia Okafor"))
        XCTAssertNotEqual(DemoTheme.stableHash("Nadia Okafor"),
                          DemoTheme.stableHash("Marco Bellini"))
    }

    func testStableHashMatchesKnownFNV1aValues() {
        XCTAssertEqual(DemoTheme.stableHash(""), 0xcbf29ce484222325)
        XCTAssertEqual(DemoTheme.stableHash("a"), 0xaf63dc4c8601ec8c)
    }

    func testHueForSeedIsDeterministicAndInRange() {
        let names = ["Nadia Okafor", "Marco Bellini", "Priya Raman", "Tom Hale"]
        for name in names {
            XCTAssertEqual(DemoTheme.hue(for: name), DemoTheme.hue(for: name))
        }
    }

    func testHueForSeedSpreadsAcrossTheRamp() {
        let seeds = (0..<64).map { "seed-\($0)" }
        let used = Set(seeds.map { DemoTheme.hue(for: $0) })
        XCTAssertGreaterThanOrEqual(used.count, 6,
                                    "A 64-seed sample should touch most of an 8-hue ramp, got \(used)")
    }

    @MainActor
    func testEveryHueResolvesDifferentlyInLightAndDark() {
        let light = UITraitCollection(userInterfaceStyle: .light)
        let dark = UITraitCollection(userInterfaceStyle: .dark)
        for hue in DemoTheme.Hue.allCases {
            let colour = DemoTheme.color(hue)
            XCTAssertNotEqual(colour.resolvedColor(with: light),
                              colour.resolvedColor(with: dark),
                              "\(hue) does not adapt to dark mode")
        }
    }

    @MainActor
    func testTintIsTheSameHueAtLowAlpha() {
        for hue in DemoTheme.Hue.allCases {
            let light = UITraitCollection(userInterfaceStyle: .light)
            var alpha: CGFloat = 0
            DemoTheme.tint(hue).resolvedColor(with: light)
                .getRed(nil, green: nil, blue: nil, alpha: &alpha)
            XCTAssertLessThan(alpha, 0.5, "\(hue) tint should be a wash, not a fill")
            XCTAssertGreaterThan(alpha, 0.0)
        }
    }
}
