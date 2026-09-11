import XCTest
import UIKit
@testable import DragDrop

@MainActor
final class DragActionTests: XCTestCase {
    func testInitCapturesViewAndItsFrame() {
        let view = UIView(frame: CGRect(x: 10, y: 20, width: 30, height: 40))
        let action = DragAction(view: view)

        XCTAssertIdentical(action.view, view)
        XCTAssertEqual(action.frame, CGRect(x: 10, y: 20, width: 30, height: 40))
        XCTAssertEqual(action.currentLocation, .zero)
        XCTAssertEqual(action.firstTouchOffset, .zero)
    }

    func testViewIsHeldWeakly() {
        var view: UIView? = UIView()
        let action = DragAction(view: view!)
        XCTAssertNotNil(action.view)

        view = nil
        XCTAssertNil(action.view)
    }

    func testGestureBeginDelayDefaultsToZero() {
        let gesture = DragDropGesture(target: nil, action: nil)
        XCTAssertEqual(gesture.gestureBeginDelay, 0)
        XCTAssertEqual(gesture.touchBeginOffset, .zero)
    }

    func testInteractionViewConsultsHitTestHandlerFirst() {
        let interactionView = DragInteractionView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let substitute = UIView()
        interactionView.hitTestHandler = { _, _ in substitute }

        XCTAssertIdentical(interactionView.hitTest(CGPoint(x: 5, y: 5), with: nil), substitute)
    }

    func testInteractionViewFallsBackToSuperWhenHandlerReturnsNil() {
        let interactionView = DragInteractionView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        interactionView.hitTestHandler = { _, _ in nil }

        XCTAssertIdentical(interactionView.hitTest(CGPoint(x: 5, y: 5), with: nil), interactionView)
    }
}

// MARK: - Source view

@MainActor
final class DragActionSourceViewTests: XCTestCase {

    func testDragActionCapturesTheSuperviewItStartedIn() {
        let container = UIView()
        let view = UIView()
        container.addSubview(view)

        let drag = DragAction(view: view)

        XCTAssertIdentical(drag.sourceView, container)
    }

    /// `startDrag` reparents the dragged view into the interaction view before
    /// any delegate callback runs, so this has to be the container the drag
    /// began in, not wherever the view happens to be now.
    func testSourceViewIsCapturedNotRecomputed() {
        let container = UIView()
        let elsewhere = UIView()
        let view = UIView()
        container.addSubview(view)

        let drag = DragAction(view: view)
        elsewhere.addSubview(view)

        XCTAssertIdentical(drag.sourceView, container)
    }

    func testSourceViewIsNilForALooseView() {
        XCTAssertNil(DragAction(view: UIView()).sourceView)
    }
}
