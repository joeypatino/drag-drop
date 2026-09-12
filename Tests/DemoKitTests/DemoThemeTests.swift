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

    func testStableMixIsDeterministic() {
        XCTAssertEqual(DemoTheme.stableMix(42), DemoTheme.stableMix(42))
        XCTAssertNotEqual(DemoTheme.stableMix(42), DemoTheme.stableMix(43))
    }

    /// The bug this exists to prevent: a hash whose low bits track its input
    /// turns consecutive indices into an arithmetic run, and a masonry seeded
    /// from it lays out as a plain grid.
    func testStableMixDoesNotStepEvenlyAcrossConsecutiveIndices() {
        let values = (0..<300).map { Int(DemoTheme.stableMix($0) % 121) }
        let steps = zip(values, values.dropFirst()).map { $1 - $0 }

        var longestRun = 1
        var run = 1
        for (previous, step) in zip(steps, steps.dropFirst()) {
            run = step == previous ? run + 1 : 1
            longestRun = max(longestRun, run)
        }
        XCTAssertLessThan(longestRun, 4,
                          "\(longestRun) consecutive indices stepped by the same amount")

        let mean = steps.map { abs($0) }.reduce(0, +) / steps.count
        XCTAssertGreaterThan(mean, 25,
                             "Neighbouring indices should land far apart, mean step was \(mean)")
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

    /// The well has to read as a recess in both appearances, so it is defined
    /// against the card it sits in rather than as a fixed grey.
    @MainActor
    func testTheWellDiffersFromTheCardInBothAppearances() {
        for style in [UIUserInterfaceStyle.light, .dark] {
            let traits = UITraitCollection(userInterfaceStyle: style)
            let card = DemoTheme.Surface.card.resolvedColor(with: traits)
            let well = DemoTheme.Surface.well.resolvedColor(with: traits)
            XCTAssertNotEqual(card, well, "well is invisible against the card in \(style)")
        }
    }

    /// A well inside a well is how Shared Album shows a target inside a target,
    /// so the recess cannot be so faint that the second one disappears.
    @MainActor
    func testTheWellIsVisibleButNotAFill() {
        for style in [UIUserInterfaceStyle.light, .dark] {
            let traits = UITraitCollection(userInterfaceStyle: style)
            var alpha: CGFloat = 0
            DemoTheme.Surface.well.resolvedColor(with: traits)
                .getWhite(nil, alpha: &alpha)
            XCTAssertGreaterThan(alpha, 0.02, "well is too faint to see in \(style)")
            XCTAssertLessThan(alpha, 0.2, "well should be a recess, not a surface")
        }
    }
}
