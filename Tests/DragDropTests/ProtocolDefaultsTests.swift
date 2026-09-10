import XCTest
import UIKit
@testable import DragDrop

@MainActor
final class ProtocolDefaultsTests: XCTestCase {
    /// Implements only the one member that was @required in Objective-C.
    private final class MinimalDataSource: DragDropControllerDataSource {
        func dragDropController(_ controller: DragDropController,
                                frameFor view: UIView,
                                in destination: DragDropController) -> CGRect {
            CGRect(x: 1, y: 2, width: 3, height: 4)
        }
    }

    private final class MinimalDelegate: DragDropControllerDelegate {}

    func testShouldDragDefaultsToTrue() {
        let dataSource = MinimalDataSource()
        let controller = DragDropController()

        XCTAssertTrue(dataSource.dragDropController(controller, shouldDrag: UIView()))
    }

    func testCanDropDefaultsToTrue() {
        let dataSource = MinimalDataSource()
        let controller = DragDropController()

        XCTAssertTrue(dataSource.dragDropController(controller, canDrop: UIView(), to: nil))
    }

    func testDelegateCallbacksDefaultToNoOps() {
        let delegate = MinimalDelegate()
        let controller = DragDropController()
        let action = DragAction(view: UIView())

        // Each of these would fail to compile if no default existed.
        delegate.dragDropController(controller, willStartDrag: action, animated: true)
        delegate.dragDropController(controller, didStartDrag: action)
        delegate.dragDropController(controller, willEndDrag: action, animated: true)
        delegate.dragDropController(controller, didEndDrag: action)
        delegate.dragDropController(controller, dragDidEnter: action, destinationController: controller)
        delegate.dragDropController(controller, dragDidMove: action, destinationController: controller)
        delegate.dragDropController(controller, dragDidExit: action, destinationController: controller)
        delegate.dragDropController(controller, didMove: UIView(), to: controller)
    }
}
