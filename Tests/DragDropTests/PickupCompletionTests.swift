import XCTest
import UIKit
@testable import DragDrop

/// The pickup animation runs for a moment after the drag begins, and its
/// completion is where drop targets first hear about the drag. A finger
/// released inside that window ends the drag first, so the completion has to
/// find the drag already over and say nothing.
@MainActor
final class PickupCompletionTests: XCTestCase {

    private final class HoverSpy: DragDropControllerDelegate {
        var log: [String] = []

        func dragDropController(_ controller: DragDropController,
                                dragDidHover drag: DragAction,
                                from source: DragDropController) {
            log.append("hover")
        }

        func dragDropController(_ controller: DragDropController,
                                didReceive view: UIView,
                                from source: DragDropController) {
            log.append("receive")
        }
    }

    private var window: UIWindow!
    private var dragged: UIView!
    private var spy: HoverSpy!

    override func setUp() {
        super.setUp()
        window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 400))
        window.isHidden = false
        spy = HoverSpy()
    }

    override func tearDown() {
        dragged = nil
        spy = nil
        window = nil
        super.tearDown()
    }

    /// Gives the pickup animation's completion block time to run.
    private func settle() {
        let settled = expectation(description: "pickup animation completed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { settled.fulfill() }
        wait(for: [settled], timeout: 2)
    }

    /// A flick-drop: picked up and released faster than the pickup animation.
    /// The completion used to notify the drop target regardless, so a table
    /// opened a vacancy after the drop had already finished and nothing was
    /// left to close it.
    func testAReleaseInsideThePickupAnimationNeverEntersADropTarget() {
        let targetView = UIView(frame: CGRect(x: 0, y: 0, width: 400, height: 400))
        window.addSubview(targetView)

        let destination = DragDropController()
        destination.dropTargetView = targetView
        destination.dragDropDelegate = spy

        let source = DragDropController()
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 400, height: 400))
        window.addSubview(container)
        source.dropTargetView = container

        dragged = UIView(frame: CGRect(x: 10, y: 10, width: 50, height: 50))
        container.addSubview(dragged)
        source.enableDragAction(for: dragged)

        let drag = DragAction(view: dragged)
        drag.currentLocation = CGPoint(x: 200, y: 200)

        source.startDrag(drag)
        source.endDrag(drag)

        settle()

        XCTAssertFalse(spy.log.contains("hover"),
                       "the drop target heard about a drag that was already over")
    }
}
