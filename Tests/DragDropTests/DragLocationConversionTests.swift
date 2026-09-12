import XCTest
import UIKit
@testable import DragDrop

/// Every drop target hears the drag location in its own coordinates, and the
/// location it is converted from is always the window's. A conversion that
/// starts from the value a previous target already converted puts the point
/// out by that target's origin -- which is what a finger crossing straight
/// from one target into another does in a single touch event.
@MainActor
final class DragLocationConversionTests: XCTestCase {

    private final class LocationSpy: DragDropControllerDelegate {
        var hovered: [CGPoint] = []

        func dragDropController(_ controller: DragDropController,
                                dragDidHover drag: DragAction,
                                from source: DragDropController) {
            hovered.append(drag.currentLocation)
        }
    }

    private var window: UIWindow!
    private var spies: [LocationSpy] = []

    override func setUp() {
        super.setUp()
        window = UIWindow(frame: CGRect(x: 0, y: 0, width: 600, height: 400))
        window.isHidden = false
    }

    override func tearDown() {
        spies = []
        window = nil
        super.tearDown()
    }

    /// Deliberately given a non-zero origin: a target at the window's origin
    /// cannot tell a single conversion from a double one.
    private func makeTarget(at frame: CGRect) -> (DragDropController, LocationSpy) {
        let view = UIView(frame: frame)
        window.addSubview(view)

        let controller = DragDropController()
        controller.dropTargetView = view

        let spy = LocationSpy()
        controller.dragDropDelegate = spy
        spies.append(spy)

        return (controller, spy)
    }

    func testATargetHearsTheLocationInItsOwnCoordinates() {
        let source = DragDropController()
        let (target, spy) = makeTarget(at: CGRect(x: 20, y: 30, width: 200, height: 200))

        let drag = DragAction(view: UIView())
        drag.currentLocation = CGPoint(x: 100, y: 80)
        source.notifyDropTarget(target, of: drag)

        XCTAssertEqual(spy.hovered, [CGPoint(x: 80, y: 50)])
    }

    /// The regression: the entered target was handed a point that had already
    /// been converted into the *departed* target's space, so it read as
    /// (30, 20) -- out by the first target's origin -- instead of (50, 50).
    /// A table resolves a row from this, so the vacancy opened on the wrong
    /// one; a collection view picked the wrong swap destination.
    func testCrossingStraightFromOneTargetToAnotherConvertsFromTheWindowEachTime() {
        let source = DragDropController()
        let (first, firstSpy) = makeTarget(at: CGRect(x: 20, y: 30, width: 200, height: 200))
        let (second, secondSpy) = makeTarget(at: CGRect(x: 300, y: 100, width: 200, height: 200))

        let drag = DragAction(view: UIView())

        drag.currentLocation = CGPoint(x: 100, y: 80)
        source.notifyDropTarget(first, of: drag)

        // One event, two targets: the departure and the arrival are notified
        // from the same window-space location.
        drag.currentLocation = CGPoint(x: 350, y: 150)
        source.notifyDropTarget(second, of: drag)

        XCTAssertEqual(secondSpy.hovered, [CGPoint(x: 50, y: 50)])
        XCTAssertEqual(firstSpy.hovered, [CGPoint(x: 80, y: 50)],
                       "the departed target should not have been hovered again")
    }

    /// Leaving for nowhere still reports in the target's own space, and the
    /// window-space location is not left mutated behind it.
    func testLeavingATargetDoesNotDisturbTheWindowLocation() {
        let source = DragDropController()
        let (target, _) = makeTarget(at: CGRect(x: 20, y: 30, width: 200, height: 200))

        let drag = DragAction(view: UIView())
        drag.currentLocation = CGPoint(x: 100, y: 80)
        source.notifyDropTarget(target, of: drag)

        drag.currentLocation = CGPoint(x: 400, y: 300)
        source.notifyDropTarget(nil, of: drag)

        XCTAssertEqual(drag.currentLocation, CGPoint(x: 400, y: 300))
    }
}
