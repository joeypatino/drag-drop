import XCTest
import UIKit
@testable import DragDrop

@MainActor
final class DragDropControllerTests: XCTestCase {
    private final class StubDataSource: DragDropControllerDataSource {
        func dragDropController(_ controller: DragDropController,
                                frameFor view: UIView,
                                in destination: DragDropController) -> CGRect { .zero }
    }

    func testEnableDragActionAttachesExactlyOneGesture() {
        let controller = DragDropController()
        let view = UIView()

        controller.enableDragAction(for: view)

        let gestures = view.gestureRecognizers?.filter { $0 is DragDropGesture } ?? []
        XCTAssertEqual(gestures.count, 1)
    }

    func testDisableDragActionRemovesEveryDragGesture() {
        let controller = DragDropController()
        let view = UIView()

        controller.enableDragAction(for: view)
        controller.enableDragAction(for: view)
        controller.disableDragAction(for: view)

        let gestures = view.gestureRecognizers?.filter { $0 is DragDropGesture } ?? []
        XCTAssertTrue(gestures.isEmpty)
    }

    /// A view inside a scrolling container gets a pickup delay so the scroll
    /// view does not start scrolling before the drag begins.
    func testGestureGetsPickupDelayInsideAScrollView() {
        let controller = DragDropController()
        let scrollView = UIScrollView()
        let view = UIView()
        scrollView.addSubview(view)

        controller.enableDragAction(for: view)

        let gesture = view.gestureRecognizers?.compactMap { $0 as? DragDropGesture }.first
        XCTAssertEqual(gesture?.gestureBeginDelay, DragDropController.dragPickupBeginDelay)
    }

    func testGestureHasNoPickupDelayOutsideAScrollView() {
        let controller = DragDropController()
        let container = UIView()
        let view = UIView()
        container.addSubview(view)

        controller.enableDragAction(for: view)

        let gesture = view.gestureRecognizers?.compactMap { $0 as? DragDropGesture }.first
        XCTAssertEqual(gesture?.gestureBeginDelay, 0)
    }

    /// Regression test for the innermost-drop-target selection, which the
    /// Objective-C never actually performed.
    func testInnermostDropTargetWinsWhenTargetsAreNested() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 400))
        let outerView = UIView(frame: CGRect(x: 0, y: 0, width: 400, height: 400))
        let innerView = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        let innermostView = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))

        window.addSubview(outerView)
        outerView.addSubview(innerView)
        innerView.addSubview(innermostView)
        window.isHidden = false

        let outer = DragDropController()
        outer.dropTargetView = outerView
        let inner = DragDropController()
        inner.dropTargetView = innerView
        let innermost = DragDropController()
        innermost.dropTargetView = innermostView

        let source = DragDropController()
        let found = source.controllerForDrop(at: CGPoint(x: 50, y: 50),
                                             in: window,
                                             among: [outer, inner, innermost])

        XCTAssertIdentical(found, innermost)
    }

    func testControllerForDropReturnsNilWhenPointIsOutsideEveryTarget() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 400))
        let targetView = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        window.addSubview(targetView)
        window.isHidden = false

        let target = DragDropController()
        target.dropTargetView = targetView

        let source = DragDropController()
        let found = source.controllerForDrop(at: CGPoint(x: 300, y: 300),
                                             in: window,
                                             among: [target])

        XCTAssertNil(found)
    }

    func testControllerForDropIgnoresControllersWithNoDropTarget() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 400))
        window.isHidden = false

        let withoutTarget = DragDropController()
        let source = DragDropController()

        XCTAssertNil(source.controllerForDrop(at: CGPoint(x: 10, y: 10),
                                              in: window,
                                              among: [withoutTarget]))
    }
}
