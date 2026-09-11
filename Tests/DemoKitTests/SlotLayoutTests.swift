import XCTest
import UIKit
@testable import DemoKit

/// Three callers depend on this function agreeing with itself: the initial
/// population, the frame an arriving view is given, and the frames the
/// survivors take when one is dragged away. Disagreement leaves a container
/// with a hole, or two views in one slot.
@MainActor
final class SlotLayoutTests: XCTestCase {

    private func container(width: CGFloat, height: CGFloat = 400) -> UIView {
        UIView(frame: CGRect(x: 0, y: 0, width: width, height: height))
    }

    private let square = CGSize(width: 40, height: 40)

    func testFirstSlotSitsAtTheMargin() {
        let frame = SlotLayout.frame(at: 0, size: square, in: container(width: 200))
        XCTAssertEqual(frame, CGRect(x: 5, y: 5, width: 40, height: 40))
    }

    func testSlotsRunLeftToRightBySizePlusSpacing() {
        let view = container(width: 200)
        XCTAssertEqual(SlotLayout.frame(at: 1, size: square, in: view).origin,
                       CGPoint(x: 50, y: 5))
        XCTAssertEqual(SlotLayout.frame(at: 3, size: square, in: view).origin,
                       CGPoint(x: 140, y: 5))
    }

    func testTheRunWrapsWhenTheRowIsFull() {
        // 200pt wide fits four 40pt squares at 5pt margin and 5pt spacing.
        let frame = SlotLayout.frame(at: 4, size: square, in: container(width: 200))
        XCTAssertEqual(frame.origin, CGPoint(x: 5, y: 50))
    }

    func testNegativeIndexIsClampedToTheFirstSlot() {
        XCTAssertEqual(SlotLayout.frame(at: -3, size: square, in: container(width: 200)),
                       SlotLayout.frame(at: 0, size: square, in: container(width: 200)))
    }

    func testTheSizeArgumentOverridesTheMetricsItemSize() {
        // The table demo's panel is one slot wide: it passes a panel-width size
        // while still using standard margins.
        let wide = CGSize(width: 180, height: 70)
        let frame = SlotLayout.frame(at: 1, size: wide, in: container(width: 200))
        XCTAssertEqual(frame, CGRect(x: 5, y: 80, width: 180, height: 70))
    }

    func testChipMetricsUseTheirOwnMarginAndSpacing() {
        let chip = CGSize(width: 44, height: 44)
        let frame = SlotLayout.frame(at: 1, size: chip,
                                     in: container(width: 300), metrics: .chip)
        XCTAssertEqual(frame.origin, CGPoint(x: 12 + 44 + 10, y: 12))
    }

    func testSlotsNeverOverlap() {
        let view = container(width: 200)
        let frames = (0..<12).map { SlotLayout.frame(at: $0, size: square, in: view) }
        for (i, a) in frames.enumerated() {
            for b in frames[(i + 1)...] {
                XCTAssertFalse(a.intersects(b), "slots overlap: \(a) and \(b)")
            }
        }
    }
}
