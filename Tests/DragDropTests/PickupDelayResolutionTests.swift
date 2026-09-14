import XCTest
import UIKit
@testable import DragDrop

/// Whether a drag waits before it lifts depends on where the view is when it
/// is touched. A SwiftUI representable enables dragging in `makeUIView`, before
/// its view has a superview, so deciding at enable time decides wrong.
@MainActor
final class PickupDelayResolutionTests: XCTestCase {

    private func gesture(on view: UIView) throws -> DragDropGesture {
        try XCTUnwrap(view.gestureRecognizers?.compactMap { $0 as? DragDropGesture }.first)
    }

    func testAViewEnabledWhileDetachedGetsTheDelayOnceItIsInAScrollView() throws {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        let dragged = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        container.addSubview(dragged)

        let controller = DragDropController()
        controller.enableDragAction(for: dragged)
        let recognizer = try gesture(on: dragged)
        XCTAssertEqual(recognizer.gestureBeginDelay, 0, "nothing scrolls above it yet")

        let scrollView = UIScrollView(frame: container.frame)
        scrollView.addSubview(container)

        XCTAssertEqual(recognizer.beginDelayProvider?(dragged), DragDropController.dragPickupBeginDelay)
    }

    func testAViewOutsideAnyScrollViewStillLiftsImmediately() throws {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        let dragged = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        container.addSubview(dragged)

        let controller = DragDropController()
        controller.enableDragAction(for: dragged)

        XCTAssertEqual(try gesture(on: dragged).beginDelayProvider?(dragged), 0)
    }
}
