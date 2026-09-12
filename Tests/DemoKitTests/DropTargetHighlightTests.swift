import XCTest
import UIKit
@testable import DemoKit

@MainActor
final class DropTargetHighlightTests: XCTestCase {

    /// roll
    ///   album
    /// bench          (a peer, in no relation to either)
    private func scene() -> (roll: UIView, album: UIView, bench: UIView) {
        let roll = UIView()
        let album = UIView()
        let bench = UIView()
        roll.addSubview(album)
        return (roll, album, bench)
    }

    func testTheArmedTargetIsArmed() {
        let (roll, album, _) = scene()
        XCTAssertEqual(DropTargetHighlight.state(of: album, whenArmed: album), .armed)
        XCTAssertEqual(DropTargetHighlight.state(of: roll, whenArmed: roll), .armed)
    }

    /// The whole point: the roll did not lose because the drag left it, it lost
    /// to a target inside itself. That is what `drained` says.
    func testATargetContainingTheArmedOneDrains() {
        let (roll, album, _) = scene()
        XCTAssertEqual(DropTargetHighlight.state(of: roll, whenArmed: album), .drained)
    }

    func testAPeerIsIdleRatherThanDrained() {
        let (_, album, bench) = scene()
        XCTAssertEqual(DropTargetHighlight.state(of: bench, whenArmed: album), .idle)
    }

    /// A target inside the armed one is not draining -- it did not lose.
    func testATargetInsideTheArmedOneIsIdle() {
        let (roll, album, _) = scene()
        XCTAssertEqual(DropTargetHighlight.state(of: album, whenArmed: roll), .idle)
    }

    func testNothingArmedLeavesEveryoneIdle() {
        let (roll, album, bench) = scene()
        for view in [roll, album, bench] {
            XCTAssertEqual(DropTargetHighlight.state(of: view, whenArmed: nil), .idle)
        }
    }

    /// Depth, not immediacy: Shared Album's album panel sits inside the roll's
    /// target with the panel's own chrome in between, so the winner is a
    /// grandchild rather than a child.
    func testContainmentIsFoundThroughInterveningViews() {
        let roll = UIView()
        let chrome = UIView()
        let album = UIView()
        roll.addSubview(chrome)
        chrome.addSubview(album)

        XCTAssertEqual(DropTargetHighlight.state(of: roll, whenArmed: album), .drained)
    }
}
