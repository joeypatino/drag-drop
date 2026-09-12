import XCTest
import UIKit
@testable import DemoKit

final class MasonryLayoutTests: XCTestCase {

    /// Two columns, no insets, 10pt gutter: each column is 45 wide in a 100
    /// wide grid, so the frames are exact numbers rather than approximations.
    private let metrics = MasonryLayout.Metrics(columns: 2,
                                                spacing: 10,
                                                inset: .zero)

    func testEqualHeightsPackAsAPlainGrid() {
        let frames = MasonryLayout.frames(for: [50, 50, 50, 50],
                                          in: 100,
                                          metrics: metrics)

        XCTAssertEqual(frames, [
            CGRect(x: 0,  y: 0,  width: 45, height: 50),
            CGRect(x: 55, y: 0,  width: 45, height: 50),
            CGRect(x: 0,  y: 60, width: 45, height: 50),
            CGRect(x: 55, y: 60, width: 45, height: 50),
        ])
    }

    /// The whole point of masonry: a tall first card leaves the right column
    /// shorter, so the next two both go right rather than one per row. A flow
    /// layout cannot do this, which is why Moodboard had gaps.
    func testTheShortestColumnTakesTheNextCard() {
        let frames = MasonryLayout.frames(for: [200, 50, 50, 50],
                                          in: 100,
                                          metrics: metrics)

        XCTAssertEqual(frames[0], CGRect(x: 0,  y: 0,   width: 45, height: 200))
        XCTAssertEqual(frames[1], CGRect(x: 55, y: 0,   width: 45, height: 50))
        XCTAssertEqual(frames[2], CGRect(x: 55, y: 60,  width: 45, height: 50),
                       "second card should stay in the shorter right column")
        XCTAssertEqual(frames[3], CGRect(x: 55, y: 120, width: 45, height: 50),
                       "and so should the third")
    }

    /// Deterministic, so a test can assert exact frames and a screenshot taken
    /// today matches one taken tomorrow.
    func testTiesGoToTheLeftmostColumn() {
        let frames = MasonryLayout.frames(for: [50, 50], in: 100, metrics: metrics)
        XCTAssertEqual(frames[0].minX, 0)
        XCTAssertEqual(frames[1].minX, 55)
    }

    func testInsetsMoveAndNarrowTheGrid() {
        let inset = MasonryLayout.Metrics(
            columns: 2, spacing: 10,
            inset: UIEdgeInsets(top: 12, left: 8, bottom: 20, right: 8))
        let frames = MasonryLayout.frames(for: [50, 50], in: 100, metrics: inset)

        XCTAssertEqual(frames[0], CGRect(x: 8,  y: 12, width: 37, height: 50))
        XCTAssertEqual(frames[1], CGRect(x: 55, y: 12, width: 37, height: 50))
    }

    func testContentHeightIsTheTallestColumnPlusTheBottomInset() {
        let inset = MasonryLayout.Metrics(
            columns: 2, spacing: 10,
            inset: UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0))
        let frames = MasonryLayout.frames(for: [200, 50], in: 100, metrics: inset)

        XCTAssertEqual(MasonryLayout.contentHeight(of: frames, metrics: inset), 220)
    }

    func testNoCardsIsJustTheInsets() {
        XCTAssertTrue(MasonryLayout.frames(for: [], in: 100, metrics: metrics).isEmpty)
        XCTAssertEqual(MasonryLayout.contentHeight(of: [], metrics: metrics), 0)
    }

    /// The property the whole design rests on: heights are indexed by position,
    /// so reordering the *cards* cannot move a tile. Packing the same heights
    /// twice must give byte-identical frames.
    func testPackingTheSameHeightsIsStable() {
        let heights: [CGFloat] = [80, 140, 95, 200, 60, 120]
        XCTAssertEqual(MasonryLayout.frames(for: heights, in: 100, metrics: metrics),
                       MasonryLayout.frames(for: heights, in: 100, metrics: metrics))
    }
}
