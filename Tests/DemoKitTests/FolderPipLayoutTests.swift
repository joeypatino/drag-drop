import XCTest
import UIKit
@testable import DemoKit

final class FolderPipLayoutTests: XCTestCase {

    private let folder = CGRect(x: 0, y: 0, width: 72, height: 72)

    func testTheGridIsCentredInTheFolder() {
        // Two 24pt pips with a 4pt gap is a 52pt block in a 72pt tile,
        // so the block starts 10pt in on both axes.
        let first = FolderPipLayout.frame(at: 0, in: folder)
        XCTAssertEqual(first, CGRect(x: 10, y: 10, width: 24, height: 24))
    }

    func testPipsFillLeftToRightThenWrap() {
        XCTAssertEqual(FolderPipLayout.frame(at: 1, in: folder)?.origin, CGPoint(x: 38, y: 10))
        XCTAssertEqual(FolderPipLayout.frame(at: 2, in: folder)?.origin, CGPoint(x: 10, y: 38))
        XCTAssertEqual(FolderPipLayout.frame(at: 3, in: folder)?.origin, CGPoint(x: 38, y: 38))
    }

    func testTheGridHoldsFour() {
        XCTAssertEqual(FolderPipLayout.capacity, 4)
        XCTAssertNotNil(FolderPipLayout.frame(at: 3, in: folder))
    }

    func testBeyondCapacityThereIsNoFrame() {
        // The folder keeps counting in its badge; the fifth file is simply
        // not drawn.
        XCTAssertNil(FolderPipLayout.frame(at: 4, in: folder))
        XCTAssertNil(FolderPipLayout.frame(at: 99, in: folder))
    }

    func testNegativeIndexHasNoFrame() {
        XCTAssertNil(FolderPipLayout.frame(at: -1, in: folder))
    }

    func testPipsNeverOverlap() {
        let frames = (0..<FolderPipLayout.capacity).compactMap {
            FolderPipLayout.frame(at: $0, in: folder)
        }
        XCTAssertEqual(frames.count, 4)
        for (i, a) in frames.enumerated() {
            for b in frames[(i + 1)...] {
                XCTAssertFalse(a.intersects(b), "pips overlap: \(a) and \(b)")
            }
        }
    }

    func testEveryPipStaysInsideTheFolder() {
        for index in 0..<FolderPipLayout.capacity {
            let pip = FolderPipLayout.frame(at: index, in: folder)!
            XCTAssertTrue(folder.contains(pip), "pip \(index) escapes the folder: \(pip)")
        }
    }
}
